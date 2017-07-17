#!/bin/bash

set -xu
set -eo pipefail

for ver in 2.1.2 2.1.8 2.2.4 2.4.1 ; do
    docker build --build-arg RUBY_VERSION=${ver} --tag akamai-rspec-gem-test:${ver} .
    docker run --rm akamai-rspec-gem-test:${ver}
done
