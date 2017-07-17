ARG RUBY_VERSION=2.2

FROM ruby:$RUBY_VERSION

ADD ./ /code/
WORKDIR /code

RUN bundle install

CMD bundle exec rake
