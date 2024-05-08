# Set versions
ARG ALPINE_VERSION=3.19
ARG NGINX_VERSION=1.25.5

# First stage to build
FROM alpine:${ALPINE_VERSION} AS build

RUN apk add curl ca-certificates \
    && curl -o /etc/apk/keys/angie-signing.rsa \
      https://angie.software/keys/angie-signing.rsa \
    && echo "https://download.angie.software/angie/alpine/v$(egrep -o \
      '[0-9]+\.[0-9]+' /etc/alpine-release)/main" \
      | tee -a /etc/apk/repositories > /dev/null \
    && apk update \
    && apk add angie angie-module-brotli angie-module-subs angie-module-zstd \
    && rm -f /usr/lib/angie/modules/*debug.so

# Second stage to run
FROM nginx:${NGINX_VERSION}-alpine-slim

COPY --from=build /usr/lib/angie/modules /usr/lib/nginx/additional-modules
