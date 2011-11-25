=begin
Copyright (c) 2010-2011 Ryuichi Sakamoto.

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

require 'irpack/cscompiler'
require 'irpack/bootloader'
require 'irpack/entrypoint'
require 'irpack/packager'
require 'irpack/missing'
require 'irpack/specification'
require 'tmpdir'

module IRPack
  IronRubyAssemblies = %w[
    Microsoft.Dynamic
    Microsoft.Scripting
    Microsoft.Scripting.Core
    Microsoft.Scripting.Metadata
    IronRuby
    IronRuby.Libraries
    IronRuby.Libraries.Yaml
  ]

  module_function
  def path_to_module_name(filename)
    name = File.basename(filename, '.*')
    name.gsub!(/[^A-Za-z0-9_]/, '_')
    (/^[A-Za-z]/=~name ? name : ('M'+name)).upcase
  end

  def ironruby_assemblies
    IronRubyAssemblies.each do |name|
      begin
        load_assembly name
      rescue LoadError
      end
    end
    System::AppDomain.current_domain.get_assemblies.select {|asm|
      IronRubyAssemblies.include?(asm.get_name.name)
    }.collect {|asm| asm.location }
  end

  def ironruby_standard_library_version
    ruby_context = binding.clr_member(:LocalScope).call.ruby_context
    ruby_context.standard_library_version
  end

  def ironruby_library_path
    ruby_context = binding.clr_member(:LocalScope).call.ruby_context
    binpath = ENV[ruby_context.class.bin_dir_environment_variable] ||
              File.dirname(System::Reflection::Assembly.get_entry_assembly.location)
    File.expand_path(File.join(binpath, '..', 'Lib'))
  end

  def ironruby_libraries(dstpath='stdlib', srcpath=ironruby_library_path)
    res = {}
    Dir.glob(File.join(srcpath, "{ironruby,ruby/#{ironruby_standard_library_version}}", '**', '*')) do |fn|
      res[fn.sub(/^#{srcpath}/, dstpath)] = fn if File.file?(fn)
    end
    res
  end

  def pack(spec)
    output_file = File.expand_path(spec.output_file)
    entry_file  = spec.map_entry
    basename    = File.basename(spec.output_file, '.*')
    references  = ironruby_assemblies
    pack_files  = spec.map_files
    pack_files  = ironruby_libraries.merge(pack_files) if spec.embed_stdlibs
    if spec.embed_assemblies then
      references.each do |asm|
        pack_files[File.basename(asm)] = asm
      end
    end

    module_name = spec.module_name || path_to_module_name(output_file)
    Dir.mktmpdir(File.basename($0,'.*')) do |tmp_path|
      entry_dll = File.join(tmp_path, module_name+'.EntryPoint.dll')
      EntryPoint.compile(entry_dll, module_name, entry_file, references, spec.runtime_options.to_hash)
      pack_files[File.basename(entry_dll)] = entry_dll

      package_file = File.join(tmp_path, basename+'.pkg')
      Packager.pack(pack_files, package_file, spec.compress)

      BootLoader.compile(spec.target, output_file, module_name, references, package_file)
    end
    output_file
  end
end

