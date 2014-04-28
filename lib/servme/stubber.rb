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
            :status_code => config[:status_code] || 200,
            :params => config[:params]
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
      method = req.request_method.downcase.to_sym
      begin
        path = @stubbings[req.path] || {}
        methods = path[method] || {}
        stub = methods[req.params]

        if req.path == "/api_users/sign_out"
          return methods[{}]
        end

        if stub.nil? && req.path !~ /\.(woff|gif|png|ico|css|js)$/ && !(req.path == "/")
          print_diff(req, method)
        end
        stub
      rescue NoMethodError
        nil
      end
    end

    def print_diff(req, method)
      methods = @stubbings[req.path]
      if methods.nil?
        puts "\nUnexpected path #{req.path}\n\n"
        return
      end

      paramPairs = methods[method]
      if paramPairs.nil?
        puts "\nUnexpected method #{method} for path #{req.path}\n\n"
        return
      end

      actual_params = stringify_keys(req.params)
      actual_params_array = actual_params.to_a

      paramPairs.each_key do |key|
        exp_params = stringify_keys(paramPairs[key][:params])
        next if exp_params.nil?
        exp_params_array = exp_params.to_a
        diff = exp_params_array - actual_params_array
        act_diff = actual_params_array - exp_params_array
        puts "\n\nServme: #{req.path} [#{method}]\nparams expected diff: #{Hash[diff]}\nparams actual diff: #{Hash[act_diff]}\n\n"
      end
    end

    def stringify_keys(params)
      Hash[params.map {|(k,v)| [k.to_s, v]}]
    end
  end
end
