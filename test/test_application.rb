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

class TC_ApplicationArguments < Test::Unit::TestCase
  include Utils
  def test_parse_without_args
    argv = []
    $stderr = StringIO.new
    assert_nil(IRPack::Application::Arguments.parse!(argv))
    assert_not_equal('', $stderr.to_s)
  end

  def test_parse
    argv = ['entry.rb']
    args = IRPack::Application::Arguments.parse!(argv)
    assert(!args.compress)
    assert(!args.complete)
    assert(args.embed_references)
    assert_equal(:exe, args.target)
    assert_equal(File.expand_path('entry.exe'), File.expand_path(args.output_file))
    assert_equal('entry.rb', args.entry_file)
    assert_equal(1, args.files.size)
    assert_equal('entry.rb', args.files[File.expand_path('entry.rb')])
    assert(!args.runtime_options[:DebugVariable])
    assert(!args.runtime_options[:DebugMode])
    assert_equal(1, args.runtime_options[:Verbosity])
    assert(!args.runtime_options[:EnableTracing])
    assert(!args.runtime_options[:Profile])
    assert(!args.runtime_options[:ExceptionDetail])
    assert(!args.runtime_options[:NoAdaptiveCompilation])
    assert_equal(-1, args.runtime_options[:CompilationThreshold])
    assert(!args.runtime_options[:PassExceptions])
    assert(!args.runtime_options[:PrivateBinding])
    assert(!args.runtime_options[:ShowClrExceptions])
  end

  def test_parse_output_file
    argv = ['-o', 'foo.exe', 'entry.rb']
    args = IRPack::Application::Arguments.parse!(argv)
    assert_equal(File.expand_path('foo.exe'), File.expand_path(args.output_file))
  end

  def test_parse_window_app
    argv = ['--window', 'entry.rb']
    args = IRPack::Application::Arguments.parse!(argv)
    assert_equal(:winexe, args.target)
  end

  def test_parse_console_app
    argv = ['--console', 'entry.rb']
    args = IRPack::Application::Arguments.parse!(argv)
    assert_equal(:exe, args.target)
  end

  def test_parse_no_embed_references
    argv = ['--no-embed', 'entry.rb']
    args = IRPack::Application::Arguments.parse!(argv)
    assert(!args.embed_references)
  end

  def test_parse_compress
    argv = ['--compress', 'entry.rb']
    args = IRPack::Application::Arguments.parse!(argv)
    assert(args.compress)
  end

  def test_parse_complete
    argv = ['--complete', 'entry.rb']
    args = IRPack::Application::Arguments.parse!(argv)
    assert(args.complete)
  end

  def test_parse_basedir
    argv = [
      '-b', 'foo/bar',
      'entry.rb',
      'foo/bar/baz.rb',
      File.expand_path('foo/bar/hoge.rb'),
      'foo/bar/hoge/fuga.rb',
    ]
    args = IRPack::Application::Arguments.parse!(argv)
    assert_equal(File.expand_path('entry.exe'), File.expand_path(args.output_file))
    assert_equal('../../entry.rb', args.entry_file)
    assert_equal(4, args.files.size)
    assert_equal('../../entry.rb', args.files[File.expand_path('entry.rb')])
    assert_equal('baz.rb', args.files[File.expand_path('foo/bar/baz.rb')])
    assert_equal('hoge.rb', args.files[File.expand_path('foo/bar/hoge.rb')])
    assert_equal('hoge/fuga.rb', args.files[File.expand_path('foo/bar/hoge/fuga.rb')])
  end

  def test_parse_debug_variable
    argv = ['-d', 'entry.rb']
    args = IRPack::Application::Arguments.parse!(argv)
    assert(args.runtime_options[:DebugVariable])
  end

  def test_parse_debug_mode
    argv = ['-D', 'entry.rb']
    args = IRPack::Application::Arguments.parse!(argv)
    assert(args.runtime_options[:DebugMode])
  end

  def test_parse_verbose
    argv = ['-v', 'entry.rb']
    args = IRPack::Application::Arguments.parse!(argv)
    assert_equal(2, args.runtime_options[:Verbosity])
  end

  def test_parse_warn
    argv = ['-w', 'entry.rb']
    args = IRPack::Application::Arguments.parse!(argv)
    assert_equal(2, args.runtime_options[:Verbosity])
  end

  def test_parse_warning
    argv = ['-W', 'entry.rb']
    args = IRPack::Application::Arguments.parse!(argv)
    assert_equal(2, args.runtime_options[:Verbosity])
  end

  def test_parse_warning0
    argv = ['-W0', 'entry.rb']
    args = IRPack::Application::Arguments.parse!(argv)
    assert_equal(0, args.runtime_options[:Verbosity])
  end

  def test_parse_trace
    argv = ['--trace', 'entry.rb']
    args = IRPack::Application::Arguments.parse!(argv)
    assert(args.runtime_options[:EnableTracing])
  end

  def test_parse_profile
    argv = ['--profile', 'entry.rb']
    args = IRPack::Application::Arguments.parse!(argv)
    assert(args.runtime_options[:Profile])
  end

  def test_parse_exception_detail
    argv = ['--exception-detail', 'entry.rb']
    args = IRPack::Application::Arguments.parse!(argv)
    assert(args.runtime_options[:ExceptionDetail])
  end

  def test_parse_no_adaptive_compilation
    argv = ['--no-adaptive-compilation', 'entry.rb']
    args = IRPack::Application::Arguments.parse!(argv)
    assert(args.runtime_options[:NoAdaptiveCompilation])
  end

  def test_parse_compilation_threshold
    argv = ['--compilation-threshold', '8192', 'entry.rb']
    args = IRPack::Application::Arguments.parse!(argv)
    assert_equal(8192, args.runtime_options[:CompilationThreshold])
  end

  def test_parse_pass_exceptions
    argv = ['--pass-exceptions', 'entry.rb']
    args = IRPack::Application::Arguments.parse!(argv)
    assert(args.runtime_options[:PassExceptions])
  end

  def test_parse_private_binding
    argv = ['--private-binding', 'entry.rb']
    args = IRPack::Application::Arguments.parse!(argv)
    assert(args.runtime_options[:PrivateBinding])
  end

  def test_parse_show_clr_exceptions
    argv = ['--show-clr-exceptions', 'entry.rb']
    args = IRPack::Application::Arguments.parse!(argv)
    assert(args.runtime_options[:ShowClrExceptions])
  end
end

