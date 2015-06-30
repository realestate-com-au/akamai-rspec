require 'rspec'
require_relative 'common'

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
