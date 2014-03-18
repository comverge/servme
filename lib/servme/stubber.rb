require 'singleton'
module Servme
  class Stubber
    include Singleton

    def initialize
      @stubbings = {}
    end

    def clear
      @stubbings = {}
    end

    def stub(config)
      (@stubbings[config[:url]] ||= {}).tap do |urls|
        (urls[config[:method] || :get] ||= {}).tap do |methods|
          methods[stringify_keys(config[:params] || {})] = {
            :data => config[:response],
            :headers => get_headers(config),
            :status_code => config[:status_code] || 200
          }
        end
      end
    end

    def get_headers(config)
      response = config[:response]

      headers = if response.is_a?(Hash)
        response.delete(:headers)
      end || {}

      headers.merge!(config[:headers] || {})

      Responder::DEFAULT_HEADERS.merge(headers)
    end

    def stub_for_request(req)
      valid_paths = filter_paths(req.path, @stubbings)
      valid_methods = filter_methods(req.request_method, valid_paths)
      valid_params = filter_params(req.params, valid_methods)
      puts "*** WARNING: multiple stubs match requested route (#{req.path}. Using first. ***" if valid_params.length > 1
      valid_params.first
    rescue NoMethodError
      nil
    end

    def filter_methods(request, stubs)
      stubs.map{|path|
        path.map{|k, v| v if request.downcase.to_sym == k }.compact
      }.flatten
    end

    def filter_paths(request, stubs)
      stubs.map{|path, data|
        data if path.split("/").each_with_index.all?{|path_part, i|
          matches?(path_part, request.split("/")[i])
        }
      }.compact
    end

    def filter_params(request, stubs)
      stubs.map{|stub|
        stub.map{|stubbed_params, response|
          response if stubbed_params == request || stubbed_params.detect{|k,v|
            request.all?{|rpk, rpv| matches?(v, rpv) }
          }
        }.compact
      }.flatten
    end

    def matches?(val1, val2)
      val1 = val1.to_s
      val2 = val2.to_s
      val1 == val2 || val1 == '*' || (/^\/.*\/$/.match(val1) && Regexp.new(val1) =~ val2)
    rescue
      false
    end

    def stringify_keys(params)
      Hash[params.map {|(k,v)| [k.to_s, v]}]
    end
  end
end
