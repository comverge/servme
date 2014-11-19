require 'servme'

require 'rack/test'
require 'rspec/given'

RSpec.configure do |config|
  config.include Rack::Test::Methods
end

RSpec::Matchers.define :be_json do |expected|
  match do |actual|
    actual == JSON::dump(expected)
  end
end

Servme.configure do |config|
  config.ignore_file_types = %w[]
  config.ignore_paths = ["/"]
  config.ignore_param_keys = ["_"]
end

class FakeRequest
  attr_accessor :path, :request_method, :params
  def initialize(path, request_method, params)
    @path = path
    @request_method = request_method
    @params = params
  end
end