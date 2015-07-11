describe 'honour_origin_cache_headers' do
  it 'should succeed when headers are the same' do
    origin = 'http://www.example.com/stuff'
    headers = { 'cache-control' => 'private, max-age=0, no-store', 'expires' => 'Thu, 01 Dec 2015 07:00:00 GMT' }
    stub_request(:any, DOMAIN + '/stuff').to_return(body: 'body', headers: headers)
    stub_request(:any, origin).to_return(body: 'body', headers: headers)
    expect(DOMAIN + '/stuff').to honour_origin_cache_headers(origin)
  end
end
