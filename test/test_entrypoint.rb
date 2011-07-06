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
require 'irpack/entrypoint'
require 'utils'

class TC_IRPack_EntryPoint < Test::Unit::TestCase
  include Utils

  def test_compile
    file = Tempfile.open(File.basename(__FILE__))
    file.close
    output_file = file.path
    module_name = 'TestModule'
    entry_file = 'foo.rb'
    references = ironruby_assemblies

    assert_equal(output_file, IRPack::EntryPoint.compile(output_file, module_name, entry_file, references))
    assert(File.exist?(output_file))
    asm = nil
    assert_nothing_raised do
      asm = System::Reflection::Assembly.load_from(output_file)
    end
    entrypoint = asm.get_type("#{module_name}.EntryPoint")
    assert_not_nil(entrypoint)
    main = entrypoint.get_method('Main')
    assert_not_nil(main)
    create_package('foo.rb' => 'exit ARGV.size') do |package|
      res = main.invoke(nil, System::Array[System::Object].new([package, System::Array[System::String].new(['hoge', 'fuga', 'piyo'])]))
      assert_equal(3, res)
    end
  end
end

