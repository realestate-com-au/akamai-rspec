require 'rest-client'
require_relative 'akamai_headers'

module RestClient
  class Request
    @@akamai_network = 'prod'
    @@akamai_stg_domain = 'overwrite me'
    @@akamai_prod_domain = 'overwrite me'

    def self.domain
      env = @@akamai_network
      case env.downcase
      when 'staging'
        @@akamai_stg_domain
      else
        @@akamai_prod_domain
      end
    end

    def self.akamai_network(env)
      @@akamai_network = env
    end

    def self.stg_domain(domain)
      @@akamai_stg_domain = domain
    end

    def self.prod_domain(domain)
      @@akamai_prod_domain = domain
    end

    def self.http_url(url)
      url = "/#{url}" unless url.start_with?('/')
      "http://#{domain}#{url}"
    end

    def self.https_url(url)
      url = "/#{url}" unless url.start_with?('/')
      "https://#{domain}#{url}"
    end

    # Define the Host header and join the Akamai headers
    def self.options
      akamai_debug_headers
    end

    # Make requests to the right network
    def self.http_get(url, options, cookies = {})
      do_get(url, options, cookies, false)
    end

    def self.https_get(url, options, cookies = {})
      do_get(url, options, cookies, true)
    end

    def self.do_get(url, options, cookies = {}, is_secure)
      if is_secure
        base_url = https_url(url)
      else
        base_url = http_url(url)
      end
      headers = options.merge(akamai_debug_headers).merge(cookies)
      do_get_no_ssl(base_url, headers) { |response, _, _| response }
    end

    def self.do_get_no_ssl(url, additional_headers = {}, &block)
      headers = (options[:headers] || {}).merge(additional_headers)
      RestClient::Request.execute(options.merge(
        method: :get,
        url: url,
        verify_ssl: false,
        headers: headers), &(block || @block))
    end

    def self.responsify(maybe_a_url)
      if maybe_a_url.is_a? RestClient::Response
        maybe_a_url
      else
        RestClient.get(maybe_a_url, akamai_debug_headers)
      end
    end
  end
end
