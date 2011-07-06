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
require 'tempfile'

module Utils
  module_function
  def create_package(filename_or_contents, contents=nil, &block)
    if contents then
      package = System::IO::Packaging::Package.open(
        filename_or_contents,
        System::IO::FileMode.create)
    else
      package = System::IO::Packaging::Package.open(
        System::IO::MemoryStream.new,
        System::IO::FileMode.create)
      contents = filename_or_contents
    end
    contents.each do |path, content|
      uri = System::IO::Packaging::PackUriHelper.create_part_uri(System::Uri.new(path, System::UriKind.relative))
      part = package.create_part(
        uri,
        'application/octet-stream',
        System::IO::Packaging::CompressionOption.not_compressed)
      stream = part.get_stream
      stream.write(content, 0, content.bytesize)
      stream.close
      package.create_relationship(
        uri,
        System::IO::Packaging::TargetMode.internal,
        'http://schemas.openxmlformats.org/package/2006/relationships/meta data/core-properties')
    end
    block.call(package) if block
    package.close
    package
  end

  def tempfilename
    tmp = Tempfile.open(File.basename(__FILE__))
    tmp.close
    $tempfiles ||= []
    $tempfiles << tmp
    tmp.path
  end

  IronRubyAssemblies = %w[
    Microsoft.Dynamic
    Microsoft.Scripting
    Microsoft.Scripting.Core
    IronRuby
    IronRuby.Libraries
    IronRuby.Libraries.Yaml
  ]
  def ironruby_assemblies
    System::AppDomain.current_domain.get_assemblies.select {|asm| IronRubyAssemblies.include?(asm.get_name.name) }.collect {|asm| asm.location }
  end
end

