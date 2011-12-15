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
require 'irpack/rake/generateexetask'

class TC_GenerateExeTask < Test::Unit::TestCase
  def teardown
    Rake::Task.clear
  end

  def test_construct
    spec = IRPack::Specification.new
    task = IRPack::Rake::GenerateExeTask.new(spec)
    assert_equal(spec, task.exe_spec)
    assert_equal(:exe, task.name)
    assert(!Rake::Task.task_defined?(task.name))
  end

  def test_construct_with_block
    spec = IRPack::Specification.new {|s|
      s.output_file = 'main.exe'
      s.entry_file  = 'main.rb'
    }
    task_in_block = nil
    task = IRPack::Rake::GenerateExeTask.new(spec) {|t|
      task_in_block = t
      assert_equal(spec, t.exe_spec)
      assert_equal(:exe, t.name)
    }
    assert_same(task, task_in_block)
    assert(Rake::Task.task_defined?(task.name))
  end

  def test_define_no_entry_file
    spec = IRPack::Specification.new
    task = IRPack::Rake::GenerateExeTask.new(spec)
    assert_raise(ArgumentError) do
      task.define
    end
  end

  def test_define_no_output_file
    spec = IRPack::Specification.new {|s|
      s.entry_file = 'main.rb'
    }
    task = IRPack::Rake::GenerateExeTask.new(spec)
    assert_raise(ArgumentError) do
      task.define
    end
  end

  def test_define_only_entry_file
    spec = IRPack::Specification.new {|s|
      s.output_file = 'output/main.exe'
      s.entry_file = 'bin/main.rb'
    }
    IRPack::Rake::GenerateExeTask.new(spec) do
    end
    assert(Rake::Task.task_defined?(:exe))
    task = Rake::Task[:exe]
    assert_equal([spec.output_file], task.prerequisites)
    assert(task.actions.empty?)
    assert(Rake::Task.task_defined?(spec.output_file))
    task = Rake::Task[spec.output_file]
    assert_equal([File.expand_path('bin/main.rb')], task.prerequisites.sort)
    assert(!task.actions.empty?)
  end

  def test_define_with_files
    spec = IRPack::Specification.new {|s|
      s.output_file = 'output/main.exe'
      s.entry_file  = 'bin/main.rb'
      s.files << 'bin/main.rb'
      s.files << 'lib/foo.rb'
      s.files << 'lib/bar.rb'
      s.files << '../hoge/../fuga/../piyo.rb'
      s.files << 'c:/foo/bar/baz.rb'
    }
    IRPack::Rake::GenerateExeTask.new(spec) do
    end
    task = Rake::Task[spec.output_file]
    assert_equal([
      'bin/main.rb',
      'lib/foo.rb',
      'lib/bar.rb',
      '../hoge/../fuga/../piyo.rb',
      'c:/foo/bar/baz.rb',
    ].collect {|fn| File.expand_path(fn) }.sort, task.prerequisites.sort)
  end

  def test_define_with_files_hash
    spec = IRPack::Specification.new {|s|
      s.output_file = 'output/main.exe'
      s.entry_file  = 'main.rb'
      s.files = {
        'main.rb'        => 'bin/main.rb',
        'foo.rb'         => 'lib/foo.rb',
        'bar.rb'         => 'lib/bar.rb',
        '../piyo.rb'     => '../hoge/../fuga/../piyo.rb',
        'foo/bar/baz.rb' => 'c:/foo/bar/baz.rb',
      }
    }
    IRPack::Rake::GenerateExeTask.new(spec) do
    end
    task = Rake::Task[spec.output_file]
    assert_equal([
      'bin/main.rb',
      'lib/foo.rb',
      'lib/bar.rb',
      '../hoge/../fuga/../piyo.rb',
      'c:/foo/bar/baz.rb',
    ].collect {|fn| File.expand_path(fn) }.sort, task.prerequisites.sort)
  end

  def test_execute
    FileUtils.mkpath('test/tmp')
    spec = IRPack::Specification.new {|s|
      s.output_file = 'test/tmp/foo.exe'
      s.entry_file  = 'test/fixtures/foo.rb'
    }
    IRPack::Rake::GenerateExeTask.new(spec) do
    end
    task = Rake::Task[spec.output_file]
    task.execute
    assert(File.exist?(spec.output_file))
    assert('Hello World!', `#{spec.output_file}`)
  ensure
    FileUtils.rm_rf('test/tmp')
  end
end

