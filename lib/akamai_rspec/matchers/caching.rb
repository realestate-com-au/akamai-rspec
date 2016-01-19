require 'rspec'
require 'securerandom'

RSpec::Matchers.define :be_cacheable do
  match do |url|
    response = AkamaiRSpec::Request.get url
    x_check_cacheable(response, 'YES')
    response.code == 200
  end
end

module RSpec::Matchers
  alias_method :be_cachable, :be_cacheable
end

RSpec::Matchers.define :have_no_cache_set do
  match do |url|
    response = AkamaiRSpec::Request.get url
    cache_control = response.headers[:cache_control]
    fail('Cache-Control has been set') unless cache_control == 'no-cache'
    true
  end
end

RSpec::Matchers.define :not_be_cached do
  match do |url|
    response = AkamaiRSpec::Request.get url
    x_check_cacheable(response, 'NO')
    response = AkamaiRSpec::Request.get url  # again to prevent spurious cache miss

    not_cached = response.headers[:x_cache] =~ /TCP(\w+)?_MISS/
    if not_cached
      true
    else
      fail("x_cache header does not indicate an origin hit: '#{response.headers[:x_cache]}'")
    end
  end
end

RSpec::Matchers.define :be_tier_distributed do
  match do |url|
    response = AkamaiRSpec::Request.get_cache_miss(url)
    tiered = !response.headers[:x_cache_remote].nil?
    fail('No X-Cache-Remote header in response') unless tiered
    response.code == 200 && tiered
  end
end

def x_check_cacheable(response, should_be_cacheable)
  x_check_cacheable = response.headers[:x_check_cacheable]
  fail('No X-Check-Cacheable header?') if x_check_cacheable.nil?
  unless (x_check_cacheable == should_be_cacheable)
    fail("X-Check-Cacheable header is: #{x_check_cacheable} expected #{should_be_cacheable}")
  end
end
