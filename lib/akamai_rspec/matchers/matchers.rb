require 'securerandom'
require 'set'
require 'socket'
require 'time'
require 'openssl'
require 'uri'
require 'rspec'
require_relative 'redirects'
require_relative 'caching'
require_relative 'non_akamai'
require_relative 'honour_origin_headers'
include AkamaiHeaders

# TODO make a proper matcher

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

RSpec::Matchers.define :check_cp_code do |cpcode|
  match do |response_or_url|
    response = responsify response_or_url
    unless response.headers[:x_cache_key].include?(cpcode)
      fail("CP Code #{cpcode} not in #{response.headers[:x_cache_key]}")
    end
    response.code == 200 && response.headers[:x_cache_key].include?(cpcode)
  end
end
