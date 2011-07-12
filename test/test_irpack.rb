# coding: utf-8
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
require 'irpack'
require 'utils'

class TC_IRPack < Test::Unit::TestCase
  include Utils
  def test_path_to_module_name
    assert_equal('IR',         IRPack.path_to_module_name('c:/Program Files/IronRuby1.1/bin/ir.exe'))
    assert_equal('IR',         IRPack.path_to_module_name('c:\\Program Files\\IronRuby1.1\\bin\\ir.exe'))
    assert_equal('M1234',      IRPack.path_to_module_name('1234'))
    assert_equal('M__FOO_BAR', IRPack.path_to_module_name('__foo_bar'))
    assert_equal('FOOBAR',     IRPack.path_to_module_name('FooBar'))
    assert_equal('FOO_BAR',    IRPack.path_to_module_name('Foo$Bar'))
    assert_equal('M_____',     IRPack.path_to_module_name('モジュール'))
  end

  def test_ironruby_assemblies
    locations = IRPack.ironruby_assemblies
    locations.each do |loc|
      assert(File.exist?(loc))
      assert(IRPack::IronRubyAssemblies.include?(File.basename(loc, '.dll')))
    end
  end

  def test_pack
    entry = Tempfile.open(File.basename(__FILE__)) do |f|
      f.write <<-RB
      $: << File.dirname(__FILE__)
      require 'hello'
      hello
      RB
      f.path
    end
    hello = Tempfile.open(File.basename(__FILE__)) do |f|
      f.write <<-RB
      def hello
        puts 'Hello World!'
      end
      RB
      f.path
    end
    files = {
      entry => 'entry.rb',
      hello => 'hello.rb',
    }
    outfile = tempfilename('.exe')
    assert_equal(outfile, IRPack.pack(outfile, files, 'entry.rb'))
    assert_equal('Hello World!', `#{outfile}`.chomp)
  end
end

