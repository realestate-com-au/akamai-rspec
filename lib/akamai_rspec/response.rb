module AkamaiRSpec
  class Response
    def initialize(response)
      @response = response
    end

    def headers
      headers = Hash[@response.to_hash.map{ |k, v| [k.gsub(/-/,'_').downcase.to_sym, v] }]
      headers.default = ""
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
      cookies = {}

      [headers[:set_cookie]].flatten.each do |cookie|
        name, value = cookie.split(/=/, 2)
        cookies[name] = value
      end
      cookies
    end

    def method_missing(method, *args)
      @response.send(method, *args)
    end

    def to_s
      case code
      when 0..99
        "Invalid status code #{code}"
      when 100..199
        "Informational: #{code}"
      when 200..299
        "Success: #{code}"
      when 300..399
        "Redirect #{code} to #{headers[:location]}"
      when 400..499
        "Client error #{code}"
      when 500..599
        "Server error #{code}"
      else
        "Unknown status code #{code}"
      end
    end
  end
end
