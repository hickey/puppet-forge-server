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
require 'uri'

module PuppetForgeServer::Backends
  class Proxy

    def initialize(url, cache_dir, http_client)
      @url = URI.parse(url)
      @cache_dir = File.join(cache_dir, Digest::SHA1.hexdigest(url))
      @http_client = http_client
      @log = PuppetForgeServer::Logger.get
    end

    def get_file_buffer(relative_path)
      buffer = download(relative_path)
      path = File.join(@cache_dir, relative_path[0].downcase, relative_path)
      File.open(path, 'wb') do |file|
        file.write(buffer.read)
      end
        
      File.open(path, 'rb')
    rescue => e
      @log.error("#{self.class.name} failed downloading file '#{relative_path}'")
      @log.error("Error: #{e}")
      return nil
    end

    def upload(file_data)
      @log.error 'File upload is not supported by the proxy backends'
      raise RuntimeError, 'File upload is not supported by the proxy backends'
    end

    def to_s
      class_type = (self.class.to_s.split('::'))[-1]
      "#{class_type}<#{__id__.to_s(16)}> (#{@url}, #{@cache_dir})"
    end
    
    protected
    attr_reader :log

    def get(relative_url)
      @http_client.get(URI.join(@url, relative_url))
    end

    def download(relative_url)
      @http_client.download(URI.join(@url, @api_file_path, relative_url))
    end

  end
end
