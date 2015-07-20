require 'securerandom'
require 'rspec'
require_relative 'redirects'
require_relative 'caching'
require_relative 'non_akamai'
require_relative 'honour_origin_headers'
include AkamaiHeaders

X_CACHE_HEADERS = [:x_true_cache_key, :x_cache_key]

RSpec::Matchers.define :be_served_from_origin do |contents|
  match do |url|
    response = RestClient::Request.responsify url
	X_CACHE_HEADERS.each do |key|
      header = response.headers[key]
      return true if header && response.headers[key] =~ /\/#{contents}\//
    end
    X_CACHE_HEADERS.each do |key|
      if (response.headers[key])
        fail("#{key} has value '#{response.headers[key]}' which doesn't match '#{contents}'")
      end
    end
    unless response.code == 200
	  fail "Response code was #{response.code}, expected 200"
	end
    unless X_CACHE_HEADERS.inject(false) { |bool, header| bool || response.headers.include?(key) }
      fail "Response does not contain the debug headers"
    end
  end
end

RSpec::Matchers.define :have_cp_code do |contents|
  match do |url|
    response = RestClient::Request.responsify url
    fail 'No X-Cache-Key header' if response.headers[:x_cache_key].nil?
    unless response.headers[:x_cache_key].include?(contents)
      fail("x_cache_key has value '#{response.headers[:x_cache_key]}' which doesn't include '#{contents}'")
    end
    response.code == 200
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
