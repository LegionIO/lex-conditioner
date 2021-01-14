FROM ruby:2.7-alpine
LABEL maintainer="Matthew Iverson <matthewdiverson@gmail.com>"

RUN mkdir /etc/legionio
RUN apk update && apk add build-base tzdata gcc git

COPY . ./
RUN gem install legionio tzinfo-data tzinfo --no-document --no-prerelease
RUN gem install lex-conditioner --no-document --no-prerelease
CMD legionio
