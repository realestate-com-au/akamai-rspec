require 'rspec'
require 'akamai_rspec/helpers/cache_headers'

module AkamaiRSpec
  module Matchers
    define :be_served_from_origin do |contents|
      include AkamaiRSpec::Helpers::CacheHeaders

      match do |url|
        @response = AkamaiRSpec::Request.get url
        cache_headers.any? {|h| h.split("/").include? contents}
      end

      failure_message do |actual|
        "expected \"#{actual}\" to be served from origin \"#{contents}\"; got #{@response} and the cache headers indicated '#{cache_headers.inspect}'"
      end
    end

    define :have_cp_code do |contents|
      include AkamaiRSpec::Helpers::CacheHeaders
      match do |url|
        @response = AkamaiRSpec::Request.get url
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
  end
end
