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
  module BootLoader
    Source = <<CS
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

        [STAThread]
        public static int Main(string[] args)
        {
          AppDomain domain = AppDomain.CurrentDomain;
          domain.AssemblyResolve += new ResolveEventHandler(delegate (object sender, ResolveEventArgs e) {
            foreach (var asm in domain.GetAssemblies()) {
              if (e.Name==asm.FullName) {
                return asm;
              }
            }
            return null;
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
    module_function
    def source(module_name, package_file, preload_assemblies)
      ERB.new(Source).result(binding)
    end

    def compile(target, output_file, module_name, references, package_file)
      boot_src = source(
        module_name,
        File.basename(package_file),
        references.collect {|fn| File.basename(fn) }
      )
      sysasm = IRPack::CSCompiler.system_assemblies.collect {|asm|
        IRPack::CSCompiler.assembly_location(asm)
      }
      Dir.chdir(File.dirname(package_file)) do
        IRPack::CSCompiler.compile(target, output_file, boot_src, references+sysasm, [File.basename(package_file)])
      end
      output_file
    end
  end
end

