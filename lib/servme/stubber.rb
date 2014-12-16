require 'singleton'

module Servme
  class Stubber
    include Singleton

    attr_accessor :stubbings

    def initialize
      clear
    end

    def clear(path=nil)
      if path
        @stubbings[path] ||= nil
      else
        @stubbings = {}
      end
    end

    def stub(config)
      (@stubbings[config[:url]] ||= {}).tap do |urls|
        (urls[config[:method] || :get] ||= {}).tap do |methods|
          methods[stringify_keys(config[:params] || {})] = {
            :data => config[:response],
            :headers => get_headers(config),
            :status_code => config[:status_code] || 200,
            :params => config[:params]
          }
        end
      end

      Logger.instance.init_stub(config[:url], @stubbings)
    end

    private

    def get_headers(config)
      response = config[:response]

      headers = if response.is_a?(Hash)
        response.delete(:headers)
      end || {}

      headers.merge!(config[:headers] || {})

      Responder::DEFAULT_HEADERS.merge(headers)
    end

    def stringify_keys(params)
      Hash[params.map {|(k,v)| [k.to_s, v]}]
    end
  end
end
