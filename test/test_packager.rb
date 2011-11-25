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
require 'irpack/packager'
require 'WindowsBase'
require 'utils'

class TC_Packager < Test::Unit::TestCase
  include Utils

  SrcFiles = {
    'foo.rb' => File.join(File.dirname(__FILE__), 'test_packager.rb'),
    'bar.rb' => File.join(File.dirname(__FILE__), 'test_cscompiler.rb'),
  }

  def test_pack
    package_file = tempfilename
    IRPack::Packager.pack(SrcFiles, package_file)
    package = System::IO::Packaging::Package.open(package_file, System::IO::FileMode.open)
    SrcFiles.each do |dst, src|
      uri = System::Uri.new(File.join('/', dst), System::UriKind.relative)
      assert(package.part_exists(uri))
      stream = package.get_part(uri).get_stream
      bytes = System::Array[System::Byte].new(stream.length)
      stream.read(bytes, 0, stream.length)
      assert_equal(File.open(src, 'rb'){|f|f.read}, bytes.to_a.pack('C*'))
    end
  end
end

