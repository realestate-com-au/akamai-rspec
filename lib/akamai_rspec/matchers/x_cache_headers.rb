require 'rspec'

module AkamaiRSpec
  module CacheHelpers
    X_CACHE_HEADERS = [:x_true_cache_key, :x_cache_key]

    def x_cache_headers
      X_CACHE_HEADERS
    end

    def cache_headers
      x_cache_headers.map {|key| @response.headers[key] }
    end
  end
end

RSpec::Matchers.define :be_served_from_origin do |contents|
  include AkamaiRSpec::CacheHelpers

  match do |url|
    @response = AkamaiRSpec::Request.get_with_debug_headers url
    cache_headers.any? {|h| h.split("/").include? contents}
  end

  failure_message do |actual|
    "expected \"#{actual}\" to be served from origin \"#{contents}\"; got #{@response} and the cache headers indicated '#{cache_headers.inspect}'"
  end
end

RSpec::Matchers.define :have_cp_code do |contents|
  include AkamaiRSpec::CacheHelpers
  match do |url|
    @response = AkamaiRSpec::Request.get_with_debug_headers url
    @response.code == 200 && cache_headers.any? do |value|
      value.to_s.split("/").include? contents
    end
  end

  failure_message do |url|
    headers = {}
    x_cache_headers.each {|h| headers[h] = @response.headers[h] }
    "Expected #{url} to have cp_code #{contents} but responded with #{headers.to_json}"
  end
end
