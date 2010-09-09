
$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'test/unit'
require 'tempfile'
require 'tmpdir'
require 'fileutils'
require 'irpack'

require 'WindowsBase'
include System
include System::IO
include System::IO::Packaging

class TC_Packager < Test::Unit::TestCase
  SrcFiles = {
    File.join(File.dirname(__FILE__), 'test_packager.rb') => 'foo.rb',
    File.join(File.dirname(__FILE__), 'test_cscompiler.rb') => 'bar.rb',
  }

  def test_pack
    target = Tempfile.new(File.basename(__FILE__))
    target.close
    IRPack::Packager.pack(SrcFiles, target.path)
    package = Package.open(target.path, FileMode.open)
    SrcFiles.each do |src, dest|
      uri = Uri.new(File.join('/', dest), UriKind.relative)
      assert(package.part_exists(uri))
      stream = package.get_part(uri).get_stream
      bytes = System::Array[System::Byte].new(stream.length)
      stream.read(bytes, 0, stream.length)
      assert_equal(File.open(src, 'rb'){|f|f.read}, bytes.to_a.pack('C*'))
    end
  end

  def test_pack_dir
    Dir.mktmpdir do |src_path|
      SrcFiles.each do |src, dest|
        FileUtils.mkdir_p(File.join(src_path, File.dirname(dest)))
        FileUtils.copy(src, File.join(src_path, dest))
      end
      target = Tempfile.new(File.basename(__FILE__))
      target.close
      IRPack::Packager.pack_dir(src_path, target.path)
      package = Package.open(target.path, FileMode.open)
      SrcFiles.each do |src, dest|
        uri = Uri.new(File.join('/', dest), UriKind.relative)
        assert(package.part_exists(uri))
        stream = package.get_part(uri).get_stream
        bytes = System::Array[System::Byte].new(stream.length)
        stream.read(bytes, 0, stream.length)
        assert_equal(File.open(src, 'rb'){|f|f.read}, bytes.to_a.pack('C*'))
      end
    end
  end
end

