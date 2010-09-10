=begin
Copyright (c) 2010 Ryuichi Sakamoto.

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
require 'fileutils'
require 'tmpdir'
require 'pathname'
require 'WindowsBase'

unless Dir.respond_to?(:mktmpdir) then
  def Dir.mktmpdir(prefix_suffix=['d',''], tmpdir=Dir.tmpdir, &block)
    if prefix_suffix.kind_of?(String) then
      prefix = prefix_suffix
      suffix = ''
    else
      prefix = prefix_suffix[0]
      suffix = prefix_suffix[1]
    end
    n = 0
    begin
      path = File.join(tmpdir, "#{prefix}-#{Time.now.to_i}-#{$$}-#{rand(0x100000000).to_s(36)}-#{suffix}-#{n}")
      Dir.mkdir(path, 0700)
    rescue Errno::EEXIST
      n += 1
      retry
    end

    if block then
      begin
        block.call(path)
      ensure
        FileUtils.remove_entry_secure(path)
      end
    else
      path
    end
  end
end

module IRPack
  include System
  include System::Reflection

  module CSCompiler
    include Microsoft::CSharp
    include System::CodeDom::Compiler
    include System::Reflection

    module_function
    def compiler_version
      case System::Environment.version.major
      when 4
        'v4.0'
      when 2
        'v3.5'
      end
    end

    def system_assemblies
      case compiler_version
      when 'v4.0'
        [
          'System, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089',
          'WindowsBase, Version=4.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35',
          'System.Core, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089',
        ]
      when 'v3.5'
        [
          'System, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089',
          'WindowsBase, Version=3.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35',
          'System.Core, Version=3.5.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089',
        ]
      end
    end

    def system_assembly_files
      system_assemblies.collect {|name|
        Assembly.reflection_only_load(name.to_clr_string).location
      }
    end

    def find_assembly(paths, file)
      path = paths.find {|path| File.exist?(File.join(path, file)) }
      if path then
        File.join(path, file)
      else
        file
      end
    end

    class CompileError < RuntimeError; end
    def compile(target, srcs, references, resources, output_name)
      opts = System::Collections::Generic::Dictionary[System::String,System::String].new
      opts['CompilerVersion'] = compiler_version
      @compiler = CSharpCodeProvider.new(opts)
      srcs = srcs.kind_of?(Array) ? srcs : [srcs]
      refs = system_assembly_files + references
      refs = System::Array[System::String].new(refs.size) {|i| refs[i] }
      icon = resources.find {|rc| File.extname(rc)=='.ico' }

      params = CompilerParameters.new(refs, output_name, false)
      params.generate_in_memory = false
      compiler_options = ['/optimize+']
      case target
      when :exe, 'exe'
        params.generate_executable = true
        compiler_options << '/target:exe'
        compiler_options << "/win32icon:#{icon}" if icon
      when :winexe, 'winexe'
        params.generate_executable = true
        compiler_options << '/target:winexe'
        compiler_options << "/win32icon:#{icon}" if icon
      else
        params.generate_executable = false
        compiler_options << '/target:library'
      end
      params.compiler_options = compiler_options.join(' ')
      resources.each do |rc|
        params.embedded_resources.add(rc)
      end
      srcs = System::Array[System::String].new(srcs.size) {|i| srcs[i] }
      result = @compiler.compile_assembly_from_source(params, srcs)
      result.errors.each do |err|
        if err.is_warning then
          $stderr.puts(err.to_s)
        else
          raise CompileError, err.to_s
        end
      end
      result.path_to_assembly
    end
  end
end

module IRPack
  BootLoaderSource = <<CS
  using System;
  using System.IO;
  using System.IO.Packaging;
  using System.Reflection;

  namespace <%= module_name %> {
    public class BootLoader
    {
      private static Assembly LoadAssemblyFromPackage(AppDomain domain, Package package, string file)
      {
        var uri = PackUriHelper.CreatePartUri(new Uri(file, UriKind.Relative));
        if (package.PartExists(uri)) {
          var stream = package.GetPart(uri).GetStream(FileMode.Open, FileAccess.Read);
          var raw = new byte[stream.Length];
          stream.Read(raw, 0, (int)stream.Length);
          stream.Close();
          return domain.Load(raw);
        }
        else {
          return null;
        }
      }

      private static Assembly LoadAssembly(AppDomain domain, Package package, string file)
      {
        try {
          return domain.Load(file);
        }
        catch (FileNotFoundException)
        {
          return LoadAssemblyFromPackage(domain, package, file);
        }
      }

      public static int Main(string[] args)
      {
        AppDomain domain = AppDomain.CurrentDomain;
        domain.AssemblyResolve += new ResolveEventHandler(delegate (object sender, ResolveEventArgs e) {
          foreach (var asm in domain.GetAssemblies()) {
            if (e.Name==asm.FullName) {
              return asm;
            }
          }
          throw new FileNotFoundException(e.Name);
        });
        var stream = Assembly.GetEntryAssembly().GetManifestResourceStream(@"<%= package_file %>");
        var package = Package.Open(stream, FileMode.Open, FileAccess.Read);
  <% preload_assemblies.each do |asm| %>
        LoadAssembly(domain, package, @"<%= asm %>");
  <% end %>
        var entry_point = LoadAssemblyFromPackage(domain, package, @"<%= module_name %>.EntryPoint.dll");
        var main = entry_point.GetType(@"<%= module_name %>.EntryPoint").GetMethod("Main");
        int result = (int)(main.Invoke(null, new object[] { package, args }));
        package.Close();
        return result;
      }
    }
  }
CS

  EntryPointSource = <<CS
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
  def bootloader_source(module_name, package_file, preload_assemblies)
    ERB.new(BootLoaderSource).result(binding)
  end

  def entrypoint_source(module_name, entry_file)
    ERB.new(EntryPointSource).result(binding)
  end
end

module IRPack
  module Packager
    include System
    include System::IO::Packaging

    RelType = 'http://schemas.openxmlformats.org/package/2006/relationships/meta data/core-properties'
    module_function
    def pack(files, package_file, compress=false)
      compress_option = compress ? CompressionOption.normal : CompressionOption.not_compressed
      package = Package.open(package_file, System::IO::FileMode.create)
      files.each do |src, dest|
        uri = PackUriHelper.create_part_uri(Uri.new(dest, UriKind.relative))
        part = package.create_part(uri, 'application/octet-stream', compress_option)
        stream = part.get_stream
        File.open(src, 'rb') do |f|
          data = f.read
          stream.write(data, 0, data.size)
        end
        stream.close
        package.create_relationship(uri, TargetMode.internal, RelType)
      end
      package.close
    end

    def pack_dir(dir_name, package_file)
      files = {}
      base = Pathname.new(dir_name)
      Dir.glob(base.join('**', '*')) do |fn|
        files[fn] = Pathname.new(fn).relative_path_from(base)
      end
      pack(files, package_file)
    end
  end

  AssemblyPath = ::File.dirname(Assembly.get_entry_assembly.location.to_s)
  PreloadAssemblies = %w[
    Microsoft.Dynamic.dll
    Microsoft.Scripting.dll
    Microsoft.Scripting.Core.dll
    IronRuby.dll
    IronRuby.Libraries.dll
    IronRuby.Libraries.Yaml.dll
  ]

  module_function
  def path_to_module_name(filename)
    name = File.basename(filename, '.*')
    name.gsub!(/[^A-Za-z0-9_]/, '_')
    /^[A-Za-z]/=~name ? name : ('M'+name)
  end

  def pack(files, entry_file, output_file, options={})
    preload_assemblies = PreloadAssemblies.collect {|fn|
      File.join(AssemblyPath, fn)
    }.select {|fn|
      File.exist?(fn)
    }
    basename    = File.basename(output_file, '.*')
    module_name = path_to_module_name(output_file)
    resources   = options[:resources] || []
    target      = options[:target] || :exe
    stdlib      = options.include?(:stdlib)   ? options[:stdlib]   : true
    compress    = options.include?(:compress) ? options[:compress] : false
    pack_files  = files.dup

    Dir.mktmpdir(File.basename($0,'.*')) do |tmp_path|
      entry_src = entrypoint_source(module_name, entry_file)
      entry_dll = File.join(tmp_path, module_name+'.EntryPoint.dll')
      CSCompiler.compile(:dll, entry_src, preload_assemblies, [], entry_dll)
      pack_files[entry_dll] = File.basename(entry_dll)
      if stdlib then
        preload_assemblies.each do |asm|
          pack_files[asm] = File.basename(asm)
        end
      end
      package_file = File.join(tmp_path, basename+'.pkg')
      Packager.pack(pack_files, package_file, compress)

      target_src = bootloader_source(
        module_name,
        File.basename(package_file),
        preload_assemblies.collect {|fn| File.basename(fn) }
      )
      Dir.chdir(tmp_path) do
        CSCompiler.compile(target, target_src, [], [File.basename(package_file)], output_file)
      end
    end
  end

  def pack_dir(pack_dir, entry_file, output_file, options={})
    output_file  = File.expand_path(output_file)
    entry_packed = nil
    pack_files   = {}
    resources    = []
    base         = Pathname.new(pack_dir).expand_path
    Dir.glob(base.join('**', '*')) do |fn|
      path = Pathname.new(File.expand_path(fn))
      next if path==output_file
      relpath = path.relative_path_from(base)
      pack_files[path] = relpath
      if not entry_packed and
         (path.to_s==File.expand_path(entry_file) or
          path.basename.to_s==entry_file or
          relpath.to_s==entry_file) then
        entry_packed = relpath
      end
      resources << path.to_s if path.extname=='.ico'
    end
    raise ArgumentError, "Entry file `#{entry_file}' is not in packed directory."unless entry_packed
    options = options.merge(:resources => resources)
    pack(pack_files, entry_packed, output_file, options)
  end
end

