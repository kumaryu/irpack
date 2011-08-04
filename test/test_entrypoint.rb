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
    output_file = tempfilename('.dll')
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

  def test_run
    output_file = tempfilename('.dll')
    module_name = 'TestModule'
    entry_file = 'main.rb'
    references = ironruby_assemblies

    IRPack::EntryPoint.compile(output_file, module_name, entry_file, references)
    asm = System::Reflection::Assembly.load_from(output_file)
    main = asm.get_type("#{module_name}.EntryPoint").get_method('Main')
    assert_not_nil(main)
    main_rb = <<-RB
    puts 'Hello World!'
    RB
    create_package('main.rb' => main_rb) do |package|
      res = main.invoke(nil, System::Array[System::Object].new([package, System::Array[System::String].new(0)]))
      assert_equal(0, res)
    end
  end

  def test_run_raised
    output_file = tempfilename('.dll')
    module_name = 'TestModule'
    entry_file = 'main.rb'
    references = ironruby_assemblies

    IRPack::EntryPoint.compile(output_file, module_name, entry_file, references)
    asm = System::Reflection::Assembly.load_from(output_file)
    main = asm.get_type("#{module_name}.EntryPoint").get_method('Main')
    assert_not_nil(main)
    main_rb = <<-RB
    raise RuntimeError, 'Hello Exception!'
    RB
    create_package('main.rb' => main_rb) do |package|
      res = nil
      err = System::IO::StringWriter.new
      assert_nothing_raised do
        prev_err = System::Console.error
        System::Console.set_error(err)
        res = main.invoke(nil, System::Array[System::Object].new([package, System::Array[System::String].new(0)]))
        System::Console.set_error(prev_err)
      end
      assert_match(/Hello Exception!/, err.get_string_builder.to_string)
      assert_equal(-1, res)
    end
  end

  def test_load_assembly
    output_file = tempfilename('.dll')
    module_name = 'TestModule'
    entry_file = 'main.rb'
    references = ironruby_assemblies

    IRPack::EntryPoint.compile(output_file, module_name, entry_file, references)
    asm = System::Reflection::Assembly.load_from(output_file)
    main = asm.get_type("#{module_name}.EntryPoint").get_method('Main')
    assert_not_nil(main)
    main_rb = <<-RB
    load_assembly 'IronRuby.Libraries', 'IronRuby.StandardLibrary.StringIO'
    RB
    create_package('main.rb' => main_rb) do |package|
      assert_nothing_raised do
        main.invoke(nil, System::Array[System::Object].new([package, System::Array[System::String].new(0)]))
      end
    end
  end
end

