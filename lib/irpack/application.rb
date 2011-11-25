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

require 'irpack'
require 'irpack/specification'
require 'optparse'
require 'pathname'

module IRPack
  module Application
    def self.parse!(argv)
      spec = ::IRPack::Specification.new
      opt = OptionParser.new("Usage: #{$0} [options] ENTRYFILE [EMBEDFILES...]", 24, '  ')
      opt.on('-b BASEDIR',    'Specify base directory.') {|v| spec.base_paths << v }
      opt.on('-o OUTPUTFILE', 'Specify output file name.') {|v| spec.output_file = v }
      opt.on('--window',      'Generate window app.') { spec.target = :winexe }
      opt.on('--console',     'Generate console app.[default]') { spec.target = :exe }
      opt.on('--compress',    'Compress package.') { spec.compress = true }
      opt.on('--complete',    'Embed all standard libraries.') { spec.complete = true }
      opt.on('--no-embed',    'Do not embed IronRuby assemblies.') {|v| spec.embed_assemblies = v }
      opt.on('--[no-]embed-assemblies', 'Embed IronRuby assemblies.')   {|v| spec.embed_assemblies = v }
      opt.on('--[no-]embed-stdlibs',    'Embed all standard libraris.') {|v| spec.embed_stdlibs = v }
      opt.separator('Runtime options:')
      opt.on('-Idirectory', 'specify $LOAD_PATH directory (may be used more than once)') {|v|
        spec.runtime_options.search_paths << v
      }
      opt.on('-rlibrary', 'require the library, before executing your script') {|v|
        spec.runtime_options.required_paths << v
      }
      opt.on('-d', 'set debugging flags (set $DEBUG to true)') {|v|
        spec.runtime_options.debug_variable = v
      }
      opt.on('-D', 'emit debugging information (PDBs) for Visual Studio debugger') {|v|
        spec.runtime_options.debug_mode = v
      }
      opt.on('-v', 'print version number, then turn on verbose mode') {|v|
        spec.runtime_options.warning_level = 2
      }
      opt.on('-w', 'turn warnings on for your script') {|v|
        spec.runtime_options.warning_level = 2
      }
      opt.on('-W[level]', 'set warning level; 0=silence, 1=medium (default), 2=verbose', Integer) {|v|
        spec.runtime_options.warning_level = (v || 2).to_i
      }
      opt.on('--trace', 'enable support for set_trace_func') {|v|
        spec.runtime_options.trace = v
      }
      opt.on('--profile', "enable support for 'pi = IronRuby::Clr.profile { block_to_profile }'") {|v|
        spec.runtime_options.profile = v
      }
      opt.on('--exception-detail', 'enable ExceptionDetail mode') {|v|
        spec.runtime_options.exception_detail = v
      }
      opt.on('--no-adaptive-compilation', 'disable adaptive compilation - all code will be compiled') {|v|
        spec.runtime_options.no_adaptive_compilation = true
      }
      opt.on('--compilation-threshold THRESHOLD', 'the number of iterations before the interpreter starts compiling', Integer) {|v|
        spec.runtime_options.compilation_threshold = v.to_i
      }
      opt.on('--pass-exceptions', 'do not catch exceptions that are unhandled by script code') {|v|
        spec.runtime_options.pass_exceptions = v
      }
      opt.on('--private-binding', 'enable binding to private members') {|v|
        spec.runtime_options.private_binding = v
      }
      opt.on('--show-clr-exceptions', 'display CLS Exception information') {|v|
        spec.runtime_options.show_clr_exceptions = v
      }
      opt.parse!(argv)

      if argv.size<1 then
        $stderr.puts opt.help
        nil
      else
        spec.entry_file = argv.shift
        argv.each do |file|
          spec.files << file
        end
        spec
      end
    end

    def self.run(spec)
      return 1 unless spec
      IRPack.pack(spec)
      return 0
    end
  end
end

