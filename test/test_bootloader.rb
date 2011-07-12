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

require 'test/unit'
require 'irpack/bootloader'
require 'utils'
require 'erb'

class TC_IRPack_BootLoader < Test::Unit::TestCase
  include Utils
  ENTRYPOINT_SRC = <<-CS
    using System;
    using System.IO;
    using System.IO.Packaging;

    namespace <%= module_name %> {
      public class EntryPoint
      {
        public static int Main(Package package, string[] args)
        {
          Console.WriteLine("Hello World!");
          return 0;
        }
      }
    }
  CS

  def compile_entrypoint(output_file, module_name)
    sysasm = IRPack::CSCompiler.system_assemblies.collect {|asm|
      IRPack::CSCompiler.assembly_location(asm)
    }
    IRPack::CSCompiler.compile(:dll, output_file, ERB.new(ENTRYPOINT_SRC).result(binding), sysasm, [])
    output_file
  end

  def test_compile
    module_name = 'TestModule'
    entrypoint = tempfilename
    references = ironruby_assemblies
    package_file = tempfilename

    compile_entrypoint(entrypoint, module_name)
    package = create_package(package_file, 'TestModule.EntryPoint.dll' => File.open(entrypoint, 'rb') {|f| f.read })

    exe = tempfilename('.exe')
    assert_equal(exe, IRPack::BootLoader.compile(:exe, exe, module_name, references, package_file))
    res = `#{exe}`.chomp
    assert_equal('Hello World!', res)
    package.close
  end
end

