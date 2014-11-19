module Servme
  class StubFilter
    attr_accessor :all_stubs

    def initialize(stubs)
      @all_stubs = stubs
    end

    def for_request(request)
      begin
        matching_stubs = by_path(request, @all_stubs)
        matching_stubs = by_method(request, matching_stubs)
        by_params(request, matching_stubs)
      rescue NoMethodError
       nil
      end
    end

    private

    def by_path(request, possible_stubs)
      path = request.path
      unless stubs = possible_stubs[path]
        stub_parts = possible_stubs.detect do |stub_path, stubs|
          stub_path_parts = stub_path.split("/")
          path_part_index = 0
          stub_path_parts.all? do |stub_path_part|
            path_part = path.split("/")[path_part_index]
            path_part_index += 1
            if stub_path_part == '*'
              true
            elsif stub_path_part[0] == '~'
              Regexp.new(stub_path_part.delete('~'), true).match(path_part)
            else
              stub_path_part == path_part
            end
          end
        end
        stubs = stub_parts.last if stub_parts
      end

      unless stubs
        if ignorable_path?(path)
          logger.ignoring_path_not_found(path)
        else
          logger.stubs_not_found(possible_stubs, :path, request)
        end
      end

      stubs
    end

    def by_method(request, possible_stubs)
      stubs = possible_stubs[request.request_method.downcase.to_sym]
      logger.stubs_not_found(possible_stubs, :request_method, request) unless stubs
      stubs
    end

    def by_params(request, possible_stubs)
      params = request.params
      ignore_param_keys.each{|key| params.delete(key) }

      stub = possible_stubs[params] || possible_stubs[stringify_keys(params)]

      unless stub
        stub_parts = possible_stubs.detect do |stub_params, stub|
          if stub_params.length == params.length
            stringify_keys(stub_params).all? do |stub_param_key, value|
              request_param_value = stringify_keys(params)[stub_param_key]
              case value
              when '*', request_param_value
                true
              else
                value[0] == '~' && Regexp.new(value.delete('~'), true).match(request_param_value)
              end
            end
          else
            false
          end
        end

        stub = stub_parts.last if stub_parts
      end

      logger.stubs_not_found(possible_stubs, :params, request) unless stub
      stub
    end

    def ignore_file_types
      Servme.configuration.ignore_file_types
    end

    def ignore_paths
      Servme.configuration.ignore_paths
    end

    def ignorable_path?(path)
      Regexp.new(ignore_file_types.join('|')).match(path) || ignore_paths.include?(path)
    end

    def ignore_param_keys
      Servme.configuration.ignore_param_keys
    end

    def stringify_keys(params)
      Hash[params.map {|(k,v)| [k.to_s, v]}]
    end

    def logger
      Logger.instance
    end

  end
end
