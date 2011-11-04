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
    runtime_options = {}

    assert_equal(output_file, IRPack::EntryPoint.compile(output_file, module_name, entry_file, references, runtime_options))
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
    runtime_options = {}

    IRPack::EntryPoint.compile(output_file, module_name, entry_file, references, runtime_options)
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
    runtime_options = {}

    IRPack::EntryPoint.compile(output_file, module_name, entry_file, references, runtime_options)
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
    runtime_options = {}

    IRPack::EntryPoint.compile(output_file, module_name, entry_file, references, runtime_options)
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

  def test_search_paths
    output_file = tempfilename('.dll')
    module_name = 'TestModule'
    entry_file = 'main.rb'
    references = ironruby_assemblies
    runtime_options = {
      SearchPaths: [
        'foo',
        '../bar',
      ],
    }

    IRPack::EntryPoint.compile(output_file, module_name, entry_file, references, runtime_options)
    asm = System::Reflection::Assembly.load_from(output_file)
    main = asm.get_type("#{module_name}.EntryPoint").get_method('Main')
    assert_not_nil(main)
    main_rb = <<-RB
    if $:.any? {|path| /foo$/=~path } and
       $:.any? {|path| /bar$/=~path } then
      exit 0
    else
      exit 1
    end
    RB
    create_package('main.rb' => main_rb) do |package|
      res = main.invoke(nil, System::Array[System::Object].new([package, System::Array[System::String].new(0)]))
      assert_equal(0, res)
    end
  end

  def test_required_paths
    output_file = tempfilename('.dll')
    module_name = 'TestModule'
    entry_file = 'main.rb'
    references = ironruby_assemblies
    runtime_options = {
      RequiredPaths: [
        'stringio',
        'date',
      ],
      StandardLibrary: '../Lib',
    }

    IRPack::EntryPoint.compile(output_file, module_name, entry_file, references, runtime_options)
    asm = System::Reflection::Assembly.load_from(output_file)
    main = asm.get_type("#{module_name}.EntryPoint").get_method('Main')
    assert_not_nil(main)
    main_rb = <<-RB
    required_constants = [:StringIO, :DateTime]
    if required_constants.all? {|const| Object.constants.include?(const) } then
      exit 0
    else
      exit 1
    end
    RB
    create_package('main.rb' => main_rb) do |package|
      res = main.invoke(nil, System::Array[System::Object].new([package, System::Array[System::String].new(0)]))
      assert_equal(0, res)
    end
  end

  def test_debug_variable
    output_file = tempfilename('.dll')
    module_name = 'TestModule'
    entry_file = 'main.rb'
    references = ironruby_assemblies
    runtime_options = {
      DebugVariable: true,
    }

    IRPack::EntryPoint.compile(output_file, module_name, entry_file, references, runtime_options)
    asm = System::Reflection::Assembly.load_from(output_file)
    main = asm.get_type("#{module_name}.EntryPoint").get_method('Main')
    assert_not_nil(main)
    main_rb = <<-RB
    exit($DEBUG ? 0 : 1)
    RB
    create_package('main.rb' => main_rb) do |package|
      res = main.invoke(nil, System::Array[System::Object].new([package, System::Array[System::String].new(0)]))
      assert_equal(0, res)
    end
  end

  def test_profile
    output_file = tempfilename('.dll')
    module_name = 'TestModule'
    entry_file = 'main.rb'
    references = ironruby_assemblies
    runtime_options = {
      Profile: true,
    }

    IRPack::EntryPoint.compile(output_file, module_name, entry_file, references, runtime_options)
    asm = System::Reflection::Assembly.load_from(output_file)
    main = asm.get_type("#{module_name}.EntryPoint").get_method('Main')
    assert_not_nil(main)
    main_rb = <<-RB
    begin
      IronRuby::Clr.profile { 1 + 1 }
      exit 0
    rescue SystemCallError
      exit 1
    end
    RB
    create_package('main.rb' => main_rb) do |package|
      res = main.invoke(nil, System::Array[System::Object].new([package, System::Array[System::String].new(0)]))
      assert_equal(0, res)
    end
  end

  def test_enable_tracing
    output_file = tempfilename('.dll')
    module_name = 'TestModule'
    entry_file = 'main.rb'
    references = ironruby_assemblies
    runtime_options = {
      EnableTracing: true,
    }

    IRPack::EntryPoint.compile(output_file, module_name, entry_file, references, runtime_options)
    asm = System::Reflection::Assembly.load_from(output_file)
    main = asm.get_type("#{module_name}.EntryPoint").get_method('Main')
    assert_not_nil(main)
    main_rb = <<-RB
    begin
      set_trace_func(proc { nil })
      exit 0
    rescue System::NotSupportedException
      exit 1
    end
    RB
    create_package('main.rb' => main_rb) do |package|
      res = main.invoke(nil, System::Array[System::Object].new([package, System::Array[System::String].new(0)]))
      assert_equal(0, res)
    end
  end

  def test_pass_exceptions
    output_file = tempfilename('.dll')
    module_name = 'TestModule'
    entry_file = 'main.rb'
    references = ironruby_assemblies
    runtime_options = {
      PassExceptions: true,
    }

    IRPack::EntryPoint.compile(output_file, module_name, entry_file, references, runtime_options)
    asm = System::Reflection::Assembly.load_from(output_file)
    main = asm.get_type("#{module_name}.EntryPoint").get_method('Main')
    assert_not_nil(main)
    main_rb = <<-RB
    raise System::ApplicationException, 'Exception Test'
    RB
    create_package('main.rb' => main_rb) do |package|
      assert_raise(System::ApplicationException) do
        begin
          main.invoke(nil, System::Array[System::Object].new([package, System::Array[System::String].new(0)]))
        rescue System::Reflection::TargetInvocationException => e
          raise e.InnerException
        end
      end
    end
  end
end

