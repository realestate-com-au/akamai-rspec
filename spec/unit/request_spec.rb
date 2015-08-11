require 'spec_helper'
require 'rspec/expectations'
require 'rest-client'

describe 'RestClient::Request' do
  describe '#domain' do
    let(:stg_domain) { 'www.example.com.edgesuite-staging.net' }
    let(:prod_domain) { 'www.example.com.edgesuite.net' }
    before do
      RestClient::Request.stg_domain(stg_domain)
      RestClient::Request.prod_domain(prod_domain)
    end

    it 'should select staging' do
      RestClient::Request.akamai_network('staging')
      expect(RestClient::Request.domain).to eq(stg_domain)
    end

    it 'should default to prod' do
      expect(RestClient::Request.domain).to eq(stg_domain)
    end
  end

end
