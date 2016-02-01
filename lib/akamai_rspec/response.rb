module AkamaiRSpec
  class Response
    def initialize(response)
      @response = response
    end

    def headers
      headers = Hash[@response.to_hash.map{ |k, v| [k.gsub(/-/,'_').downcase.to_sym, v] }]
      headers.each do |k, v|
        if v.is_a?(Array) && v.size == 1
          headers[k] = v.first
        end
      end

      headers
    end

    def code
      @response.code.to_i
    end

    def cookies
      cookie_header = headers.to_hash[:set_cookie]
      if cookie_header
        if cookie_header.is_a?(Array)
          cookies_string = cookie_header.collect do |header_value|
            header_value.split('; ')
          end
          cookies_string.flatten!
          cookies_array = cookies_string.collect { |c| c.split('=') }
        else
          cookies_array = [cookie_header.split('=')]
        end

        Hash[cookies_array]
      else
        {}
      end
    end

    def method_missing(method, *args)
      @response.send(method, *args)
    end
  end
end
