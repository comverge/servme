module Servme
  class Configuration
    attr_accessor :log_level, :output_type, :logger_path, :logger_file, :ignore_file_types, :ignore_paths, :ignore_param_keys

    def initialize
      @log_level = :info
      @output_type = :file
      @logger_path = "log"
      @logger_file = "servme.log"
      @ignore_file_types = []
      @ignore_paths = []
      @ignore_param_keys = []
    end
  end
end