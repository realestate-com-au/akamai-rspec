require 'rspec'
require 'securerandom'
require 'akamai_rspec/akamai_headers'
require 'akamai_rspec/request'

RSpec::Matchers.define :be_cacheable do |request_count: 4, headers: {}, allow_refresh: false|
  match do |url|
    @responses = [1..request_count].map {
      AkamaiRSpec::Request.new.get url, AkamaiHeaders.akamai_debug_headers.merge(headers)
    }

    @responses.any? do |response|
      fail("Error fetching #{url}: #{response}") if response.code != 200
      return allow_refresh if refresh_hit? response
      hit?(response)
    end
  end

  def refresh_hit?(response)
    response.headers[:x_cache] =~ /TCP_REFRESH/
  end

  def hit?(response)
    response.headers[:x_cache] =~ /TCP(\w+)?_HIT/
  end

  def suggest_allow_refresh?(allow_refresh)
    !allow_refresh &&
    !@responses.any?(&method(:hit?)) &&
    @responses.any?(&method(:refresh_hit?))
  end

  description do
    msg = "to be cacheable (got #{cache_headers} from #{@responses.length} requests)"
    msg += ". Try setting 'allow_refresh: true'." if suggest_allow_refresh?(allow_refresh)
    msg
  end

  def cache_headers
    @responses.map {|response| response.headers[:x_cache] }
  end
end

module RSpec::Matchers
  alias_method :be_cachable, :be_cacheable
  alias_method :be_cached, :be_cacheable
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
    @tiered = !response.headers[:x_cache_remote].empty?
    response.code == 200 && @tiered
  end

  description do
    "be tier distributed (as indicated by the presence of an X-Cache-Remote header in response)"
  end
end

