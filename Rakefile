
require 'rake/testtask'
require 'rake/gempackagetask'
require 'rubygems'

PKG_VERSION = '0.1.0'

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

