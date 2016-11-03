
module AkamaiRSpec
  module Helpers
    module ChainableRedirect
      def self.included(other)
        other.chain :then do |matcher|
          (@and_then_matchers ||= []).push(matcher)
        end
      end

      def with_and_without_tls(url)
        url = "http://#{url}" unless URI(url).scheme
        url = url.gsub(/^https:/i, 'http:')
        secure = url.gsub(/^http:/i, 'https:')
        return secure, url
      end

      def redirect(url, expected_location, expected_response_code, headers)
        response = AkamaiRSpec::Request.get(url, headers)
        fail "Response was #{response.inspect}, expected code #{expected_response_code}" unless response.code == expected_response_code
        unless expected_location === response.headers[:location]
          fail "redirect location was #{response.headers[:location]} (expected #{expected_location})"
        end

        if @and_then_matchers
          begin
            @and_then_matchers.each {|matcher| expect(response.headers[:location]).to matcher}
          rescue Exception => e
            @and_then_error = e
            return false
          end
        end

        true
      end

      def failure_message
        @and_then_error || super
      end
    end
  end
end
