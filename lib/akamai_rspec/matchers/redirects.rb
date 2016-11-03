require 'rspec'
require 'uri'
require 'akamai_rspec/helpers/chainable_redirect'

module AkamaiRSpec
  module Matchers
    define :be_permanently_redirected_to do |expected_location, headers: {}|
      include AkamaiRSpec::Helpers::ChainableRedirect
      match do |url|
        redirect(url, expected_location, 301, headers)
      end
    end

    define :be_temporarily_redirected_to do |expected_location, headers: {}|
      include AkamaiRSpec::Helpers::ChainableRedirect
      match do |url|
        redirect(url, expected_location, 302, headers)
      end
    end

    define :redirect_http_to_https do |with: 301, headers: {}|
      include AkamaiRSpec::Helpers::ChainableRedirect
      match do |url|
        secure, url = with_and_without_tls(url)
        redirect(url, secure, with, headers)
      end
    end

    define :redirect_https_to_http do |with: 301, headers: {}|
      include AkamaiRSpec::Helpers::ChainableRedirect
      match do |url|
        secure, url = with_and_without_tls(url)
        redirect(secure, url, with, headers)
      end
    end

    define :redirect_to_remove_trailing_slash do |with: 301, headers: {}|
      include AkamaiRSpec::Helpers::ChainableRedirect
      match do |url|
        without_trailing_slash = url.gsub(/\/+$/, '')
        with_trailing_slash = without_trailing_slash + "/"
        redirect(with_trailing_slash, without_trailing_slash, with, headers)
      end
    end

    define :redirect_to_add_trailing_slash do |with: 301, headers: {}|
      include AkamaiRSpec::Helpers::ChainableRedirect
      match do |url|
        without_trailing_slash = url.gsub(/\/+$/, '')
        with_trailing_slash = without_trailing_slash + "/"
        redirect(without_trailing_slash, with_trailing_slash, with, headers)
      end
    end

    define :be_temporarily_redirected_with_trailing_slash do
      include AkamaiRSpec::Helpers::ChainableRedirect
      match do |url|
        puts "be_temporarily_redirected_with_trailing_slash is deprecated and will be removed in 2.0; use redirect_to_add_trailing_slash(with: 302)"
        redirect(url, url + '/', 302, {})
      end
    end
  end
end
