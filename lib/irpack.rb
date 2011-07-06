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
require 'tmpdir'

module IRPack
  IronRubyAssemblies = %w[
    Microsoft.Dynamic
    Microsoft.Scripting
    Microsoft.Scripting.Core
    IronRuby
    IronRuby.Libraries
    IronRuby.Libraries.Yaml
  ]
  module_function
  def path_to_module_name(filename)
    name = File.basename(filename, '.*')
    name.gsub!(/[^A-Za-z0-9_]/, '_')
    /^[A-Za-z]/=~name ? name : ('M'+name)
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

  def pack(output_file, files, entry_file, opts={})
    opts = {
      :target           => :exe,
      :compress         => false,
      :embed_references => true,
      :module_name      => path_to_module_name(output_file)
    }.update(opts)
    basename    = File.basename(output_file, '.*')
    module_name = opts[:module_name]
    target      = opts[:target]
    references  = opts[:references] || ironruby_assemblies
    compress    = opts[:compress]
    pack_files  = {}.merge(files)
    if opts[:embed_references] then
      references.each do |asm|
        pack_files[asm] = File.basename(asm)
      end
    end

    Dir.mktmpdir(File.basename($0,'.*')) do |tmp_path|
      entry_dll = File.join(tmp_path, module_name+'.EntryPoint.dll')
      EntryPoint.compile(entry_dll, module_name, entry_file, references)
      pack_files[entry_dll] = File.basename(entry_dll)

      package_file = File.join(tmp_path, basename+'.pkg')
      Packager.pack(pack_files, package_file, compress)

      BootLoader.compile(target, output_file, references, package_file)
    end
  end
end

