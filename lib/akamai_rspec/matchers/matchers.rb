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
    return true if x_cache_headers_from_origin(response, contents)
    missing_x_cache_error(response, contents)
    expect(response).to be_successful
    has_x_cache_headers(response)
  end
end

RSpec::Matchers.define :have_cp_code do |contents|
  match do |url|
    response = RestClient::Request.responsify url
    has_x_cache_headers(response)
    return true if x_cache_headers_contain(response, contents)
    missing_x_cache_error(response, contents)
    expect(response).to be_successful
  end
end

def has_x_cache_headers(response)
  unless X_CACHE_HEADERS.inject(false) { |bool, header| bool || response.headers.include?(header) }
    fail "Response does not contain the debug headers"
  end
end

def x_cache_headers_contain(response, contents)
  X_CACHE_HEADERS.each do |key|
    return true if response.headers[key] && response.headers[key].include?(contents)
  end
  false
end


def x_cache_headers_from_origin(response, contents)
  X_CACHE_HEADERS.each do |key|
    header = response.headers[key]
    return true if (header && header =~ /\/#{contents}\//)
  end
  return false
end

def missing_x_cache_error(response, contents)
  X_CACHE_HEADERS.each do |key|
    if (response.headers[key])
      fail("#{key} has value '#{response.headers[key]}' which doesn't match '#{contents}'")
    end
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
