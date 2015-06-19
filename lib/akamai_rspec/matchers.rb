require 'securerandom'
require 'set'
require 'socket'
require 'time'
require 'openssl'
require 'uri'
require 'rspec'
include AkamaiHeaders

def check_ssl_serial(addr, port, url, serial)
  cert_serial = ssl_cert(addr, port, url).serial.to_s(16).upcase
  fail("Incorrect S/N of: #{cert_serial}") unless cert_serial == serial.upcase
end

def ssl_cert(addr, port, url)
  ssl_client = ssl_client(TCPSocket.new(addr, port), addr, url)

  # We get this after the request as we have layer 7 routing in Akamai
  cert = OpenSSL::X509::Certificate.new(ssl_client.peer_cert)

  ssl_client.sysclose
  cert
end

def ssl_client(tcp_client, addr, url)
  # Going to need a proper request to get around Akamai request verification
  request = "GET #{url} HTTP/1.1\r\n" \
    'User-Agent: Akamai-Regression-Framework\r\n' \
    "Host: #{addr}\r\n" \
  'Accept: */*\r\n'

  ssl_client = OpenSSL::SSL::SSLSocket.new(tcp_client)
  ssl_client.sync_close = true
  ssl_client.connect
  ssl_client.puts(request)
  ssl_client.puts("\r\n")
  ssl_client
end

def responsify(maybe_a_url)
  if maybe_a_url.is_a? RestClient::Response
    maybe_a_url
  else
    RestClient.get(maybe_a_url, akamai_debug_headers)
  end
end

RSpec::Matchers.define :be_permanently_redirected_to do |expected_location|
  match do |url|
    redirect(url, expected_location, 301)
  end
end

RSpec::Matchers.define :be_temporarily_redirected_to do |expected_location|
  match do |url|
    redirect(url, expected_location, 302)
  end
end

RSpec::Matchers.define :be_temporarily_redirected_with_trailing_slash do
  match do |url|
    redirect(url, url + '/', 302)
  end
end

def redirect(url, expected_location, expected_response_code)
  response = RestClient.get(url) { |response, _, _| response }
  fail "response was #{response.code}" unless response.code == expected_response_code
  unless response.headers[:location] == expected_location
    fail "redirect location was #{response.headers[:location]} (expected #{expected_location})"
  end
  true
end

def x_check_cacheable(response, should_be_cacheable)
  x_check_cacheable = response.headers[:x_check_cacheable]
  fail('No X-Check-Cacheable header?') if x_check_cacheable.nil?
  unless (x_check_cacheable == should_be_cacheable)
    fail("X-Check-Cacheable header is: #{x_check_cacheable} expected #{should_be_cacheable}")
  end
end

RSpec::Matchers.define :be_cacheable do
  match do |url|
    response = responsify url
    x_check_cacheable(response, 'YES')
    response.code == 200
  end
end

module RSpec::Matchers
  alias_method :be_cachable, :be_cacheable
end

RSpec::Matchers.define :have_no_cache_control do
  match do |url|
    response = responsify url
    cache_control = response.headers[:cache_control]
    fail('Cache-Control has been set') unless cache_control == 'no-cache'
    true
  end
end

RSpec::Matchers.define :not_be_cached do
  match do |url|
    response = responsify url
    x_check_cacheable(response, 'NO')
    response = responsify response.args[:url]  # again to prevent spurious cache miss

    not_cached = response.headers[:x_cache] =~ /TCP(\w+)?_MISS/
    unless not_cached
      fail("x_cache header does not indicate an origin hit: '#{response.headers[:x_cache]}'")
    end

    response.code == 200 && not_cached
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
  # Sigh. RFC 7231, section 7.1.1.2
  # > An origin server MUST NOT send a Date header field if it does not have
  # > a clock capable of providing a reasonable approximation of the current
  # > instance in Coordinated Universal Time.  An origin server MAY send a
  # > Date header field if the response is in the 1xx (Informational) or 5xx
  # > (Server Error) class of status codes.  An origin server MUST send a
  # > Date header field in all other cases.
  #
  # > A recipient with a clock that receives a response message without a
  # > Date header field MUST record the time it was received and append a
  # > corresponding Date header field to the message's header section if it is
  # > cached or forwarded downstream.
  origin_response.headers[:date] = Time.now.httpdate unless origin_response.headers[:date]
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
  check_cc(clean_cc_directives(origin_response, akamai_response))
end

def check_cc(origin_cc, akamai_cc)
  unless (origin_cc & ['no-store', 'no-cache']).empty?
    %w(no-store max-age=0).each do |expected|
      unless akamai_cc.include? expected
        fail "Akamai was expected to, but did not, add 'Cache-Control: #{expected}' as Origin sent 'no-store' or 'no-cache'"
      end
      akamai_cc.delete expected  unless origin_cc.include? expected
    end
  end
  return origin_cc, akamai_cc
end

def max_age(cc_directives)
  cc_directives.detect { |d| d.start_with? 'max-age=' }
end

def max_age_to_num(max_age)
  max_age.split('=').last.to_i
end

def check_max_age(origin_cc_directives, akamai_cc_directives)
  # If we send a max-age from the origin, Akamai will send a max-age value
  # that counts down from that max-age.
  origin_max_age = max_age(origin_cc_directives)
  akamai_max_age = max_age(akamai_cc_directives)
  if origin_max_age && akamai_max_age
    origin_cc_directives.delete origin_max_age
    akamai_cc_directives.delete akamai_max_age

    if max_age_to_num(akamai_max_age) > max_age_to_num(origin_max_age)
      fail "Akamai sent a max-age greater than Origin's: #{akamai_max_age} > #{origin_max_age}"
    end
  end
  return origin_cc_directives, akamai_cc_directives
end

def check_cache_control(origin_cc_directives, akamai_cc_directives)
  if [:both, :cache_control].include? headers
    origin_sent_akamai_did_not = origin_cc_directives - akamai_cc_directives
    akamai_cc_added = akamai_cc_directives - origin_cc_directives

    unless origin_sent_akamai_did_not.empty?
      fail "Origin sent 'Cache-Control: #{origin_sent_akamai_did_not.to_a.join ','}', but Akamai did not."
    end

    unless akamai_cc_added.empty?
      fail "Akamai unexpectedly added 'Cache-Control: #{akamai_cc_directives.to_a.join ','}'"
    end
  end
end

def check_expires(origin_response, akamai_response)
  if [:both, :expires].include? headers
    akamai_expires = Time.httpdate(akamai_response.headers[:expires])
    origin_expires = origin_expires(origin_response)

    unless akamai_expires == origin_expires
      fail "Origin sent 'Expires: #{origin_response.headers[:expires]}', "\
      "but Akamai sent 'Expires: #{akamai_response.headers[:expires]}'"
    end
  end
end

def origin_expires(origin_response)
  expires = origin_response.headers[:expires]
  if expires == '0'
    # A cache recipient MUST interpret invalid date formats, especially the
    # value "0", as representing a time in the past (i.e., "already
    # expired").
    Time.httpdate(origin_response.headers[:date])
  else
    # Ruby's Time.httpdate _only_ accepts RFC 2616 dates.
    # Using DateTime.parse to be less strict about what we accept.
    DateTime.parse(expires)
  end
end

RSpec::Matchers.define :honour_origin_cache_headers do |origin, headers|
  header_options = [:cache_control, :expires, :both]
  headers ||= :both
  fail("Headers must be one of: #{header_options}") unless header_options.include? headers

  match do |url|
    akamai_response = responsify url
    origin_response = origin_response(URI.parse akamai_response.args[:url], origin)
    check_cache_control(cc_directives(origin_response, akamai_response))
    check_expires(origin_response, akamai_response)
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

RSpec::Matchers.define :be_tier_distributed do
  match do |response_or_url|
    # we need to force a cache miss to see the X-Cache-Remote header
    url = response_or_url
    url = url.args[:url] if url.is_a? RestClient::Response
    url += url.include?('?') ? '&' : '?'
    url += SecureRandom.hex
    response = RestClient.get(url, akamai_debug_headers)

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
