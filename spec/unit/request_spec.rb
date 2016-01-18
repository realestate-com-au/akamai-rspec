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
    stub_status(prod_domain, 200)
    stub_status(stg_domain, 200)
  end

  subject { described_class.get(url) }

  describe '#get' do
    context 'prod domain' do
      it 'queries the right domain' do
        expect(Net::HTTP).to receive(:start).with(prod_domain, anything)
        subject
      end
    end

    context 'staging domain' do
      let(:network) { 'staging' }
      it 'quereis the right domain' do
        expect(Net::HTTP).to receive(:start).with(stg_domain, anything)
        subject
      end
    end
  end

  describe '#headers' do
    it 'returns a hash' do
      expect(subject.headers).to be_a(Hash)
    end

    context 'header value is a single element array' do
      before do
        stub_request(:any, prod_domain).to_return(
          body: 'abc', headers: { 'Bacon' => ['Yes'] }, status: [200, 'message'])
      end

      it 'returns a string' do
        expect(subject.headers[:bacon]).to eq('Yes')
      end
    end
  end
end
