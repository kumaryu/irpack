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
require 'irpack/cscompiler'
require 'utils'

class TC_CSCompiler < Test::Unit::TestCase
  include Utils
  def test_system_assemblies
    assert_equal(IRPack::CSCompiler.system_assemblies(4), [
      'System, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089',
      'WindowsBase, Version=4.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35',
      'System.Core, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089',
    ])
    [2,3.0,3.5].each do |v|
      assert_equal(IRPack::CSCompiler.system_assemblies(v), [
        'System, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089',
        'WindowsBase, Version=3.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35',
        'System.Core, Version=3.5.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089',
      ])
      assert_raise(ArgumentError) do
        IRPack::CSCompiler.system_assemblies(5)
      end
    end
  end

  def test_assembly_location
    path = IRPack::CSCompiler.assembly_location(
        'System, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089')
    assert_equal(File.basename(path), 'System.dll')
  end

  def test_compile_dll
    src = <<-CS
    using System;
    namespace hoge {
      class Hoge {
        public static int Main(string[] args) {
          System.Console.WriteLine("hoge");
          return 0;
        }
      }
    }
    CS
    references = []
    resources = []
    output_file = tempfilename('.dll')
    result = IRPack::CSCompiler.compile(
      :dll,
      output_file,
      src,
      references,
      resources)
    assert_equal(output_file, result)
    asm = nil
    assert_nothing_raised do
      asm = System::Reflection::Assembly.load_from(output_file)
    end
    assert(asm.get_type('hoge.Hoge'))
    assert_nil(asm.entry_point)
    assert_equal(System::Reflection::Assembly.get_entry_assembly.image_runtime_version, asm.image_runtime_version)
  end
end

