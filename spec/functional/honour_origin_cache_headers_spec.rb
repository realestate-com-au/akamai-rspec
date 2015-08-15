describe 'honour_origin_cache_headers' do

  # Perhaps this should be something like (Time.now + 6.months).to_s ?
  let(:a_date_in_the_future) { 'Thu, 01 Dec 2015 07:00:00 GMT' }
  let(:a_date_in_the_future_plus_one) { 'Thu, 01 Dec 2015 07:01:00 GMT' }

  # The happy-path test
  it 'should succeed when headers are the same' do
    origin = 'http://www.example.com/stuff'
    headers = { 'cache-control' => 'private, max-age=0, no-store', 'expires' => a_date_in_the_future }
    stub_request(:any, DOMAIN + '/stuff').to_return(body: 'body', headers: headers)
    stub_request(:any, origin).to_return(body: 'body', headers: headers)
    expect(DOMAIN + '/stuff').to honour_origin_cache_headers(origin)
  end

  # Tweak the max-age parameter, see if gets picked up
  it 'should fail when max age is slightly smaller' do
    origin = 'http://www.example.com/stuff'
    headers1 = { 'cache-control' => 'public, max-age=120', 'expires' => a_date_in_the_future }
    headers2 = { 'cache-control' => 'public, max-age=60', 'expires' => a_date_in_the_future }
    stub_request(:any, DOMAIN + '/stuff').to_return(body: 'body', headers: headers1)
    stub_request(:any, origin).to_return(body: 'body', headers: headers2)
    expect {
      expect(DOMAIN + '/stuff').to honour_origin_cache_headers(origin)
    }.to raise_error(/Akamai sent a max-age greater than Origin/)
  end

  # Tweak the max-age the other way
  it 'should succeed when max age is slightly larger' do
    origin = 'http://www.example.com/stuff'
    headers1 = { 'cache-control' => 'public, max-age=60', 'expires' => a_date_in_the_future }
    headers2 = { 'cache-control' => 'public, max-age=120', 'expires' => a_date_in_the_future }
    stub_request(:any, DOMAIN + '/stuff').to_return(body: 'body', headers: headers1)
    stub_request(:any, origin).to_return(body: 'body', headers: headers2)
    expect(DOMAIN + '/stuff').to honour_origin_cache_headers(origin)
  end

  # Flip the cache-control from private to public...
  it 'should fail when Akamai changes the cache-control values' do
    origin = 'http://www.example.com/stuff'
    headers1 = { 'cache-control' => 'private, max-age=0', 'expires' => a_date_in_the_future }
    headers2 = { 'cache-control' => 'public, max-age=0', 'expires' => a_date_in_the_future }
    stub_request(:any, DOMAIN + '/stuff').to_return(body: 'body', headers: headers1)
    stub_request(:any, origin).to_return(body: 'body', headers: headers2)
    expect {
      expect(DOMAIN + '/stuff').to honour_origin_cache_headers(origin)
    }.to raise_error(/Origin sent .* but Akamai did not/)
  end

  # Now let's sneakily change no-store to no-cache...
  it 'should fail when Akamai changes the cache-control values' do
    origin = 'http://www.example.com/stuff'
    headers1 = { 'cache-control' => 'public, max-age=0, no-store', 'expires' => a_date_in_the_future }
    headers2 = { 'cache-control' => 'public, max-age=0, no-cache', 'expires' => a_date_in_the_future }
    stub_request(:any, DOMAIN + '/stuff').to_return(body: 'body', headers: headers1)
    stub_request(:any, origin).to_return(body: 'body', headers: headers2)
    expect {
      expect(DOMAIN + '/stuff').to honour_origin_cache_headers(origin)
    }.to raise_error(/Origin sent .* but Akamai did not/)
  end

  # Check the expires value is preserved
  it 'should fail if the expires value are not identical' do
    origin = 'http://www.example.com/stuff'
    headers1 = { 'cache-control' => 'public, max-age=0, no-store', 'expires' => a_date_in_the_future }
    headers2 = { 'cache-control' => 'public, max-age=0, no-store', 'expires' => a_date_in_the_future_plus_one }
    stub_request(:any, DOMAIN + '/stuff').to_return(body: 'body', headers: headers1)
    stub_request(:any, origin).to_return(body: 'body', headers: headers2)
    expect {
      expect(DOMAIN + '/stuff').to honour_origin_cache_headers(origin)
    }.to raise_error(/Origin sent .* but Akamai sent/)
  end
end
