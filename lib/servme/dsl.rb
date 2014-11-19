module Servme
  module DSL
    def on(request)
      ServiceStubbing.new(request)
    end
  end

  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration)
  end

  #methods invoked statically Servme.foo_bar
  def self.start(options = {})
    Service.run!({
      :port => 51922
    }.merge(options))
  end

  def self.reset
    Logger.instance.alert_reset
    Service.clear
  end

end
