require 'securerandom'
require 'set'
require 'socket'
require 'time'
require 'openssl'
require 'uri'
require 'rspec'
include AkamaiHeaders

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
  origin_cc, akamai_cc = clean_cc_directives(origin_response, akamai_response)
  check_cc(origin_cc, akamai_cc) unless (origin_cc & ['no-store', 'no-cache']).empty?
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

def check_cache_control(origin_response, akamai_response)
  if [:both, :cache_control].include? headers
    origin_cc, akamai_cc = check_max_age(cc_directives(origin_response, akamai_response))
    akamai_dropped = origin_cc - akamai_cc
    akamai_added = akamai_cc - origin_cc

    unless akamai_dropped.empty?
      fail "Origin sent 'Cache-Control: #{akamai_dropped.to_a.join ','}', but Akamai did not."
    end

    unless akamai_added.empty?
      fail "Akamai unexpectedly added 'Cache-Control: #{akamai_added.to_a.join ','}'"
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
    # Must interpret invalid dates as already expired
    Time.httpdate(origin_response.headers[:date])
  else
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
    check_cache_control(origin_response, akamai_response)
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
