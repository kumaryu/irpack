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
      :embed_references,
      :entry_file,
      :files) do
      def self.parse!(argv)
        args = self.new
        basedir     = nil
        args.output_file = nil
        args.target      = :exe
        args.compress    = false
        args.embed_references = true
        args.entry_file  = nil
        args.files = {}
        opt = OptionParser.new
        opt.on('-b BASEDIR',    'Specify base directory. [base of ENTRYFILE]') {|v| basedir = v }
        opt.on('-o OUTPUTFILE', 'Specify output file name.') {|v| args.output_file = v }
        opt.on('--window',      'Generate window app.') { args.target = :winexe }
        opt.on('--console',     'Generate console app.[default]') { args.target = :exe }
        opt.on('--compress',    'Compress package.') { args.compress = true }
        opt.on('--no-embed',    'Do not embed IronRuby assemblies.') {|v| args.embed_references = v }
        opt.banner = "Usage: #{$0} [options] ENTRYFILE [EMBEDFILES...]"
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
        :target => args.target,
        :compress => args.compress,
        :embed_references => args.embed_references)
      return 0
    end
  end
end

