# akamai-rspec
[![Build Status](https://travis-ci.org/realestate-com-au/akamai-rspec.svg?branch=master)](https://travis-ci.org/realestate-com-au/akamai-rspec)

Use [rspec](http://rspec.info/) to write tests for your [akamai](https://www.akamai.com/) configuration.

## How to use

### Setup

Add 'akamai-rspec' to your Gemfile.

In your `spec-helper.rb`, configure the Akamai domain:
```
AkamaiRSpec::Request.prod_domain = "www.example.com.edgesuite.net"
```
or
```
AkamaiRSpec::Request.network = "staging" # Defaults to prod network
AkamaiRSpec::Request.stg_domain = "www.example.com.edgesuite-staging.net"
```

then include the matchers in your specs:
```
RSpec.configure do |c|
  include AkamaiRSpec::Matchers
end
```

Finally, use the matchers from within your specs.

### Matchers

#### Caching

##### `be_cacheable` AKA `be_cachable`, `be_cached`
```
expect("http://example.org/").to be_cacheable
```
Requests the resource repeatedly and checks that the 'x-cache' header says 'HIT'.

Previous versions used X-Check-Cacheable, but this has some awkward/misleading edge cases.
Sources: [akamai forums](https://community.akamai.com/thread/1987) and [docs (requires login; see p22)]( https://control.akamai.com/dl/customers/other/EDGESERV/ESN-User-Guide.pdf ).

##### `have_no_cache_set`
```
expect(url).to have_no_cache_set
```
Check that the header `cache-control` is set to `no-cache`

##### `be_tier_distributed`
```
expect(url).to be_tier_distributed
```

Forces a cache miss by adding a query string to your URL, then checks
that the 'x_cache_remote' header is set (indicating that the request
was bounced between akamai servers).

##### ``` honour_origin_cache_headers```
```
expect(url).to honour_origin_cache_headers origin
```

Check that akamai and origin cache headers correspond, and takes in to
account expected differences, e.g. akamai removing `must-revalidate`.

#### Redirects

##### Chaining

Redirection matchers support chaining as follows:
```
expect(insecure_url).to redirect_http_to_https.then(be_successful)
```

This will expect a redirect from http to https and then check that the HTTPS response has a 2xx status code.

Redirection matchers also support custom headers (e.g. for testing m-site redirects):
`expect(desktop_url).to be_temporarily_redirected_to(mobile_url, headers: {user_agent: '...'})`

##### ``` be_permanently_redirected_to ```
```
expect(old).to be_permanently_redirected_to(new)
```

Requires the response code to be 301, and redirect to new

##### ``` be_temporarily_redirected_to ```
The same as be_permanently_redirected_to, except expecting a 302

##### ``` redirect_http_to_https ```
```
expect(url).to redirect_http_to_https(with: 302)
```
Checks that requests for this URL via HTTP are redirected to the same URL via HTTPS.

This does what you would expect whether the supplied URL is HTTP or HTTPS.

##### ``` redirect_https_to_http ```
```
expect(url).to redirect_https_to_http(with: 302)
```
Checks that requests for this URL via HTTPS are redirected to the same URL via HTTP.

This does what you would expect whether the supplied URL is HTTP or HTTPS.

##### ``` redirect_to_remove_trailing_slash ```
```
expect(url).to redirect_to_remove_trailing_slash(with: 302)
```
Checks that requests for this URL with a trailing slash are redirected to the same URL without a trailing slash

This does what you would expect whether the supplied URL has a trailing slash or not.

##### ``` redirect_to_add_trailing_slash ```
```
expect(url).to redirect_to_add_trailing_slash(with: 302)
```
Checks that requests for this URL without a trailing slash are redirected to the same URL with a trailing slash

This does what you would expect whether the supplied URL has a trailing slash or not.


#### General HTTP

##### ``` be_successful ```
```
expect(url).to be_successful
```

expect a response code of 200-299.
Override the valid response codes with `be_successful(response_codes: 200..204)`

##### ``` respond_with_headers ```
```
expect(url).to respond_with_headers(cache_control: "no-cache")
```

Checks that the given headers are present in an HTTP response.

##### ``` be_verifiably_secure ```
```
expect(url).to be_verifiably_secure
```

The SSL cert can be verified by the default configuration of openssl.

Previously also checked that HTTP is unavailable, or redirects to HTTPS.
If you still want to check HTTP redirects, use `should redirect_http_to_https`


##### ``` be_gzipped ```
```
expect(url).to be_gzipped
```

Expect the response to be gzipped.

##### ``` have_cookie ```
```
expect(url).to have_cookie cookie
```

Expect the url to contain the specified cookie

##### ``` be_forbidden ```
```
expect(url).to be_forbidden
```

Expect the url to response with 403

#### Origin configuration

##### ``` be_served_from_origin ```
```
expect(url).to be_served_from_origin origin
```

'x_cache_key' header to include origin url

##### ``` have_cp_code ```
```
expect(url).to have_cp_code(cp_code)
```

- Check that cache key contains Content Provider Code

##### `be_forwarded_to_path`
```
expect("example.com/foo").to be_forwarded_to_path("/foo")
```
Aliases: `be_forwarded_to_index`

Expect response to have an x-akamai-session-info header containing
`AKA_PM_FWD_URL; value="/foo"`

This means that the request is being passed back to the origin
with a path of "/foo"

## Advanced usage

The examples in the specs/functional folder have more details.

# Contributions

We would be very thankful for any contributions, particularly documentation or tests.

# License
Copyright (C) 2015 REA Group Ltd.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
