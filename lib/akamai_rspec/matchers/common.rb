require 'securerandom'
require 'set'
require 'socket'
require 'time'
require 'openssl'
require 'uri'
require 'rspec'
require_relative 'redirects'
require_relative 'caching'
include AkamaiHeaders

# TODO make a proper matcher
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

RSpec::Matchers.define :be_served_from_origin do |origin|
  match do |url|
    response = responsify url
    fail 'No X-Cache-Key header' if response.headers[:x_cache_key].nil?
    unless response.headers[:x_cache_key].include?(origin)
      fail("x_cache_key has value '#{response.headers[:x_cache_key]}' which doesn't include '#{origin}'")
    end
    response.code == 200 && response.headers[:x_cache_key].include?(origin)
  end
end

def fix_date_header(origin_response)
  origin_response.headers[:date] = Time.now.httpdate unless origin_response.headers[:date]
  origin_response
end

def origin_response(uri, origin)
  uri.host = origin
  fix_date_header(RestClient::Request.execute(method: :get, url: uri.to_s, verify_ssl: false))
end

def clean_cc_directives(origin_response, akamai_response)
  origin_cc_directives = origin_response.headers[:cache_control].split(/[, ]+/).to_set
  akamai_cc_directives = akamai_response.headers[:cache_control].split(/[, ]+/).to_set

  origin_cc_directives.delete 'must-revalidate' # as Akamai does no pass it on
  return origin_cc_directives, akamai_cc_directives
end

def cc_directives(origin_response, akamai_response)
  origin_cc, akamai_cc = clean_cc_directives(origin_response, akamai_response)
  check_cc(origin_cc, akamai_cc) unless (origin_cc & ['no-store', 'no-cache']).empty?
  return origin_cc, akamai_cc
end

def check_and_clean_header(origin_cc, akamai_cc, expected)
  unless akamai_cc.include? expected
    fail "Akamai was expected to, but did not, add 'Cache-Control: #{expected}' as Origin sent 'no-store' or 'no-cache'"
  end
  akamai_cc.delete expected unless origin_cc.include? expected
  akamai_cc
end

def check_cc(origin_cc, akamai_cc)
  ['no-store', 'max-age=0'].each do |expected|
    akamai_cc = check_and_clean_header(origin_cc, akamai_cc, expected)
  end
  return origin_cc, akamai_cc
end

def max_age(cc_directives)
  cc_directives.detect { |d| d.start_with? 'max-age=' }
end

def max_age_to_num(max_age)
  max_age.split('=').last.to_i
end

def clean_max_age(cc_directives)
  max_age = max_age(cc_directives)
  cc_directives.delete max_age if max_age
  return max_age_to_num(max_age), cc_directives
end

def check_max_age(origin_cc_directives, akamai_cc_directives)
  origin_max_age, origin_cc_directives = clean_max_age(origin_cc_directives)
  akamai_max_age, akamai_cc_directives = clean_max_age(akamai_cc_directives)
  if akamai_max_age > origin_max_age
    fail "Akamai sent a max-age greater than Origin's: #{akamai_max_age} > #{origin_max_age}"
  end
  return origin_cc_directives, akamai_cc_directives
end

def validate_akamai_dropped(origin_cc, akamai_cc)
  dropped = origin_cc - akamai_cc
  unless dropped.empty?
    fail "Origin sent 'Cache-Control: #{dropped.to_a.join ','}', but Akamai did not."
  end
end

def validate_akamai_added(origin_cc, akamai_cc)
  added = akamai_cc - origin_cc
  unless added.empty?
    fail "Akamai unexpectedly added 'Cache-Control: #{added.to_a.join ','}'"
  end
end

def check_cache_control(origin_response, akamai_response, headers)
  if [:both, :cache_control].include? headers
    origin_cc, akamai_cc = cc_directives(origin_response, akamai_response)
    origin_cc, akamai_cc = check_max_age(origin_cc, akamai_cc)
    validate_akamai_dropped(origin_cc, akamai_cc)
    validate_akamai_added(origin_cc, akamai_cc)
  end
end

def check_expires(origin_response, akamai_response, headers)
  if [:both, :expires].include? headers
    origin_expires, akamai_expires = expires(origin_response, akamai_response)
    validate_expires(origin_expires, akamai_expires)
  end
end

def validate_expires(origin, akamai)
  unless akamai == origin
    fail "Origin sent 'Expires: #{origin}' but Akamai sent 'Expires: #{akamai}'"
  end
end

def expires(origin_response, akamai_response)
  return origin_expires(origin_response), Time.httpdate(akamai_response.headers[:expires])
end

def origin_expires(origin_response)
  expires = origin_response.headers[:expires]
  expires == '0' ? Time.httpdate(origin_response.headers[:date]) : DateTime.parse(expires)
end

RSpec::Matchers.define :honour_origin_cache_headers do |origin, headers|
  header_options = [:cache_control, :expires, :both]
  headers ||= :both
  fail("Headers must be one of: #{header_options}") unless header_options.include? headers

  match do |url|
    akamai_response = responsify url
    origin_response = origin_response(URI.parse(akamai_response.args[:url]), origin)
    check_cache_control(origin_response, akamai_response, headers)
    check_expires(origin_response, akamai_response, headers)
    true
  end
end

RSpec::Matchers.define :be_forwarded_to_index do |channel|
  match do |url|
    response = RestClient.get(url, akamai_debug_headers)

    session_info = response.raw_headers['x-akamai-session-info']
    if session_info.nil?
      fail("x-akamai-session-info not found in the headers '#{response.raw_headers}'")
    end
    outcome_attribute = session_info.find { |header| header.include? 'AKA_PM_FWD_URL' }
    if outcome_attribute.nil?
      fail("AKA_PM_FWD_URL not found in the x-akamai-session-info header '#{session_info}'")
    end
    outcome_url = outcome_attribute.split('value=')[1]
    response.code == 200 && outcome_url == "#{channel}"
  end
end

def request_cache_miss(url)
  url += url.include?('?') ? '&' : '?'
  url += SecureRandom.hex
  RestClient.get(url, akamai_debug_headers)
end

RSpec::Matchers.define :be_tier_distributed do
  match do |url|
    response = request_cache_miss(url)
    tiered = !response.headers[:x_cache_remote].nil?
    fail('No X-Cache-Remote header in response') unless tiered
    response.code == 200 && tiered
  end
end

RSpec::Matchers.define :be_gzipped do
  match do |response_or_url|
    response = responsify response_or_url
    response.headers[:content_encoding] == 'gzip'
  end
end

RSpec::Matchers.define :set_cookie do |cookie|
  match do |response_or_url|
    response = responsify response_or_url
    unless response.cookies[cookie]
      fail("Cookie #{cookie} not in #{response.cookies}")
    end
    response.cookies[cookie]
  end
end

RSpec::Matchers.define :check_cp_code do |cpcode|
  match do |response_or_url|
    response = responsify response_or_url
    unless response.headers[:x_cache_key].include?(cpcode)
      fail("CP Code #{cpcode} not in #{response.headers[:x_cache_key]}")
    end
    response.code == 200 && response.headers[:x_cache_key].include?(cpcode)
  end
end
