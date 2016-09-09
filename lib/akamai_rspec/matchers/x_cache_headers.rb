require 'rspec'

module AkamaiRSpec
  module Helpers
    X_CACHE_HEADERS = [:x_true_cache_key, :x_cache_key]

    def x_cache_headers
      X_CACHE_HEADERS
    end

    def served_from_origin?(response, contents)
      response.headers.any? { |key, value|
        x_cache_headers.include?(key) && value =~ /\/#{contents}\// } && response.code == 200
    end
  end
end

RSpec::Matchers.define :be_served_from_origin do |contents|
  include AkamaiRSpec::Helpers
  match do |url|
    response = AkamaiRSpec::Request.get url
    served_from_origin?(response, contents)
  end
end

RSpec::Matchers.define :response_be_served_from_origin do |contents|
  include AkamaiRSpec::Helpers
  match do |response|
    served_from_origin?(response, contents)
  end
end

RSpec::Matchers.define :have_cp_code do |contents|
  include AkamaiRSpec::Helpers
  match do |url|
    response = AkamaiRSpec::Request.get url
    response.headers.any? { |key, value| x_cache_headers.include?(key) && value == contents } && \
      response.code == 200
  end
end
