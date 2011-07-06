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

require 'WindowsBase'

module IRPack
  module Packager
    include System
    include System::IO::Packaging

    RelType = 'http://schemas.openxmlformats.org/package/2006/relationships/meta data/core-properties'
    module_function
    def pack(files, package_file, compress=false)
      compress_option = compress ? CompressionOption.normal : CompressionOption.not_compressed
      package = Package.open(package_file, System::IO::FileMode.create)
      files.each do |src, dest|
        uri = PackUriHelper.create_part_uri(Uri.new(dest, UriKind.relative))
        part = package.create_part(uri, 'application/octet-stream', compress_option)
        stream = part.get_stream
        File.open(src, 'rb') do |f|
          data = f.read
          stream.write(data, 0, data.size)
        end
        stream.close
        package.create_relationship(uri, TargetMode.internal, RelType)
      end
      package.close
    end
  end
end

