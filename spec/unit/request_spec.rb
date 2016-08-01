require 'spec_helper'
require 'rspec/expectations'

describe AkamaiRSpec::Request do
  let(:stg_domain) { 'www.example.com.edgesuite-staging.net' }
  let(:prod_domain) { 'www.example.com.edgesuite.net' }
  let(:url) { 'example.com' }
  let(:network) { 'prod' }
  before do
    AkamaiRSpec::Request.stg_domain = stg_domain
    AkamaiRSpec::Request.prod_domain = prod_domain
    AkamaiRSpec::Request.network = network
    stub_request(:any, stg_domain).to_return(
                  body: 'abc', status: [200, 'message'])
    stub_request(:any, prod_domain).to_return(
                  body: 'abc', status: [200, 'message'])
  end

  subject { described_class.get(url) }

  describe '#get' do
    context 'prod domain' do
      it 'queries the right domain' do
        expect(Net::HTTP).to receive(:new).with(prod_domain, anything).and_call_original
        subject
      end
    end

    context 'staging domain' do
      let(:network) { 'staging' }
      it 'quereis the right domain' do
        expect(Net::HTTP).to receive(:new).with(stg_domain, anything).and_call_original
        subject
      end
    end
  end
end
