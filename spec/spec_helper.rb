require 'rspec'
require 'webmock/rspec'
require 'akamai_rspec'

DOMAIN = "www.example.com.edgesuite.net"
RestClient::Request.prod_domain(DOMAIN)
