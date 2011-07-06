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

module IRPack
  include System
  include System::Reflection

  module CSCompiler
    include Microsoft::CSharp
    include System::CodeDom::Compiler
    include System::Reflection

    class CompileError < RuntimeError
    end

    module_function
    def compiler_version(target_version=System::Environment.version.major)
      case target_version
      when 4
        'v4.0'
      when 2...4
        'v3.5'
      else
        raise ArgumentError, "Unsupported version #{target_version}"
      end
    end

    def system_assemblies(target_version=System::Environment.version.major)
      case compiler_version(target_version)
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

    def assembly_location(sig)
      Assembly.reflection_only_load(sig.to_clr_string).location
    end

    def compile(target, output_name, srcs, references, resources)
      opts = System::Collections::Generic::Dictionary[System::String,System::String].new
      opts['CompilerVersion'] = compiler_version
      @compiler = CSharpCodeProvider.new(opts)
      srcs = srcs.kind_of?(Array) ? srcs : [srcs]
      icon = resources.find {|rc| File.extname(rc)=='.ico' }

      params = CompilerParameters.new(
        System::Array[System::String].new(references),
        output_name,
        false)
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
      when :dll, 'dll', :library, 'library'
        params.generate_executable = false
        compiler_options << '/target:library'
      else
        raise ArgumentError, "target must be :exe, :winexe or :library"
      end
      params.compiler_options = compiler_options.join(' ')
      resources.each do |rc|
        params.embedded_resources.add(rc)
      end
      result = @compiler.compile_assembly_from_source(
        params,
        System::Array[System::String].new(srcs))
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

