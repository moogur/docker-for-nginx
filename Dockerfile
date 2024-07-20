# Set versions
ARG ALPINE_VERSION=3.19
ARG NGINX_VERSION=1.27.0

# First stage to build
FROM alpine:${ALPINE_VERSION} AS build

ARG NGINX_VERSION

WORKDIR /additional

RUN mkdir additional-dist

ENV base_folder=/additional

RUN apk update \
    && apk add wget linux-headers openssl-dev pcre2-dev zlib-dev abuild \
      musl-dev libxslt libxml2-utils make gcc unzip git xz g++ coreutils zstd zstd-dev \
    && wget https://nginx.org/download/nginx-$NGINX_VERSION.tar.gz \
    && tar zxvf nginx-$NGINX_VERSION.tar.gz \
    && git clone https://github.com/google/ngx_brotli.git \
    && git clone --depth=1 --single-branch -b master https://github.com/yaoweibin/ngx_http_substitutions_filter_module.git \
    && git clone --depth=1 --single-branch -b master https://github.com/tokers/zstd-nginx-module.git \
    && git clone --depth=1 --single-branch -b master https://github.com/openresty/headers-more-nginx-module.git \
    && cd $base_folder/ngx_brotli || exit \
    && git checkout 6e975bcb015f62e1f303054897783355e2a877dc \
    && git submodule update --init \
    && cd $base_folder/nginx-$NGINX_VERSION || exit \
    && ./configure \
      --with-compat \
      --add-dynamic-module=../ngx_brotli \
      --add-dynamic-module=../ngx_http_substitutions_filter_module \
      --add-dynamic-module=../zstd-nginx-module \
      --add-dynamic-module=../headers-more-nginx-module \
    && make modules \
    && cp $base_folder/nginx-$NGINX_VERSION/objs/*.so $base_folder/additional-dist \
    && echo "all modules have been successfully assembled"

# Second stage to run
FROM nginx:${NGINX_VERSION}-alpine-slim

RUN apk add --no-cache zstd-dev

COPY --from=build /additional/additional-dist /usr/lib/nginx/additional-modules
