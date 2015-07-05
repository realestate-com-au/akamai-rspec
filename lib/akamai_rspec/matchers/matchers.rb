require 'securerandom'
require 'rspec'
require_relative 'redirects'
require_relative 'caching'
require_relative 'non_akamai'
require_relative 'honour_origin_headers'
include AkamaiHeaders

RSpec::Matchers.define :x_cache_key_contains do |contents|
  match do |url|
    response = RestClient::Request.responsify url
    fail 'No X-Cache-Key header' if response.headers[:x_cache_key].nil?
    unless response.headers[:x_cache_key].include?(contents)
      fail("x_cache_key has value '#{response.headers[:x_cache_key]}' which doesn't include '#{contents}'")
    end
    response.code == 200 && response.headers[:x_cache_key].include?(contents)
  end
end

module RSpec::Matchers
  alias_method :be_served_from_origin, :x_cache_key_contains
  alias_method :have_cp_code, :x_cache_key_contains
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
