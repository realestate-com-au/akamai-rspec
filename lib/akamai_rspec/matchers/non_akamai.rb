require 'rspec'
require 'socket'
require 'openssl'
require 'uri'

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

RSpec::Matchers.define :be_successful do
  match do |url|
    response = AkamaiRSpec::Request.get url
    fail("Response #{response} was not successful for #{url}") unless response.code == 200
    true
  end
end

RSpec::Matchers.define :respond_with_headers do |headers|
  match do |url|
    @response = AkamaiRSpec::Request.get url
    headers.each do |k, v|
      fail "Expected header #{k} to be #{v}, got #{@response.headers[k]}" unless @response.headers[k] == v
    end
    true
  end
end

RSpec::Matchers.define :be_verifiably_secure do (verify = OpenSSL::SSL::VERIFY_PEER)
  match do |url|
    return false if URI(url).scheme == "http"
    url = "https://#{url}" unless URI(url).scheme
    begin
      # Avoid AkamaiRspec::Request as it turns off SSL checking
      @response = RestClient::Request.execute(method: :get, url: url, verify_ssl: verify)
      return true
    rescue => e
      @error = e
      return false
    end
  end

  failure_message do |url|
    "got error #{@error} fetching #{@response}"
  end
end

RSpec::Matchers.define :be_gzipped do
  match do |response_or_url|
    response = AkamaiRSpec::Request.get_decode response_or_url
    response.headers[:content_encoding] == 'gzip'
  end
end

RSpec::Matchers.define :have_cookie do |cookie|
  match do |response_or_url|
    response = AkamaiRSpec::Request.get response_or_url
    unless response.cookies[cookie]
      fail("Cookie #{cookie} not in #{response.cookies}")
    end
    response.cookies[cookie]
  end
end

RSpec::Matchers.define :be_forbidden do
  match do |url|
    response = AkamaiRSpec::Request.get url
    fail('Response was not forbidden') unless response.code == 403
    true
  end
end
