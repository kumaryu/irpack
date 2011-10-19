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

require 'fileutils'
require 'tmpdir'

if not Dir.respond_to?(:mktmpdir) or
   not File::Stat.instance_methods.include?(:world_writable) then
  def Dir.mktmpdir(prefix='d', tmpdir=Dir.tmpdir, &block)
    n = 0
    begin
      path = File.join(tmpdir, "#{prefix}-#{Time.now.to_i}-#{$$}-#{rand(0x100000000).to_s(36)}-#{n}")
      Dir.mkdir(path, 0700)
    rescue Errno::EEXIST
      n += 1
      retry
    end
    begin
      block.call(path)
    ensure
      FileUtils.remove_entry(path, true)
    end
  end
end

