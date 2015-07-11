require 'spec_helper'
require 'rspec/expectations'
require 'rest-client'
require 'byebug'

describe 'honour_origin_cache_headers' do
  context 'fix_date_header' do
    it 'should leave filled in date unchanged' do
      origin_response = double(RestClient::Response)
      allow(origin_response).to receive(:headers) { { :date => 'something' } }
      expect(fix_date_header(origin_response)).to equal(origin_response)
    end

    it 'should fill in date if it is absent' do
      pending("the code under test can't seem to change the double")
      origin_response = double(RestClient::Response)
      allow(origin_response).to receive(:headers) { { } }
      expect(fix_date_header(origin_response).headers[:date]).to equal(Time.now.httpdate)
    end

  end
end
