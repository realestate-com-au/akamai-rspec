require 'rspec'
require 'webmock/rspec'
require 'akamai_rspec'

DOMAIN = "www.example.com.edgesuite.net"
RestClient::Request.prod_domain(DOMAIN)

def stub_headers(url, headers, body="abc")
  stub_request(:any, DOMAIN + url).to_return(
    :body => body, :headers => headers)
end

def stub_status(url, status)
  stub_request(:any, DOMAIN + url).to_return(
    :body => "abc", :status => [status, "message"])
end
