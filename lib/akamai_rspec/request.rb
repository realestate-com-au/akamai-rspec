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
      AkamaiHeaders.akamai_debug_headers
    end

    def self.http_get(url, options, cookies = {})
      get_with_debug_headers(http_url(url), options, cookies)
    end

    def self.https_get(url, options, cookies = {})
      get_with_debug_headers(https_url(url), options, cookies)
    end

    def self.get_with_debug_headers(url, options, cookies = {})
      headers = options.merge(options).merge(cookies)
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
          RestClient.get(maybe_a_url, options)
        rescue RestClient::RequestFailed => exception
          # Return the original request
          exception.response
        end
      end
    end

    def self.request_cache_miss(url)
      url += url.include?('?') ? '&' : '?'
      url += SecureRandom.hex
      RestClient.get(url, options)
    end
  end
end

module AkamaiRSpec
  class Request
    def self.stg_domain=(domain)
      @@akamai_stg_domain = domain
    end

    def self.prod_domain=(domain)
      @@akamai_prod_domain = domain
    end

    def initialize(env)
      @env = env
      @domain = case env.downcase
                when 'staging'
                  @@akamai_stg_domain
                else
                  @@akamai_prod_domain
                end
    end

    def get(url)
      uri = parse_url(url)

      req = build_request(uri, headers)

      req['Host'] = uri.hostname
      uri.hostname = @domain

      Net::HTTP.start(uri.hostname, uri.port) do |http|
        http.request(req, nil) { |http_response| http_response }
      end
    end

    def parse_url(url)
      uri = URI.parse(url)
      if uri.hostname.nil?
        raise URI::InvalidURIError.new("bad URI(no host provided): #{url}")
      end

      uri
    end

    def headers
      AkamaiHeaders.akamai_debug_headers.inject({}) do |result, (key, value)|
        key = key.to_s.capitalize
        result[key] = value.to_s
        result
      end
    end

    def build_request(uri, headers)
      req = Net::HTTP::Get.new(uri)
      headers.each { |key, value| req.send(:[]=, key, value) }

      req
    end
  end
end
