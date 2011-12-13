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
require 'irpack/specification'

class TC_Specification < Test::Unit::TestCase
  def test_construct
    spec = IRPack::Specification.new
    assert_nil(spec.output_file)
    assert_nil(spec.entry_file)
    assert_nil(spec.module_name)
    assert(spec.files.empty?)
    assert(spec.base_paths.empty?)
    assert(!spec.compress)
    assert_equal(:exe, spec.target)
    assert(spec.embed_assemblies)
    assert(!spec.embed_stdlibs)
    assert_kind_of(IRPack::Specification::RuntimeOptions, spec.runtime_options)
  end

  def test_construct_with_block
    arg = nil
    spec = IRPack::Specification.new do |block_arg|
      arg = block_arg
    end
    assert_same(arg, spec)
  end

  def test_map_entry_no_entry_file
    spec = IRPack::Specification.new
    assert_raise(ArgumentError) do
      spec.map_entry
    end
  end

  def test_map_entry_no_base_paths
    spec = IRPack::Specification.new
    spec.entry_file = 'bin/main.rb'
    assert_equal('bin/main.rb', spec.map_entry)
  end

  def test_map_entry_base_paths
    spec = IRPack::Specification.new
    spec.entry_file = 'foo/bar/main.rb'
    spec.base_paths << 'foo'
    assert_equal('bar/main.rb', spec.map_entry)
  end

  def test_map_files_no_entry_file
    spec = IRPack::Specification.new
    assert_raise(ArgumentError) do
      spec.map_files
    end
  end

  def test_map_files_only_entry_file
    spec = IRPack::Specification.new
    spec.entry_file = 'foo.rb'
    pack_files = spec.map_files
    assert_equal(1, pack_files.size)
    assert_equal(File.expand_path('foo.rb'), pack_files['foo.rb'])
  end

  def test_map_files_with_file_array
    files = [
      'foo.rb',
      'foo/bar.rb',
      'foo/bar/baz.rb',
      'hoge/fuga/piyo.rb',
    ]
    spec = IRPack::Specification.new
    spec.entry_file = files.first
    spec.files = files
    pack_files = spec.map_files
    assert_equal(files.size, pack_files.size)
    files.each do |file|
      assert_equal(File.expand_path(file), pack_files[file])
    end
  end

  def test_map_files_with_base_paths
    files = [
      'bin/foo.rb',
      'lib/foo/bar.rb',
      'lib/foo/bar/baz.rb',
      'hoge/fuga/piyo.rb',
    ]
    spec = IRPack::Specification.new
    spec.entry_file = files.first
    spec.files = files
    spec.base_paths << 'lib'
    spec.base_paths << 'hoge'
    pack_files = spec.map_files
    assert_equal(files.size, pack_files.size)
    assert_equal(File.expand_path('bin/foo.rb'),         pack_files['bin/foo.rb'])
    assert_equal(File.expand_path('lib/foo/bar.rb'),     pack_files['foo/bar.rb'])
    assert_equal(File.expand_path('lib/foo/bar/baz.rb'), pack_files['foo/bar/baz.rb'])
    assert_equal(File.expand_path('hoge/fuga/piyo.rb'),  pack_files['fuga/piyo.rb'])
  end

  def test_map_files_with_base_paths
    files = [
      'bin/foo.rb',
      'lib/foo/bar.rb',
      'lib/foo/bar/baz.rb',
      'hoge/fuga/piyo.rb',
      'hoge/main.rb',
    ]
    spec = IRPack::Specification.new
    spec.entry_file = 'main.rb'
    spec.files = files
    spec.base_paths << 'lib'
    spec.base_paths << 'hoge'
    spec.base_paths << 'hoge/fuga'
    pack_files = spec.map_files
    assert_equal(files.size, pack_files.size)
    assert_equal(File.expand_path('bin/foo.rb'),         pack_files['bin/foo.rb'])
    assert_equal(File.expand_path('lib/foo/bar.rb'),     pack_files['foo/bar.rb'])
    assert_equal(File.expand_path('lib/foo/bar/baz.rb'), pack_files['foo/bar/baz.rb'])
    assert_equal(File.expand_path('hoge/fuga/piyo.rb'),  pack_files['piyo.rb'])
    assert_equal(File.expand_path('hoge/main.rb'),       pack_files['main.rb'])
  end

  def test_map_files_with_base_paths_no_entry
    files = []
    spec = IRPack::Specification.new
    spec.entry_file = 'hoge/main.rb'
    spec.files = files
    spec.base_paths << 'lib'
    spec.base_paths << 'hoge'
    pack_files = spec.map_files
    assert_equal(files.size+1, pack_files.size)
    assert_equal(File.expand_path('hoge/main.rb'), pack_files['main.rb'])
  end

  def test_map_files_hash
    files = {
      'main.rb'        => 'bin/main.rb',
      'bin/foo.rb'     => 'bin/foo.rb',
      'foo/bar.rb'     => 'lib/foo/bar.rb',
      'foo/bar/baz.rb' => 'lib/foo/bar/baz.rb',
      'fuga/piyo.rb'   => 'hoge/fuga/piyo.rb',
    }
    spec = IRPack::Specification.new
    spec.entry_file = 'main.rb'
    spec.files = files
    pack_files = spec.map_files
    assert_equal(files.size, pack_files.size)
    assert_equal(File.expand_path('bin/main.rb'),        pack_files['main.rb'])
    assert_equal(File.expand_path('bin/foo.rb'),         pack_files['bin/foo.rb'])
    assert_equal(File.expand_path('lib/foo/bar.rb'),     pack_files['foo/bar.rb'])
    assert_equal(File.expand_path('lib/foo/bar/baz.rb'), pack_files['foo/bar/baz.rb'])
    assert_equal(File.expand_path('hoge/fuga/piyo.rb'),  pack_files['fuga/piyo.rb'])
  end

  def test_map_files_hash_no_entry
    files = {}
    spec = IRPack::Specification.new
    spec.entry_file = 'bin/main.rb'
    spec.files = files
    pack_files = spec.map_files
    assert_equal(files.size+1, pack_files.size)
    assert_equal(File.expand_path('bin/main.rb'), pack_files['bin/main.rb'])
  end
end

class TC_Specification_RuntimeOptions < Test::Unit::TestCase
  def test_construct
    opts = IRPack::Specification::RuntimeOptions.new
    assert(!opts.debug_mode)
    assert(!opts.no_adaptive_compilation)
    assert_equal(-1, opts.compilation_threshold)
    assert(!opts.exception_detail)
    assert(!opts.show_clr_exceptions)
    assert_equal(1, opts.warning_level)
    assert(!opts.debug_variable)
    assert(!opts.profile)
    assert(!opts.trace)
    assert(opts.required_paths.empty?)
    assert(opts.search_paths.empty?)
    assert(!opts.pass_exceptions)
    assert(!opts.private_binding)
  end

  def test_to_hash
    opts = IRPack::Specification::RuntimeOptions.new
    opts.debug_mode = true
    opts.no_adaptive_compilation = true
    opts.compilation_threshold = 42
    opts.exception_detail = true
    opts.show_clr_exceptions = true
    opts.warning_level = 2
    opts.debug_variable = true
    opts.profile = true
    opts.trace = true
    opts.required_paths << 'stringio'
    opts.search_paths << 'lib'
    opts.pass_exceptions = true
    opts.private_binding = true
    hash = opts.to_hash
    assert_equal(opts.debug_mode,              hash[:DebugMode])
    assert_equal(opts.private_binding,         hash[:PrivateBinding])
    assert_equal(opts.no_adaptive_compilation, hash[:NoAdaptiveCompilation])
    assert_equal(opts.compilation_threshold,   hash[:CompilationThreshold])
    assert_equal(opts.exception_detail,        hash[:ExceptionDetail])
    assert_equal(opts.show_clr_exceptions,     hash[:ShowClrExceptions])
    assert_equal(opts.pass_exceptions,         hash[:PassExceptions])
    assert_equal(opts.profile,                 hash[:Profile])
    assert_equal(opts.warning_level,           hash[:Verbosity])
    assert_equal(opts.debug_variable,          hash[:DebugVariable])
    assert_equal(opts.trace,                   hash[:EnableTracing])
    assert_equal(opts.required_paths,          hash[:RequiredPaths])
    assert_equal(opts.search_paths,            hash[:SearchPaths])
  end
end

