require 'spec_helper'

describe 'honour_origin_cache_headers' do

  let(:a_date_in_the_future) { 'Thu, 01 Dec 2015 07:00:00 GMT' }
  let(:a_date_in_the_future_plus_one) { 'Thu, 01 Dec 2015 07:01:00 GMT' }
  let(:origin_url) { 'http://www.example.com/stuff' }
  subject { DOMAIN + '/stuff' }

  before do
    stub_request(:any, DOMAIN + '/stuff').to_return(body: 'body', headers: akamai_headers)
    stub_request(:any, origin_url).to_return(body: 'body', headers: origin_headers)
  end

  def h(cache_control, expires=a_date_in_the_future)
    { 'cache-control' => cache_control, 'expires' => expires }
  end

  describe 'when headers are the same' do
    let(:akamai_headers) { h 'private, max-age=0, no-store' }
    let(:origin_headers) { h 'private, max-age=0, no-store' }
    it { should honour_origin_cache_headers(origin_url) }
  end

  describe "when akamai changes the max-age" do
    let(:origin_headers) { h 'public, max-age=60' }

    describe "to a longer one" do
      let(:akamai_headers) { h 'public, max-age=120' }

      it "fails" do
        expect {
          expect(DOMAIN + '/stuff').to honour_origin_cache_headers(origin_url)
        }.to raise_error(/Akamai sent a max-age greater than Origin/)
      end
    end

    describe 'to a shorter one' do
      let(:akamai_headers) { h 'public, max-age=40' }
      it { should honour_origin_cache_headers(origin_url) }
    end

    describe 'by removing it' do
      let(:akamai_headers) { h 'public' }
      it { should honour_origin_cache_headers(origin_url) }
    end

    describe 'by adding it' do
      let(:origin_headers) { h 'public' }
      let(:akamai_headers) { h 'public, max-age=40' }

      it "fails" do
        expect {
          expect(DOMAIN + '/stuff').to honour_origin_cache_headers(origin_url)
        }.to raise_error(/Akamai sent a max-age but Origin did not/)
      end
    end
  end

  describe 'when akamai changes the cache-control values' do
    describe "from private to public" do
      let(:origin_headers) { h 'private, max-age=0, no-store' }
      let(:akamai_headers) { h 'public, max-age=0, no-store' }
      it "fails" do
        expect {
          expect(DOMAIN + '/stuff').to honour_origin_cache_headers(origin_url)
        }.to raise_error(/Origin sent .* but Akamai did not/)
      end
    end

    describe "from no-cache to no-store" do
      let(:origin_headers) { h 'private, max-age=0, no-cache' }
      let(:akamai_headers) { h 'private, max-age=0, no-store' }
      it "fails" do
        expect {
          expect(DOMAIN + '/stuff').to honour_origin_cache_headers(origin_url)
        }.to raise_error(/Origin sent .* but Akamai did not/)
      end
    end

    describe "to a later expires date" do
      let(:origin_headers) { h 'private, max-age=0, no-store' }
      let(:akamai_headers) { h 'private, max-age=0, no-store', a_date_in_the_future_plus_one }
      it "fails" do
        expect {
          expect(DOMAIN + '/stuff').to honour_origin_cache_headers(origin_url)
        }.to raise_error(/Origin sent .* but Akamai sent/)
      end
    end
  end
end
