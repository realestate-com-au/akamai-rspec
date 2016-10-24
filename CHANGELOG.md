Change history / upgrade notes

# 0.5

## Redirects & chaining

Until now, most checks have followed redirects and asserted that the final result has status 200.

This release opens up support for assertions on redirects, like
```
expect('google.com').to redirect_http_to_https.then be_successful
```

This enables more fine-grained checks but also means you'll need to revise your tests when you update.

