require 'rspec'
require 'set'
require 'time'
require 'uri'

RSpec::Matchers.define :honour_origin_cache_headers do |origin, headers|
  header_options = [:cache_control, :expires, :both]
  headers ||= :both
  fail("Headers must be one of: #{header_options}") unless header_options.include? headers

  match do |url|
    akamai_response = AkamaiRSpec::Request.get url
    origin_response = origin_response(origin)
    check_cache_control(origin_response, akamai_response, headers)
    check_expires(origin_response, akamai_response, headers)
    true
  end
end

def fix_date_header(origin_response)
  origin_response.headers[:date] ||= Time.now.httpdate
  origin_response
end

def origin_response(origin)
  fix_date_header(RestClient::Request.execute(method: :get, url: origin, verify_ssl: false))
end

def clean_cc_directives(origin_response, akamai_response)
  origin_cc_directives = origin_response.headers[:cache_control].split(/[, ]+/).to_set
  akamai_cc_directives = akamai_response.headers[:cache_control].split(/[, ]+/).to_set

  origin_cc_directives.delete 'must-revalidate' # as Akamai does no pass it on
  return origin_cc_directives, akamai_cc_directives
end

def cc_directives(origin_response, akamai_response)
  origin_cc, akamai_cc = clean_cc_directives(origin_response, akamai_response)
  check_cc(origin_cc, akamai_cc) unless (origin_cc & ['no-store', 'no-cache']).empty?
  return origin_cc, akamai_cc
end

def check_and_clean_header(origin_cc, akamai_cc, expected)
  unless akamai_cc.include? expected
    fail "Akamai was expected to, but did not, add 'Cache-Control: #{expected}' as Origin sent 'no-store' or 'no-cache'"
  end
  akamai_cc.delete expected unless origin_cc.include? expected
  akamai_cc
end

def check_cc(origin_cc, akamai_cc)
  ['no-store', 'max-age=0'].each do |expected|
    akamai_cc = check_and_clean_header(origin_cc, akamai_cc, expected)
  end
  return origin_cc, akamai_cc
end

def max_age(cc_directives)
  cc_directives.detect { |d| d.start_with? 'max-age=' }
end

def max_age_to_num(max_age)
  max_age.split('=').last.to_i
end

def clean_max_age(cc_directives)
  max_age = max_age(cc_directives)
  cc_directives.delete max_age if max_age
  return max_age_to_num(max_age), cc_directives
end

def check_max_age(origin_cc_directives, akamai_cc_directives)
  origin_max_age, origin_cc_directives = clean_max_age(origin_cc_directives)
  akamai_max_age, akamai_cc_directives = clean_max_age(akamai_cc_directives)
  if akamai_max_age > origin_max_age
    fail "Akamai sent a max-age greater than Origin's: #{akamai_max_age} > #{origin_max_age}"
  end
  return origin_cc_directives, akamai_cc_directives
end

def validate_akamai_dropped(origin_cc, akamai_cc)
  dropped = origin_cc - akamai_cc
  unless dropped.empty?
    fail "Origin sent 'Cache-Control: #{dropped.to_a.join ','}', but Akamai did not."
  end
end

def validate_akamai_added(origin_cc, akamai_cc)
  added = akamai_cc - origin_cc
  unless added.empty?
    fail "Akamai unexpectedly added 'Cache-Control: #{added.to_a.join ','}'"
  end
end

def check_cache_control(origin_response, akamai_response, headers)
  if [:both, :cache_control].include? headers
    origin_cc, akamai_cc = cc_directives(origin_response, akamai_response)
    origin_cc, akamai_cc = check_max_age(origin_cc, akamai_cc)
    validate_akamai_dropped(origin_cc, akamai_cc)
    validate_akamai_added(origin_cc, akamai_cc)
  end
end

def check_expires(origin_response, akamai_response, headers)
  if [:both, :expires].include? headers
    origin_expires, akamai_expires = expires(origin_response, akamai_response)
    validate_expires(origin_expires, akamai_expires)
  end
end

def validate_expires(origin, akamai)
  unless akamai.to_i == origin.to_i
    fail "Origin sent 'Expires: #{origin}' but Akamai sent 'Expires: #{akamai}'"
  end
end

def expires(origin_response, akamai_response)
  return origin_expires(origin_response), Time.httpdate(akamai_response.headers[:expires])
end

def origin_expires(origin_response)
  expires = origin_response.headers[:expires]
  expires == '0' ? Time.httpdate(origin_response.headers[:date]) : Time.httpdate(expires)
end
