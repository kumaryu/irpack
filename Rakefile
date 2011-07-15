=begin
Copyright (c) 2010-2011 Ryuichi Sakamoto.

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

require 'rake/testtask'
require 'rake/gempackagetask'
require 'rubygems'

PKG_VERSION = '0.2.1'

spec = Gem::Specification.new do |s|
  s.platform = Gem::Platform::RUBY
  s.summary = 'Generate a standalone executable file from IronRuby scripts.'
  s.name = 'irpack'
  s.author = 'kumaryu'
  s.email = 'kumaryu@kumayu.net'
  s.homepage = 'http://github.com/kumaryu/irpack'
  s.version = PKG_VERSION
  s.requirements << 'none'
  s.description = <<EOF
IRPack converts your IronRuby scripts to a standalone .exe file.
Generated executable does not require IronRuby, but only .NET Framework or mono.
EOF
  s.executable = 'irpack'
  s.require_path = 'lib'
  s.bindir = 'bin'
  s.files = FileList['bin/*', 'lib/**/*.rb', 'test/**/*.rb']
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.need_zip = true
  pkg.need_tar = true
end

Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList['test/test*.rb']
end

