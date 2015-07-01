require 'rspec'
require_relative 'common'

def check_ssl_serial(addr, port, url, serial)
  cert_serial = ssl_cert(addr, port, url).serial.to_s(16).upcase
  fail("Incorrect S/N of: #{cert_serial}") unless cert_serial == serial.upcase
end

def ssl_cert(addr, port, url)
  ssl_client = ssl_client_for_verify_cert(TCPSocket.new(addr, port), addr, url)
  # We get this after the request as we have layer 7 routing in Akamai
  cert = OpenSSL::X509::Certificate.new(ssl_client.peer_cert)
  ssl_client.sysclose
  cert
end

def dummy_request(url, addr)
  "GET #{url} HTTP/1.1\r\n" \
    'User-Agent: Akamai-Regression-Framework\r\n' \
    "Host: #{addr}\r\n" \
  'Accept: */*\r\n'
end

def ssl_client_for_verify_cert(tcp_client, addr, url)
  ssl_client = OpenSSL::SSL::SSLSocket.new(tcp_client)
  ssl_client.sync_close = true
  ssl_client.connect
  ssl_client.puts(dummy_request(url, addr))
  ssl_client
end

def responsify(maybe_a_url)
  if maybe_a_url.is_a? RestClient::Response
    maybe_a_url
  else
    RestClient.get(maybe_a_url, akamai_debug_headers)
  end
end

RSpec::Matchers.define :be_successful do
  match do |url|
    response = responsify url
    fail('Response was not successful') unless response.code == 200
    true
  end
end

RSpec::Matchers.define :be_verifiably_secure do
  match do |url|
    begin
      RestClient::Request.execute(method: :get, url: url, verify_ssl: OpenSSL::SSL::VERIFY_PEER)
      true
    rescue => e
      raise("#{url} could not be verified as secure, :sad_panda: #{e.message}")
    end
  end
end
