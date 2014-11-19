require 'spec_helper'
describe Servme::StubFilter do
  let(:url) { "stuff_by_id/1/details" }
  let(:method) { :post }
  let(:response) { "Details you wanted" }
  let(:status_code) { 200 }
  let(:params) { {a: 'param_1', b: 'param_2'} }
  let(:stringified_params) { Hash[params.map {|(k,v)| [k.to_s, v]}] }
  let(:basic_stub) {
    {
      url => {
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
  }

  let(:other_stubs) { {} }

  let(:stubs) { basic_stub.merge(other_stubs) }

  let(:request_url) { url }
  let(:request_method) { method }
  let(:request_params) { params }
  let(:request) { FakeRequest.new(request_url, request_method, request_params) }

  subject { Servme::StubFilter.new(stubs) }

  describe "#for_request" do
    let(:results) { subject.for_request(request) }

    context "exact match" do
      it "finds the stub with the exactly matched url, method and params" do
        results[:data].should == response
      end
    end

    context "no match" do
      let(:request_url) { "stuff_by_id/2/details" }

      it "returns nil" do
        results.should be_nil
      end
    end

    context "fuzzy matches" do
      context "by path" do
        context "astericks" do
          let(:url) { "stuff_by_id/*/details" }
          let(:request_url) { "stuff_by_id/3/details" }

          it "indicates an automatic match on any value in that part of the requested path" do
            results[:data].should == response
          end
        end

        context "by regex" do
          let(:url) { "stuff_by_id/~[2-4]/details" }
          context "matching requests" do
            let(:request_url) { "stuff_by_id/3/details" }
            it "matches request params using the regex provided after a tilde" do
              results[:data].should == response
            end
          end

          context "unmatching requests" do
            let(:request_url) { "stuff_by_id/5/details" }
            it "does not match value in that part of the requested path" do
              results.should be_nil
            end
          end
        end
      end

      context "by params" do
        context "astericks" do
          let(:params) { {a: 'param_1', b: '*'} }
          let(:request_params) { {a: 'param_1', b: 'any random crazy value!!!!' } }

          it "indicates an automatic match on any value on the requested param key" do
            results[:data].should == response
          end
        end

        context "by regex" do
          let(:params) { {a: 'param_1', b: '~[ABC|DEF]'} }

          context "matching requests" do
            let(:request_params) { {a: 'param_1', b: 'ABC' } }
            it "matches request params using the regex provided after a tilde" do
              results[:data].should == response
            end
          end

          context "unmatching requests" do
            let(:request_params) { {a: 'param_1', b: 'XYZ' } }
            it "does not match value in that part of the requested path" do
              results.should be_nil
            end
          end
        end
      end

    end
  end
end