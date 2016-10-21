require 'spec_helper'
require 'rspec/expectations'
require 'rest-client'

describe 'honour_origin_cache_headers' do
  context 'fix_date_header' do
    let(:date) { Time.now }
    let(:headers) { {} }
    it 'should leave filled in date unchanged' do
      origin_response = double(RestClient::Response)
      allow(origin_response).to receive(:headers) { { :date => 'something' } }
      expect(fix_date_header(origin_response)).to equal(origin_response)
    end

    it 'should fill in date if it is absent' do
      allow(Time).to receive(:now).and_return(date)
      origin_response = double(RestClient::Response)
      allow(origin_response).to receive(:headers).and_return(headers)
      expect(fix_date_header(origin_response).headers[:date]).to eq(date.httpdate)
    end

  end
end
