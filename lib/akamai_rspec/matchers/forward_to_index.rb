
module AkamaiRSpec
  module Matchers
    define :be_forwarded_to_path do |channel|
      match do |url|
        response = Request.get(url)
        session_info = response.headers[:x_akamai_session_info]
        if session_info.nil?
          fail("x-akamai-session-info not found in the headers '#{response.headers}'")
        end
        outcome_attribute = session_info.find { |header| header.include? 'AKA_PM_FWD_URL' }
        if outcome_attribute.nil?
          fail("AKA_PM_FWD_URL not found in the x-akamai-session-info header '#{session_info}'")
        end
        outcome_url = outcome_attribute.split('value=')[1]
        response.code == 200 && outcome_url == channel
      end
    end

    alias_method :be_forwarded_to_index, :be_forwarded_to_path
  end
end
