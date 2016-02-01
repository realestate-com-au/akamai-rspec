require 'rest-client'
require 'forwardable'

module AkamaiRSpec
  class Request
    extend Forwardable

    @@akamai_stg_domain = nil
    @@akamai_prod_domain = nil

    def self.stg_domain=(domain)
      @@akamai_stg_domain = domain
    end

    def self.prod_domain=(domain)
      @@akamai_prod_domain = domain
    end

    def self.network=(env)
      @@env = env
    end

    def self.get(url)
      new.get(url)
    end

    def self.get_with_debug_headers(url)
      new.get(url, AkamaiHeaders.akamai_debug_headers)
    end

    def self.get_cache_miss(url)
      url += url.include?('?') ? '&' : '?'
      url += SecureRandom.hex
      new.get(url, AkamaiHeaders.akamai_debug_headers)
    end

    def self.get_decode(url)
      response = new.get(url, AkamaiHeaders.akamai_debug_headers)
      RestClient::Request.decode(response.headers[:content_encoding], response.body)
      response
    end

    def initialize
      @@env ||= 'prod'

      @domain = case @@env.downcase
                when 'staging'
                  if @@akamai_stg_domain.nil?
                    raise ArgumentError.new(
                      "You must set the prod domain: AkamaiRSpec::Request.stg_domain = 'www.example.com.edgesuite.net'"
                    )
                  end

                  @@akamai_stg_domain
                else
                  if @@akamai_prod_domain.nil?
                    raise ArgumentError.new(
                      "You must set the prod domain: AkamaiRSpec::Request.prod_domain = 'www.example.com.edgesuite.net'"
                    )
                  end

                  @@akamai_prod_domain
                end

      @rest_client = RestClient::Request.new(method: :get,
                                              url: 'fakeurl.com',
                                              verify_ssl: false)
    end

    delegate [:parse_url_with_auth, :stringify_headers] => :@rest_client

    def get(url, headers = {})
      if url.is_a? RestClient::Response
        warn 'This functionality is deprecated and will be removed in the next release'
        return AkamaiRSpec::Response.new(url)
      end

      uri = parse_url_with_auth(url)

      req = build_request(uri, stringify_headers(headers))

      req['Host'] = uri.hostname
      uri.hostname = @domain

      response = Net::HTTP.start(uri.hostname, uri.port) do |http|
        http.request(req, nil) { |http_response| http_response }
      end

      AkamaiRSpec::Response.new(response)
    end

    def build_request(uri, headers)
      req = Net::HTTP::Get.new(uri)
      headers.each { |key, value| req.send(:[]=, key, value) }

      req
    end
  end
end
