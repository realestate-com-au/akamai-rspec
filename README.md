# akamai-rspec

Use rspec to test your akamai configuration.

## How to use

### Basic configuration
To use, you must configure the domains:
# having both is stupid
RestClient::Request.stg_domain("<mysite>.edgesuite-staging.net")
RestClient::Request.prod_domain("<mysite>.edgesuite.net")

The default akamai network used is prod, to test in staging you must specify.
RestClient::Request.akamai_network("staging")

#### matchers

``` be_permanently_redirected_to ```
``` expect(<old-url-string>).to be_permanently_redirected_to(<new-url-string>) ```
Requires the response code to be 301, and redirect to <new-url-string>

``` be_temporarily_redirected_to ```
The same as be_permanently_redirected_to, except expecting a 302

``` be_temporarily_redirected_to_with_trailing_slash ```
The same as be_temporarily_redirected_to, but also expect the response location to have a '/' added

``` be_cacheable ```
Requests to the url with the akamai debug headers should have X-Check-Cacheable as yes in the
response headers

``` have_no_cache_control ```


``` not_be_cached ```

``` be_successful ```

``` be_verifiably_secure ```

``` be_served_from_origin ```

``` honour_origin_cache_headers```

``` be_forwarded_to_index ```

``` be_tier_distributed ```

``` be_gzipped ```

``` set_cookie ```

``` check_cp_code ```

# making requests

## Contributions
We would be very thankful for any contributions, particularly documentation or tests.

## License
Copyright (C) 2015 REA Group Ltd.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
