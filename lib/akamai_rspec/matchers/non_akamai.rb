require 'rspec'
require 'socket'
require 'openssl'
require 'uri'

module AkamaiRSpec
  module Matchers
    define :be_successful do |response_codes=(200..299)|
      match do |url|
        response = AkamaiRSpec::Request.get url
        fail("Response #{response} was not successful for #{url}") unless response_codes === response.code
        true
      end
    end

    define :respond_with_headers do |headers|
      match do |url|
        @response = AkamaiRSpec::Request.get url
        headers.each do |k, v|
          fail "Expected header #{k} to be #{v}, got #{@response.headers[k]}" unless @response.headers[k] == v
        end
        true
      end
    end

    define :be_verifiably_secure do (verify = OpenSSL::SSL::VERIFY_PEER)
      match do |url|
        return false if URI(url).scheme == "http"
        url = "https://#{url}" unless URI(url).scheme
        begin
          # Avoid AkamaiRspec::Request as it turns off SSL checking
          @response = RestClient::Request.execute(method: :get, url: url, verify_ssl: verify)
          return true
        rescue => e
          @error = e
          return false
        end
      end

      failure_message do |url|
        "got error #{@error} fetching #{@response}"
      end
    end

    define :be_gzipped do
      match do |url|
        @response = AkamaiRSpec::Request.get_decode url
        @response.headers[:content_encoding] == 'gzip'
      end
      failure_message do |url|
        "Expected #{url} to be gzipped (got #{@response})"
      end

    end

    define :have_cookie do |cookie, value=nil|
      match do |response_or_url|
        response = AkamaiRSpec::Request.get response_or_url
        unless response.cookies[cookie]
          fail("Cookie #{cookie} not in #{response.cookies}")
        end
        if value && response.cookies[cookie] != value
          fail("Cookie #{cookie} was set to #{response.cookies[cookie]}, expected #{value}")
        end
        !!response.cookies[cookie]
      end
    end

    define :be_forbidden do
      match do |url|
        response = AkamaiRSpec::Request.get url
        fail("Response #{response} was not forbidden") unless response.code == 403
        true
      end
    end
  end
end
