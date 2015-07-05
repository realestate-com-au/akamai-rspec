require 'rspec'
require 'webmock/rspec'
require 'akamai_rspec'

DOMAIN = 'www.example.com.edgesuite.net'
RestClient::Request.prod_domain(DOMAIN)

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

module Kernel
  def suppress_warnings
    original_verbosity = $VERBOSE
    $VERBOSE = nil
    result = yield
    $VERBOSE = original_verbosity
    return result
  end
end
