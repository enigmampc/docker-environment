FROM alpine

RUN apk --update add git && \
    rm -rf /var/lib/apt/lists/* && \
    rm /var/cache/apk/*

ARG branch=develop

# Cache buster -- make sure everything after this is never cached
ADD http://worldtimeapi.org/api/timezone/Europe/London.txt /tmp/bustcache

WORKDIR /root

RUN git clone --single-branch --branch ${branch} https://github.com/enigmampc/salad.git
