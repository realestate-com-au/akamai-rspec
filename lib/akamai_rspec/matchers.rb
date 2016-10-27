require 'securerandom'
require 'rspec'

module AkamaiRSpec
  module Matchers
    extend RSpec::Matchers::DSL
  end
end

require_relative 'matchers/redirects'
require_relative 'matchers/caching'
require_relative 'matchers/non_akamai'
require_relative 'matchers/honour_origin_headers'
require_relative 'matchers/x_cache_headers'
require_relative 'matchers/forward_to_index'
