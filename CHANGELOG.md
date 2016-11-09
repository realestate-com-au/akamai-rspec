Change history / upgrade notes

# 1.2.2

`be_cacheable` now makes requests for the same resource until it gets N requests (default=4) served by the same edge node.

# 1.2.0

## Caching

`be_cacheable` now makes requests for the same resource until it gets two requests served by the same edge node.

`be_cacheable` no longer checks for a response status of 200; use `be_successful` to check this.

`honour_origin_cache_headers` no longer crashes if a max-age isn't specified.

# 1.1.0

## Redirects

Redirects matchers now accept custom headers, e.g.
```
should be_permanantly_redirected_to(other_url, headers: {cookie: 'foo: bar'})
```

`be_temporarily_redirected_with_trailing_slash` is deprecated in favor
of `redirect_to_add_trailing_slash(with: 302)`.

## SSL checks

`be_verifiably_secure` no longer accidentally tests redirects.

To get the old behavior, add a check for:
`should be_permanantly_redirected_to(other_url).then be_verifiably_secure`

# 1.0.0

## Loading

Previously all matchers were added to the global namespace when you load this gem.

As of 1.0.0, you'll need to `include AkamaiRSpec::Matchers` in specs which use them (or in your global rspec config).

## `be_served_from_origin` and status codes

Previously, `be_served_from_origin` would follow redirects and check the last URL.

It now checks the URL you specify is served from the origin you specify, and *does not* check the status code.

## Redirects & chaining

Until now, most checks have followed redirects and asserted that the final result has status 200.

This release opens up support for assertions on redirects, like
```
expect('google.com').to redirect_http_to_https.then be_successful
```

This enables more fine-grained checks but also means you'll need to revise your tests when you update.

## Caching

We had been checking the `X-Check-Cacheable` header.
As Akamai no longer recommends relying on this header, we now make
a sequence of requests and look for `X-Cache: TCP_HIT`.
If any request is a cache hit we infer that the resource is cacheable.

Previously requests which returned 'not modified' from the backend
would pass `be_cacheable`; you now need to use `be_cacheable(allow_refresh: true)`.

Finally, `to not_be_cached` has been removed in favor of the standard
rspec syntax `not_to be_cached`
## Origin cache headers

Now actually contacts the upstream to determine cache headers

