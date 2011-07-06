=begin
Copyright (c) 2011 Ryuichi Sakamoto.

This software is provided 'as-is', without any express or implied
warranty. In no event will the authors be held liable for any damages
arising from the use of this software.

Permission is granted to anyone to use this software for any purpose,
including commercial applications, and to alter it and redistribute it
freely, subject to the following restrictions:

    1. The origin of this software must not be misrepresented; you must not
    claim that you wrote the original software. If you use this software
    in a product, an acknowledgment in the product documentation would be
    appreciated but is not required.

    2. Altered source versions must be plainly marked as such, and must not be
    misrepresented as being the original software.

    3. This notice may not be removed or altered from any source
    distribution.
=end

require 'erb'
require 'irpack/cscompiler'

module IRPack
  module EntryPoint
    Source = <<CS
    using System;
    using System.IO;
    using System.IO.Packaging;
    using System.Reflection;
    using Microsoft.Scripting;
    using Microsoft.Scripting.Hosting;

    namespace <%= module_name %> {
      public class EntryPoint
      {
        public class PackagePAL : PlatformAdaptationLayer
        {
          public Package CurrentPackage { get; set; }
          public PackagePAL(Package pkg)
          {
            CurrentPackage = pkg;
          }

          private Uri ToPackageLoadPath(string path)
          {
            var domain = AppDomain.CurrentDomain;
            var fullpath = Path.GetFullPath(path);
            var searchpath = Path.GetFullPath(
              domain.RelativeSearchPath!=null ?
              Path.Combine(domain.BaseDirectory, domain.RelativeSearchPath) :
              domain.BaseDirectory);
            if (fullpath.StartsWith(searchpath)) {
              var relpath = fullpath.Substring(searchpath.Length, fullpath.Length-searchpath.Length);
              return PackUriHelper.CreatePartUri(new Uri(relpath, UriKind.Relative));
            }
            else {
              return PackUriHelper.CreatePartUri(new Uri(path, UriKind.Relative));
            }
          }

          private Uri ToPackagePath(string path)
          {
            var fullpath = Path.GetFullPath(path);
            var searchpath = Path.GetDirectoryName(Path.GetFullPath(Assembly.GetEntryAssembly().Location));
            if (fullpath.StartsWith(searchpath)) {
              var relpath = fullpath.Substring(searchpath.Length, fullpath.Length-searchpath.Length);
              return PackUriHelper.CreatePartUri(new Uri(relpath, UriKind.Relative));
            }
            else {
              return PackUriHelper.CreatePartUri(new Uri(path, UriKind.Relative));
            }
          }

          public override Assembly LoadAssembly(string name)
          {
            foreach (var asm in AppDomain.CurrentDomain.GetAssemblies()) {
              if (asm.FullName==name) {
                return asm;
              }
            }
            return Assembly.Load(name);
          }

          public override Assembly LoadAssemblyFromPath(string path)
          {
            try {
              return Assembly.LoadFile(path);
            }
            catch (FileNotFoundException e) {
              var uri = ToPackageLoadPath(path);
              if (CurrentPackage.PartExists(uri)) {
                var stream = CurrentPackage.GetPart(uri).GetStream(FileMode.Open, FileAccess.Read);
                var raw = new byte[stream.Length];
                stream.Read(raw, 0, (int)stream.Length);
                stream.Close();
                return Assembly.Load(raw);
              }
              else {
                throw e;
              }
            }
          }

          public override bool FileExists(string path)
          {
            if (File.Exists(path)) {
              return true;
            }
            else {
              var uri = ToPackagePath(path);
              return CurrentPackage.PartExists(uri);
            }
          }

          public override Stream OpenInputFileStream(string path, FileMode mode, FileAccess access, FileShare share) 
          {
            if (mode==FileMode.Open && access==FileAccess.Read) {
              var uri = ToPackagePath(path);
              if (CurrentPackage.PartExists(uri)) {
                return CurrentPackage.GetPart(uri).GetStream(mode, access);
              }
              else {
                return new FileStream(path, mode, access, share);
              }
            }
            else {
              return new FileStream(path, mode, access, share);
            }
          }

          public override Stream OpenInputFileStream(string path, FileMode mode, FileAccess access, FileShare share, int bufferSize)
          {
            if (mode==FileMode.Open && access==FileAccess.Read) {
              var uri = ToPackagePath(path);
              if (CurrentPackage.PartExists(uri)) {
                return CurrentPackage.GetPart(uri).GetStream(mode, access);
              }
              else {
                return new FileStream(path, mode, access, share, bufferSize);
              }
            }
            else {
              return new FileStream(path, mode, access, share, bufferSize);
            }
          }

          public override Stream OpenInputFileStream(string path)
          {
            var uri = ToPackagePath(path);
            if (CurrentPackage.PartExists(uri)) {
              return CurrentPackage.GetPart(uri).GetStream(FileMode.Open, FileAccess.Read);
            }
            else {
              return new FileStream(path, FileMode.Open, FileAccess.Read);
            }
          }
        }

        public class IRHost : ScriptHost
        {
          private PlatformAdaptationLayer PAL_;
          public override PlatformAdaptationLayer PlatformAdaptationLayer { get { return PAL_; } }
          public IRHost(Package pkg)
          {
            PAL_ = new PackagePAL(pkg);
          }
        }

        public static int Main(Package package, string[] args)
        {
          var runtime_setup = new ScriptRuntimeSetup();
          runtime_setup.LanguageSetups.Add(IronRuby.Ruby.CreateRubySetup());
          runtime_setup.Options["MainFile"]  = "<%= entry_file %>";
          runtime_setup.Options["Arguments"] = args;
          runtime_setup.HostType = typeof(IRHost);
          runtime_setup.HostArguments = new object[] { package };
          var engine = IronRuby.Ruby.GetEngine(IronRuby.Ruby.CreateRuntime(runtime_setup));
          try {
            engine.ExecuteFile("<%= entry_file %>");
            return 0;
          }
          catch (IronRuby.Builtins.SystemExit e) {
            return e.Status;
          }
        }
      }
    }
CS
    module_function
    def source(module_name, entry_file)
      ERB.new(Source).result(binding)
    end

    def compile(output_file, module_name, entry_file, references)
      src = source(module_name, entry_file)
      sysasm = IRPack::CSCompiler.system_assemblies.collect {|asm|
        IRPack::CSCompiler.assembly_location(asm)
      }
      IRPack::CSCompiler.compile(:dll, output_file, src, references+sysasm, [])
      output_file
    end
  end
end

