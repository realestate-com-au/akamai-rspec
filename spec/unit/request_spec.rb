require 'spec_helper'
require 'rspec/expectations'
require 'rest-client'

describe RestClient::Request do
  let(:stg_domain) { 'www.example.com.edgesuite-staging.net' }
  let(:prod_domain) { 'www.example.com.edgesuite.net' }
  before do
    RestClient::Request.stg_domain(stg_domain)
    RestClient::Request.prod_domain(prod_domain)
  end

  describe '#domain' do
    it 'should select staging' do
      RestClient::Request.akamai_network('staging')
      expect(RestClient::Request.domain).to eq(stg_domain)
    end

    it 'should default to prod' do
      RestClient::Request.akamai_network('not staging')
      expect(RestClient::Request.domain).to eq(prod_domain)
    end
  end

  describe '#http_url' do
    it 'should succeed without leading /' do
      path = 'something'
      RestClient::Request.akamai_network('prod')
      expect(RestClient::Request.http_url(path)).to eq("http://#{prod_domain}/#{path}")
    end

    it 'should succeed with a leading /' do
      path = '/something'
      RestClient::Request.akamai_network('prod')
      expect(RestClient::Request.http_url(path)).to eq("http://#{prod_domain}#{path}")
    end

    it 'should succeed with an empty path' do
      path = ''
      RestClient::Request.akamai_network('prod')
      expect(RestClient::Request.http_url(path)).to eq("http://#{prod_domain}/")
    end
  end

  describe '#https_url' do
    it 'should succeed without leading /' do
      path = 'something'
      RestClient::Request.akamai_network('prod')
      expect(RestClient::Request.https_url(path)).to eq("https://#{prod_domain}/#{path}")
    end

    it 'should succeed with a leading /' do
      path = '/something'
      RestClient::Request.akamai_network('prod')
      expect(RestClient::Request.https_url(path)).to eq("https://#{prod_domain}#{path}")
    end

    it 'should succeed with an empty path' do
      path = ''
      RestClient::Request.akamai_network('prod')
      expect(RestClient::Request.https_url(path)).to eq("https://#{prod_domain}/")
    end
  end
end
