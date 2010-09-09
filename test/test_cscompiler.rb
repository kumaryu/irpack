
$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'test/unit'
require 'tempfile'
require 'tmpdir'
require 'fileutils'
require 'irpack'

require 'WindowsBase'
include System
include System::IO
include System::IO::Packaging

class TC_CSCompiler < Test::Unit::TestCase
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
    output_file = Tempfile.new(File.basename(__FILE__))
    output_file.close
    result = IRPack::CSCompiler.compile(
      :dll,
      src,
      references,
      resources,
      output_file.path
    )
    assert_equal(output_file.path, result)
    asm = nil
    assert_nothing_raised do
      asm = System::Reflection::Assembly.load_from(output_file.path)
    end
    assert(asm.get_type('hoge.Hoge'))
    assert_nil(asm.entry_point)
    assert_equal(System::Reflection::Assembly.get_entry_assembly.image_runtime_version, asm.image_runtime_version)
  end
end

