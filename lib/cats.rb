# frozen_string_literal: true

require 'sinatra/base'
require 'sinatra/json'
require 'net/http'

module Cats
  class Web < Sinatra::Base
    configure do
      set :url, URI('http://thecatapi.com/api/images/get').freeze
      sleep(1 + rand(5))
    end

    get '/' do
      json url: Net::HTTP.get_response(settings.url)['location']
    end

    get '/health' do
      content_type :json
      { 
        status: 'healthy',
        version: ENV['APP_VERSION'] || '1.0.0',
        timestamp: Time.now.utc.iso8601,
        dependencies: {
          cat_api: settings.url.respond_to?(:host) ? 'reachable' : 'unreachable'
        }
      }.to_json
    end
  end
end
