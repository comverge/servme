require 'spec_helper'
describe Servme::Stubber do
  subject { Servme::Stubber.instance }

  before {
    subject.clear
  }

  let(:url) { "my_api/stuff_i_want" }
  let(:method) { :post }
  let(:response) { "Stuff you wanted" }
  let(:status_code) { 300 }
  let(:params) { {a: 'param_1', b: 'param_2'} }
  let(:stringified_params) { Hash[params.map {|(k,v)| [k.to_s, v]}] }

  let(:config) {
    {
      url: url,
      method: method,
      response: response,
      status_code: status_code,
      params: params
    }
  }

  let(:stub_body) {
    {
      post: {
        stringified_params => {
          data: response,
          headers: { "Content-Type" => "application/json" },
          status_code: status_code,
          params: params
        }
      }
    }
  }

  describe "#stub" do
    it "uses the provided config hash to add a new stub to the stubbings collection" do
      subject.stub(config)
      subject.stubbings[url].should == stub_body
    end

    it "defaults the method to GET if not provided" do
      config.delete(:method)
      subject.stub(config)
      subject.stubbings[url][:get].should_not be_nil
    end

    it "defaults to status code 200 if not provided" do
      config.delete(:status_code)
      subject.stub(config)
      subject.stubbings[url][:post][stringified_params][:status_code].should == 200
    end
  end
end