require 'rspec'
require 'webmock/rspec'
require 'akamai_rspec'

DOMAIN = 'www.example.com.edgesuite.net'
AkamaiRSpec::Request.prod_domain = DOMAIN

def stub_headers(url, headers, body = 'abc')
  stub_request(:any, DOMAIN + url).to_return(
    body: body, headers: headers)
end

def stub_status(url, status)
  stub_request(:any, DOMAIN + url).to_return(
    body: 'abc', status: [status, 'message'])
end

def stub_redirect(status, location = '/redirected')
  stub_request(:any, DOMAIN + '/redirect').to_return(
    body: 'abc', headers: { 'Location' => DOMAIN + location }, status: [status, 'message'])
end
