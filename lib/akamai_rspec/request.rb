require 'rest-client'
require 'akamai_rspec'

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

    def self.options
      akamai_debug_headers
    end

    def self.http_get(url, options, cookies = {})
      get_with_debug_headers(http_url(url), options, cookies)
    end

    def self.https_get(url, options, cookies = {})
      get_with_debug_headers(https_url(url), options, cookies)
    end

    def self.get_with_debug_headers(url, options, cookies = {})
      headers = options.merge(akamai_debug_headers).merge(cookies)
      do_get_no_verify(url, headers) { |response, _, _| response }
    end

    def self.do_get_no_verify(url, additional_headers = {}, &block)
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
        begin
          RestClient.get(maybe_a_url, akamai_debug_headers)
        rescue RestClient::RequestFailed => exception
          # Return the original request
          exception.response
        end
      end
    end

    def self.request_cache_miss(url)
      url += url.include?('?') ? '&' : '?'
      url += SecureRandom.hex
      RestClient.get(url, akamai_debug_headers)
    end
  end
end
