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
require 'optparse'
require 'pathname'

module IRPack
  module Application
    Arguments = Struct.new(
      :output_file,
      :target,
      :compress,
      :complete,
      :embed_references,
      :runtime_options,
      :entry_file,
      :files) do
      def self.parse!(argv)
        args = self.new
        basedir     = nil
        args.output_file = nil
        args.target      = :exe
        args.compress    = false
        args.complete    = false
        args.embed_references = true
        args.entry_file  = nil
        args.files = {}
        args.runtime_options = {
          DebugMode:             false,
          PrivateBinding:        false,
          NoAdaptiveCompilation: false,
          CompilationThreshold:  -1,
          ExceptionDetail:       false,
          ShowClrExceptions:     false,
          Profile:               false,
          Verbosity:             1,
          DebugVariable:         false,
          EnableTracing:         false,
          RequiredPaths:         [],
          SearchPaths:           [],
        }
        opt = OptionParser.new("Usage: #{$0} [options] ENTRYFILE [EMBEDFILES...]", 24, '  ')
        opt.on('-b BASEDIR',    'Specify base directory. [base of ENTRYFILE]') {|v| basedir = v }
        opt.on('-o OUTPUTFILE', 'Specify output file name.') {|v| args.output_file = v }
        opt.on('--window',      'Generate window app.') { args.target = :winexe }
        opt.on('--console',     'Generate console app.[default]') { args.target = :exe }
        opt.on('--compress',    'Compress package.') { args.compress = true }
        opt.on('--complete',    'Embed all standard libraries.') { args.complete = true }
        opt.on('--no-embed',    'Do not embed IronRuby assemblies.') {|v| args.embed_references = v }
        opt.separator('Runtime options:')
        opt.on('-Idirectory', 'specify $LOAD_PATH directory (may be used more than once)') {|v|
          args.runtime_options[:SearchPaths] << v
        }
        opt.on('-rlibrary', 'require the library, before executing your script') {|v|
          args.runtime_options[:RequiredPaths] << v
        }
        opt.on('-d', 'set debugging flags (set $DEBUG to true)') {|v|
          args.runtime_options[:DebugVariable] = v
        }
        opt.on('-D', 'emit debugging information (PDBs) for Visual Studio debugger') {|v|
          args.runtime_options[:DebugMode] = v
        }
        opt.on('-v', 'print version number, then turn on verbose mode') {|v|
          args.runtime_options[:Verbosity] = 2
        }
        opt.on('-w', 'turn warnings on for your script') {|v|
          args.runtime_options[:Verbosity] = 2
        }
        opt.on('-W[level]', 'set warning level; 0=silence, 1=medium (default), 2=verbose', Integer) {|v|
          args.runtime_options[:Verbosity] = (v || 2).to_i
        }
        opt.on('--trace', 'enable support for set_trace_func') {|v|
          args.runtime_options[:EnableTracing] = v
        }
        opt.on('--profile', "enable support for 'pi = IronRuby::Clr.profile { block_to_profile }'") {|v|
          args.runtime_options[:Profile] = v
        }
        opt.on('--exception-detail', 'enable ExceptionDetail mode') {|v|
          args.runtime_options[:ExceptionDetail] = v
        }
        opt.on('--no-adaptive-compilation', 'disable adaptive compilation - all code will be compiled') {|v|
          args.runtime_options[:NoAdaptiveCompilation] = true
        }
        opt.on('--compilation-threshold THRESHOLD', 'the number of iterations before the interpreter starts compiling', Integer) {|v|
          args.runtime_options[:CompilationThreshold] = v.to_i
        }
        opt.on('--pass-exceptions', 'do not catch exceptions that are unhandled by script code') {|v|
          args.runtime_options[:PassExceptions] = v
        }
        opt.on('--private-binding', 'enable binding to private members') {|v|
          args.runtime_options[:PrivateBinding] = v
        }
        opt.on('--show-clr-exceptions', 'display CLS Exception information') {|v|
          args.runtime_options[:ShowClrExceptions] = v
        }
        opt.parse!(argv)

        if argv.size<1 then
          $stderr.puts opt.help
          nil
        else
          basedir = Pathname.new(File.expand_path(basedir || File.dirname(argv[0])).gsub(/\\/, '/'))
          args.output_file ||= File.join(File.dirname(argv[0]), File.basename(argv[0], '.*')+'.exe')
          args.entry_file = argv[0]
          argv.each_with_index do |file, i|
            fullpath = Pathname.new(file.gsub(/\\/, '/')).expand_path
            relpath  = fullpath.relative_path_from(basedir)
            args.files[fullpath.to_s] = relpath.to_s 
            args.entry_file = relpath.to_s if i==0
          end
          args
        end
      end
    end

    def self.run(args)
      return 1 unless args
      IRPack.pack(
        args.output_file,
        args.files,
        args.entry_file,
        {
          target:   args.target,
          compress: args.compress,
          complete: args.complete,
          embed_references: args.embed_references,
        },
        args.runtime_options)
      return 0
    end
  end
end

