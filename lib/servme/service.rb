require 'thin'
require 'sinatra/base'
require 'json'

module Servme

  class Service < Sinatra::Base
    set :server, 'thin'

    get '*' do
      responder.respond(request)
    end

    post '*' do
     responder.respond(request)
    end

    put '*' do
      responder.respond(request)
    end

    delete '*' do
      responder.respond(request)
    end

    def responder
      @responder ||= Responder.new(
        self,
        {
          :static_file_root_path => settings.respond_to?(:static_file_root_path) ? settings.static_file_root_path : nil,
          :static_file_vdir => settings.respond_to?(:static_file_vdir) ? settings.static_file_vdir : nil
        }
      )
    end

    def self.clear(path=nil)
      Stubber.instance.clear(path)
    end
  end

end
