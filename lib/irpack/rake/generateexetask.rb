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

require 'rake'
require 'rake/tasklib'
require 'pathname'
require 'irpack'

module IRPack
  module Rake
  end
end

# Define task to generate executable described by IRPack::Specification.
#
# Example:
#
#   require 'irpack/rake/generateexetask'
#
#   exe_spec = IRPack::Specification.new do |s|
#     s.output_file      = 'example.exe'
#     s.entry_file       = 'bin/main.rb'
#     s.files            = Rake::Filelist['lib/**/*.rb']
#     s.target           = :exe
#     s.embed_stdlibs    = true
#     s.embed_assemblies = true
#     s.compress         = true
#   end
#
#   IRPack::Rake::GenerateExeTask.new(exe_spec) do |t|
#   end
#
class IRPack::Rake::GenerateExeTask < ::Rake::TaskLib
  # Task name. default is +exe+.
  attr_accessor :name
  # Spec to generate executable.
  attr_accessor :exe_spec

  # Create tasks that generates exe file.
  # Automatically define the gem if a block is given.
  # If no block is supplied, then +define+
  # needs to be called to define the task.
  def initialize(exe_spec, name=:exe)
    @defined  = false
    @name     = name
    @exe_spec = exe_spec
    if block_given? then
      yield self
      define
    end
  end
  
  # Create rake tasks.
  def define
    raise ArgumentError, "No output_file is specified" unless @exe_spec.output_file
    raise ArgumentError, "No entry_file is specified" unless @exe_spec.entry_file
    output_file = @exe_spec.output_file
    sources = @exe_spec.map_files.values.to_a
    desc "Generate #{File.basename(output_file)}"
    task @name => [output_file]
    file output_file => sources do
      IRPack.pack(@exe_spec)
    end
  end
end

