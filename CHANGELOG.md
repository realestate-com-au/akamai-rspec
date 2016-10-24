Change history / upgrade notes

# 0.5

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

Previously requests which returned 'not modified' from the backend
would pass `be_cacheable`; you now need to use `be_cacheable(allow_refresh: true)`.

## Origin cache headers

Now actually contacts the upstream to determine cache headers

