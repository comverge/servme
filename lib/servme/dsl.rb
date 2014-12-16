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

  def self.reset(path=nil)
    Logger.instance.alert_reset(path)
    Service.clear(path)
  end

  def self.log(message)
    Logger.instance.write_hr(message)
  end

  def self.paths(show_responses = false)
    if show_responses
      Stubber.instance.stubbings
    else
      Stubber.instance.stubbings.keys
    end
  end

  def self.stubs_for_url(url)
    Stubber.instance.stubbings[url]
  end
end
