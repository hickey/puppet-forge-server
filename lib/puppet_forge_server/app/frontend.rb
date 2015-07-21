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

require 'sinatra/base'
require 'haml'
require 'json'

module PuppetForgeServer::App
  class Frontend < Sinatra::Base

    configure do
      set :haml, :format => :html5
      enable :logging
      use ::Rack::CommonLogger, PuppetForgeServer::Logger.get(:access)
    end

    before do
      env['rack.errors'] =  PuppetForgeServer::Logger.get(:server)
    end

    def initialize(root, backends, http_client = PuppetForgeServer::Http::HttpClient.new)
      super(nil)
      settings.root = root
      @backends = backends
      @http_client = http_client
      @upload_status = nil
      @log = PuppetForgeServer::Logger.get(:server)
      @log.info 'Application UI initialized'
    end

    get '/' do
      haml :index
    end

    get '/modules' do
      query = params[:query]
      modules = get("#{request.base_url}/v3/modules?query=#{query}")['results']
      haml :modules, :locals => {:query => query, :modules => modules}
    end

    get '/upload' do
      haml :upload
    end
    
    post '/upload' do
      unless params[:file] &&
        @upload_status = "No file selected"
        return haml :upload
      end
      
      @log.info "Uploading #{params[:file][:filename]} to local forge installation"
      @backends.each do |backend|
        class_type = (backend.class.to_s.split('::'))[-1]
        if class_type == 'Directory'
          if backend.upload params[:file]
            @upload_status = :success
            return haml :upload 
          end
        end
      end
      
      @upload_status = :failure
      haml :upload
    end
    
    
    private
    def get(relative_url)
      begin
        JSON.parse(@http_client.get(relative_url))
      rescue
        {'results' => []}
      end
    end
  end
end
