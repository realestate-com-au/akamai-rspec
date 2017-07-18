#! /bin/bash
gem uninstall akamai_rspec
rm akamai_rspec-*.gem
gem build akamai_rspec.gemspec
gem install akamai_rspec-*.gem
