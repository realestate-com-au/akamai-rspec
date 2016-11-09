require 'rspec'
require 'securerandom'
require 'akamai_rspec/request'

module AkamaiRSpec
  module Matchers
    define :be_cacheable do |request_count: 4, only_same_server: true, headers: {}, allow_refresh: false|
      match do |url|
        @responses = []
        fail("URL must be a string") unless url.is_a? String

        if only_same_server
          while response = AkamaiRSpec::Request.get(url, headers) do
            responses_from_same_server = cache_servers.count(cache_server response.headers[:x_cache])
            @responses.push response
            break if responses_from_same_server >= request_count
          end
        else
          @responses = (1..request_count).map {
            AkamaiRSpec::Request.get url, headers
          }
        end

        @responses.any? do |response|
          if refresh_hit? response
            allow_refresh
          else
            hit?(response)
          end
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

      def cache_servers
        cache_headers.map &method(:cache_server)
      end

      def cache_server(header)
        header.split(" ")[2]
      end
    end

    alias_method :be_cachable, :be_cacheable
    alias_method :be_cached, :be_cacheable

    define :have_no_cache_set do
      match do |url|
        response = AkamaiRSpec::Request.get url
        cache_control = response.headers[:cache_control]
        return cache_control == 'no-cache'
      end
    end

    define :be_tier_distributed do
      match do |url|
        response = AkamaiRSpec::Request.get_cache_miss(url)
        @tiered = !response.headers[:x_cache_remote].empty?
        response.code == 200 && @tiered
      end

      description do
        "be tier distributed (as indicated by the presence of an X-Cache-Remote header in response)"
      end
    end
  end
end
