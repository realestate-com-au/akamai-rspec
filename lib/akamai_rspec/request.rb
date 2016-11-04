require 'rest-client'
require 'forwardable'

module AkamaiRSpec
  class Request
    extend Forwardable

    class << self
      attr_accessor :stg_domain, :prod_domain, :network
    end
    self.network = 'prod'

    def self.get(url, headers={})
      new.get(url, headers.merge(debug_headers))
    end

    def self.get_without_debug_headers(url, headers={})
      new.get(url, headers)
    end

    def self.get_cache_miss(url)
      url += url.include?('?') ? '&' : '?'
      url += SecureRandom.hex
      get(url)
    end

    def self.get_decode(url)
      response = new.get(url, debug_headers.merge({'Accept-Encoding' => 'gzip'}))
      RestClient::Request.decode(response.headers[:content_encoding], response.body)
      response
    end

    def self.debug_headers
      {
        pragma: [
          'akamai-x-cache-on',
          'akamai-x-cache-remote-on',
          'akamai-x-check-cacheable',
          'akamai-x-get-cache-key',
          'akamai-x-get-extracted-values',
          'akamai-x-get-nonces',
          'akamai-x-get-ssl-client-session-id',
          'akamai-x-get-true-cache-key',
          'akamai-x-serial-no'
        ].join(", ")
      }
    end

    def initialize
      @domain = case self.class.network.downcase
      when 'staging'
        self.class.stg_domain or raise ArgumentError.new(
          "You must set the staging domain: AkamaiRSpec::Request.stg_domain = 'www.example.com.edgesuite.net'"
        )
      else
        self.class.prod_domain or raise ArgumentError.new(
          "You must set the prod domain: AkamaiRSpec::Request.prod_domain = 'www.example.com.edgesuite.net'"
        )
      end

      @rest_client = RestClient::Request.new(
        method: :get,
        url: 'fakeurl.com',
        verify_ssl: false
      )
    end

    delegate [:parse_url_with_auth, :stringify_headers] => :@rest_client

    def get(url, headers = {})
      # DO NOT USE url.is_a? here - some versions of
      # the JSON gem monkey patch String which causes it to match.

      if url.class.ancestors.include? RestClient::Response
        return AkamaiRSpec::Response.new(url)
      end

      if url.class.ancestors.include? AkamaiRSpec::Response
        return url
      end

      uri = parse_url_with_auth(url)
      req = build_request(uri, stringify_headers(headers))

      req['Host'] = uri.hostname
      uri.hostname = @domain

      net = Net::HTTP.new(uri.hostname, uri.port)
      if uri.scheme == 'https'
        net.use_ssl = true
        net.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
      response = net.request(req, nil)

      AkamaiRSpec::Response.new(response)
    end

    def build_request(uri, headers)
      req = Net::HTTP::Get.new(uri)
      headers.each { |key, value| req[key] = value }
      req
    end
  end
end
