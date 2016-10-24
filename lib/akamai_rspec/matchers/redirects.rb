require 'rspec'
require 'uri'

module AkamaiRSpec
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

    def redirect(url, expected_location, expected_response_code)
      response = AkamaiRSpec::Request.get(url)
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

RSpec::Matchers.define :be_permanently_redirected_to do |expected_location|
  include AkamaiRSpec::ChainableRedirect
  match do |url|
    redirect(url, expected_location, 301)
  end
end

RSpec::Matchers.define :be_temporarily_redirected_to do |expected_location|
  include AkamaiRSpec::ChainableRedirect
  match do |url|
    redirect(url, expected_location, 302)
  end
end

RSpec::Matchers.define :redirect_http_to_https do |with: 301|
  include AkamaiRSpec::ChainableRedirect
  match do |url|
    secure, url = with_and_without_tls(url)
    redirect(url, secure, with)
  end
end

RSpec::Matchers.define :redirect_https_to_http do |with: 301|
  include AkamaiRSpec::ChainableRedirect
  match do |url|
    secure, url = with_and_without_tls(url)
    redirect(secure, url, with)
  end
end

RSpec::Matchers.define :redirect_to_add_trailing_slash do |with: 301|
  include AkamaiRSpec::ChainableRedirect
  match do |url|
    without_trailing_slash = url.gsub(/\/+$/, '')
    with_trailing_slash = without_trailing_slash + "/"
    redirect(without_trailing_slash, with_trailing_slash, with)
  end
end

RSpec::Matchers.define :be_temporarily_redirected_with_trailing_slash do
  include AkamaiRSpec::ChainableRedirect
  match do |url|
    redirect(url, url + '/', 302)
  end
end
