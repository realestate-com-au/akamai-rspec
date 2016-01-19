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

    def method_missing(method, *args)
      @response.send(method, *args)
    end
  end
end
