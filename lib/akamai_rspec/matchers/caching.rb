require 'rspec'
require 'securerandom'
require 'akamai_rspec/akamai_headers'

RSpec::Matchers.define :be_cacheable do |opts={request_count: 10}|
  match do |url|
    responses = [1..opts[:request_count]].map { AkamaiRSpec::Request.get_with_debug_headers url }

    responses.any? do |response|
      fail("Error fetching #{url}: #{response}") if response.code != 200
      (
        (response.headers[:x_cache] =~ /TCP(\w+)?_HIT/) and not
        (response.headers[:x_cache] =~ /TCP_REFRESH/)
      )
    end
  end
end

module RSpec::Matchers
  alias_method :be_cachable, :be_cacheable
  alias_method :be_cached, :be_cacheable
  define_negated_matcher :not_be_cached, :be_cached
end

RSpec::Matchers.define :have_no_cache_set do
  match do |url|
    response = AkamaiRSpec::Request.get url
    cache_control = response.headers[:cache_control]
    return cache_control == 'no-cache'
  end
end


RSpec::Matchers.define :be_tier_distributed do
  match do |url|
    response = AkamaiRSpec::Request.get_cache_miss(url)
    @tiered = !response.headers[:x_cache_remote].nil?
    response.code == 200 && @tiered
  end
  description do
    "be tier distributed (as indicated by the presence of an X-Cache-Remote header in response)"
  end
end

