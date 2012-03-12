#
# Copyright (C) 2011 by Justin Walsh / http://theJustinWalsh.com
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

require 'buildr'
require 'fileutils'

module Buildr
  module AS3
    module Packaging

      class AneTask < Rake::FileTask
        include Extension

        attr_writer :target_ane, :src_swc, :flexsdk
        attr_reader :target_ane, :src_swc, :descriptor, :platforms, :flexsdk

        def initialize(*args) #:nodoc:
          super
          enhance do

            fail "File not found: #{src_swc}" unless File.exists? src_swc
            fail "File not found: #{descriptor}" unless File.exists? descriptor

            cmd_args = []
            cmd_args << "-jar" << flexsdk.adt_jar
            cmd_args << "-package"
            cmd_args << "-target" << "ane"
            cmd_args << target_ane
            cmd_args << descriptor
            cmd_args << "-swc" << src_swc

            platforms.each do |key, value|
              cmd_args << "-platform" << key

              # Extract the library.swf files from each package
              target_dir = File.join(File.dirname(src_swc), key)
              if value.has_key? :swc
                directory target_dir

                zip_target = Buildr::Unzip.new(target_dir => value[:swc]).include('library.swf')
                zip_target.extract
              end
              if value.has_key? :lib
                source_file = value[:lib]
                target_file = File.join(target_dir, File.basename(value[:lib]))
                if (File.extname(source_file) == ".framework")
                  target_file = target_dir
                end
                FileUtils.cp_r source_file, target_file, :remove_destination => true
              end

              cmd_args << "-C" << target_dir << "."

              if value.has_key? :options
                cmd_args << "-platformoptions" << value[:options] 
              end
            end unless platforms.nil?

            #puts cmd_args.join " "

            unless Buildr.application.options.dryrun
              Java::Commands.java cmd_args
            end
          end
        end

        def needed?
          return true unless File.exists?(target_ane)

          needed = File.stat(src_swc).mtime > File.stat(target_ane).mtime ||
                   File.stat(descriptor).mtime > File.stat(target_ane).mtime

          platforms.each do |key, value|
            needed ||= File.stat(value[:swc]).mtime > File.stat(target_ane).mtime if value.has_key? :swc
            needed ||= File.stat(value[:lib]).mtime > File.stat(target_ane).mtime if value.has_key? :lib
            needed ||= File.stat(value[:options]).mtime > File.stat(target_ane).mtime if value.has_key? :options
          end unless platforms.nil?

          needed
        end

        first_time do
          desc 'create ane package task'
          Project.local_task('package_ane')
        end

        before_define do |project|
          AirTask.define_task('package_ane').tap do |package_ane|
            package_ane
          end
        end

        def sign(*args)
          args.each do |arg|
            @storetype = arg[:storetype] if arg.has_key? :storetype
            @keystore = arg[:keystore] if arg.has_key? :keystore
            @storepass = arg[:storepass] if arg.has_key? :storepass
            @appdescriptor = arg[:appdescriptor] if arg.has_key? :appdescriptor
          end
          self
        end

        def with(*args)
          @platforms ||= Hash.new
          args.each do |arg|
            case arg
              when Hash
                arg.each do |key, value|
                  if key == :platforms
                    @platforms = value
                  elsif key == :descriptor
                    @descriptor = value
                  end
                end
            end
          end
          puts @platforms.inspect
          self
        end

      end

      def package_ane(&block)
        task("package_ane").enhance &block
      end

      protected

      def package_as_ane(file_name)
        #fail("Package types don't match! :ane vs. :#{compile.packaging.to_s}") unless compile.packaging == :ane
        real_filename = "#{file_name.chomp(File.extname(file_name))}.ane"
        AneTask.define_task(real_filename).tap do |ane|
          ane.src_swc = File.join(compile.target.to_s, compile.options[:output] || "#{project.name.split(":").last}.#{compile.packaging.to_s}")
          ane.target_ane = real_filename
          ane.flexsdk = compile.options[:flexsdk]
        end
      end

    end
  end
end