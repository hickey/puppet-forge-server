# -*- encoding: utf-8 -*-
#
# Copyright 2014 North Development AB
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'json'
require 'digest/sha1'

module PuppetForgeServer::Backends
  class Cache < PuppetForgeServer::Backends::Directory
    include PuppetForgeServer::Utils::Archiver

    attr_reader :priority
    
    def initialize(url, cache_dir)
      @cache_dir = File.join(cache_dir, Digest::SHA1.hexdigest(url))
      @log = PuppetForgeServer::Logger.get
      
      # Give highest priority to locally hosted modules
      @priority = 0

      # Create directory structure for all alphabetic letters
      (10...36).each do |i|
        FileUtils.mkdir_p(File.join(@cache_dir, i.to_s(36)))
      end
    end

    def get_file_buffer(relative_path)
      file_name = relative_path.split('/').last
      path = Dir["#{@cache_dir}/**/#{file_name}"].first
      if not path.nil? and File.exist?(path)
        File.open(path, 'rb') 
      end
    end

    def upload(file_data)
      @log.error 'File upload is not supported by the cache backend'
      raise RuntimeError, 'File upload is not supported by the cache backend'
    end

    def to_s
      class_type = (self.class.to_s.split('::'))[-1]
      "#{class_type}<#{__id__.to_s(16)}> (#{@cache_dir})"
    end
    
    protected
    attr_reader :log

    def get_file_metadata(file_name, options)
      options = ({:with_checksum => true}).merge(options)
      Dir["#{@cache_dir}/**/#{file_name}"].map do |path|
        {
            :metadata => parse_dependencies(PuppetForgeServer::Models::Metadata.new(read_metadata(path))),
            :checksum => options[:with_checksum] == true ? Digest::MD5.file(path).hexdigest : nil,
            :path => "#{Pathname.new(path).relative_path_from(Pathname.new(@cache_dir))}"
        }
      end
    end
  end
end
