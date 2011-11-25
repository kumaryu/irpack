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
require 'irpack/application'
require 'utils'
require 'stringio'

class TC_Application < Test::Unit::TestCase
  include Utils
  def test_parse_without_spec
    argv = []
    $stderr = StringIO.new
    assert_nil(IRPack::Application.parse!(argv))
    assert_not_equal('', $stderr.to_s)
    $stderr = STDERR
  end

  def test_parse
    argv = ['entry.rb']
    spec = IRPack::Application.parse!(argv)
    assert(!spec.compress)
    assert(!spec.complete)
    assert(spec.embed_assemblies)
    assert_equal(:exe, spec.target)
    assert_nil(spec.output_file)
    assert_equal('entry.rb', spec.entry_file)
    assert_equal('entry.rb', spec.map_entry)
    assert_equal(0, spec.files.size)
    pack_files = spec.map_files
    assert_equal(1, pack_files.size)
    assert_equal(File.expand_path('entry.rb'), pack_files['entry.rb'])
    assert(!spec.runtime_options.debug_variable)
    assert(!spec.runtime_options.debug_mode)
    assert_equal(1, spec.runtime_options.warning_level)
    assert(!spec.runtime_options.trace)
    assert(!spec.runtime_options.profile)
    assert(!spec.runtime_options.exception_detail)
    assert(!spec.runtime_options.no_adaptive_compilation)
    assert_equal(-1, spec.runtime_options.compilation_threshold)
    assert(!spec.runtime_options.pass_exceptions)
    assert(!spec.runtime_options.private_binding)
    assert(!spec.runtime_options.show_clr_exceptions)
  end

  def test_parse_output_file
    argv = ['-o', 'foo.exe', 'entry.rb']
    spec = IRPack::Application.parse!(argv)
    assert_equal(File.expand_path('foo.exe'), File.expand_path(spec.output_file))
  end

  def test_parse_window_app
    argv = ['--window', 'entry.rb']
    spec = IRPack::Application.parse!(argv)
    assert_equal(:winexe, spec.target)
  end

  def test_parse_console_app
    argv = ['--console', 'entry.rb']
    spec = IRPack::Application.parse!(argv)
    assert_equal(:exe, spec.target)
  end

  def test_parse_no_embed
    argv = ['--no-embed', 'entry.rb']
    spec = IRPack::Application.parse!(argv)
    assert(!spec.embed_assemblies)
  end

  def test_parse_no_embed_assemblies
    argv = ['--no-embed-assemblies', 'entry.rb']
    spec = IRPack::Application.parse!(argv)
    assert(!spec.embed_assemblies)
  end

  def test_parse_compress
    argv = ['--compress', 'entry.rb']
    spec = IRPack::Application.parse!(argv)
    assert(spec.compress)
  end

  def test_parse_complete
    argv = ['--complete', 'entry.rb']
    spec = IRPack::Application.parse!(argv)
    assert(spec.complete)
  end

  def test_parse_embed_stdlibs
    argv = ['--embed-stdlibs', 'entry.rb']
    spec = IRPack::Application.parse!(argv)
    assert(spec.embed_stdlibs)
  end

  def test_parse_basedir
    argv = [
      '-b', 'foo/bar',
      'entry.rb',
      'foo/bar/baz.rb',
      File.expand_path('foo/bar/hoge.rb'),
      'foo/bar/hoge/fuga.rb',
    ]
    spec = IRPack::Application.parse!(argv)
    assert_nil(spec.output_file)
    assert_equal('entry.rb', spec.entry_file)
    assert_equal('entry.rb', spec.map_entry)
    pack_files = spec.map_files
    assert_equal(4, pack_files.size)
    assert_equal(File.expand_path('entry.rb'),             pack_files['entry.rb'])
    assert_equal(File.expand_path('foo/bar/baz.rb'),       pack_files['baz.rb'])
    assert_equal(File.expand_path('foo/bar/hoge.rb'),      pack_files['hoge.rb'])
    assert_equal(File.expand_path('foo/bar/hoge/fuga.rb'), pack_files['hoge/fuga.rb'])
  end

  def test_parse_debug_variable
    argv = ['-d', 'entry.rb']
    spec = IRPack::Application.parse!(argv)
    assert(spec.runtime_options.debug_variable)
  end

  def test_parse_debug_mode
    argv = ['-D', 'entry.rb']
    spec = IRPack::Application.parse!(argv)
    assert(spec.runtime_options.debug_mode)
  end

  def test_parse_verbose
    argv = ['-v', 'entry.rb']
    spec = IRPack::Application.parse!(argv)
    assert_equal(2, spec.runtime_options.warning_level)
  end

  def test_parse_warn
    argv = ['-w', 'entry.rb']
    spec = IRPack::Application.parse!(argv)
    assert_equal(2, spec.runtime_options.warning_level)
  end

  def test_parse_warning
    argv = ['-W', 'entry.rb']
    spec = IRPack::Application.parse!(argv)
    assert_equal(2, spec.runtime_options.warning_level)
  end

  def test_parse_warning0
    argv = ['-W0', 'entry.rb']
    spec = IRPack::Application.parse!(argv)
    assert_equal(0, spec.runtime_options.warning_level)
  end

  def test_parse_trace
    argv = ['--trace', 'entry.rb']
    spec = IRPack::Application.parse!(argv)
    assert(spec.runtime_options.trace)
  end

  def test_parse_profile
    argv = ['--profile', 'entry.rb']
    spec = IRPack::Application.parse!(argv)
    assert(spec.runtime_options.profile)
  end

  def test_parse_exception_detail
    argv = ['--exception-detail', 'entry.rb']
    spec = IRPack::Application.parse!(argv)
    assert(spec.runtime_options.exception_detail)
  end

  def test_parse_no_adaptive_compilation
    argv = ['--no-adaptive-compilation', 'entry.rb']
    spec = IRPack::Application.parse!(argv)
    assert(spec.runtime_options.no_adaptive_compilation)
  end

  def test_parse_compilation_threshold
    argv = ['--compilation-threshold', '8192', 'entry.rb']
    spec = IRPack::Application.parse!(argv)
    assert_equal(8192, spec.runtime_options.compilation_threshold)
  end

  def test_parse_pass_exceptions
    argv = ['--pass-exceptions', 'entry.rb']
    spec = IRPack::Application.parse!(argv)
    assert(spec.runtime_options.pass_exceptions)
  end

  def test_parse_private_binding
    argv = ['--private-binding', 'entry.rb']
    spec = IRPack::Application.parse!(argv)
    assert(spec.runtime_options.private_binding)
  end

  def test_parse_show_clr_exceptions
    argv = ['--show-clr-exceptions', 'entry.rb']
    spec = IRPack::Application.parse!(argv)
    assert(spec.runtime_options.show_clr_exceptions)
  end
end

