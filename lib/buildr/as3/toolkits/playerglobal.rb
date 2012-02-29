#
# Copyright (C) 2012 by Justin Walsh / http://theJustinWalsh.com
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#

require 'fileutils'

module Buildr
  module AS3
    module Toolkits
      class PlayerGlobal

        attr_reader :home, :playerglobal_swc

        def initialize(version, flex_sdk)
          @version = version
          @flex_sdk = flex_sdk
          @spec = "com.adobe.flex:playerglobal:swc:#{@version}"
          @swc = Buildr.artifact(@spec)
          self
        end

        def invoke #:nodoc:
          @url ||= generate_url_from_version @version

          Buildr::download(Buildr::artifact(@spec) => @url).invoke
          return unless File.exists? @swc.to_s

          copy_player
          self
        end

        # :call-seq:
        #   from(url) => self
        #
        # * You can pass a url where the FlexSDK should be downloaded from as a string:
        # FLEX_SDK.from("http://domain.tld/flex_sdk.zip")
        # * You can pass :maven as a parameter to download it from a maven repository:
        # FLEX_SDK.from(:maven)
        # * If you don't call this function at all, buildr-as3 will try and resolve a url on the adobe-website
        # to download the FlexSDK
        def from(url)
          @url = url
          self
        end

        private

        def generate_url_from_version(version)
          version_major = version.split(".")[0]
          version_minor = version.split(".")[1]
          version_minor = 0 # Adobe doesn't seem to store the player global properly
          version_id = "#{version_major}_#{version_minor}"
          
          "http://fpdownload.macromedia.com/pub/flashplayer/updaters/#{version_major}/playerglobal#{version_id}.swc"
        end

        def copy_player
          project_dir = Dir.getwd
          Dir.chdir File.dirname(@swc.to_s)

          destination = "#{@flex_sdk.home}/frameworks/lib/player/#{@version}"
          FileUtils.mkdir_p destination
          FileUtils.cp(@swc.to_s, "destination/playerglobal.swc")
          Dir.chdir project_dir
        end
      end
    end
  end
end
