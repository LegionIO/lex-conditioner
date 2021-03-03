FROM legionio/legion:latest
LABEL maintainer="Matthew Iverson <matthewdiverson@gmail.com>"

RUN apk update && apk add build-base tzdata postgresql-dev mysql-client mariadb-dev tzdata gcc git

COPY . ./
RUN gem install lex-conditioner legion-data --no-document --no-prerelease
CMD ruby $(which legionio)
