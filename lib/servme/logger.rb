require 'fileutils'
require 'singleton'
require 'yaml'

module Servme
  class Logger
    include Singleton

    attr_accessor :output_file, :level

    def initialize
      @level = log_level
      @output_file = File.open output_file_path, 'w'
      @last_request_handled = nil
      init_session
    end

    def stubs_not_found(possible_stubs, search_type, request)
      search_by = request.send(search_type)
      formatted_matches = possible_stubs.is_a?(Hash) ? possible_stubs.keys : possible_stubs

      unless @last_request_handled == request
        write_hr "Unmatched Stub", :error
        write_line "Path", request.path unless search_type == :path
      end

      write_line "#{search_type} Search", search_by
      write_line "Available #{search_type}", formatted_matches.to_yaml

      @last_request_handled = request
    end

    def init_stub(path, stub)
      return unless level == :info
      write_hr "Stubbing"
      write_line "Path", path
      write_line "Config", stub[path].to_yaml
    end

    def request_response_pair(request, response)
      return unless level == :info
      write_hr "Handling Request"
      write_line "Request", "#{request.request_method} #{request.path}"
      write_line "Params", request.params.to_yaml
      write_line "Response", response.to_yaml
    end

    def ignoring_path_not_found(path)
      return unless level == :info
      write_hr "Ignoring allowed unmatched path"
      write_line "Path", path
    end

    def alert_reset
      return unless level == :info
      write_hr "Resetting - all stubs deleted"
    end

    private

    def log_level
      Servme.configuration.log_level
    end

    def output_type
      Servme.configuration.output_type
    end

    def output_file_path
      FileUtils::mkdir_p Servme.configuration.logger_path
      File.join(Servme.configuration.logger_path, Servme.configuration.logger_file)
    end

    def init_session
      write_hr("Session Starting")
    end

    def write_hr(title = '', type = :info)
      char = type == :info ? "-" : "!"
      spacer = char * ((76 - title.length) / 2)
      output_file.puts
      output_file.puts "#{spacer}  #{title}  #{spacer}"
    end

    def write_line(type, info)
      output_file.puts "[#{Time.now}] #{type.upcase} : #{info}"
    end
  end
end