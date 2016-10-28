
module AkamaiRSpec
  module Helpers
    module CacheHeaders
      X_CACHE_HEADERS = [:x_true_cache_key, :x_cache_key]

      def x_cache_headers
        X_CACHE_HEADERS
      end

      def cache_headers
        x_cache_headers.map {|key| @response.headers[key] }
      end

    end
  end
end
