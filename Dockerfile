# Set versions
ARG NGINX_VERSION=1.24.0

# First stage to build
FROM nginx:${NGINX_VERSION}-alpine AS build

ARG NGINX_VERSION

WORKDIR /additional

COPY docker-entrypoint.sh docker-entrypoint.sh

RUN mkdir brotli-dist

ENV brotli_folder=/additional

RUN ls -la /usr/lib/nginx/modules

RUN apk update \
    && apk add wget git linux-headers openssl-dev pcre2-dev zlib-dev openssl abuild \
      musl-dev libxslt libxml2-utils make mercurial gcc unzip git \
      xz g++ coreutils \
    && wget https://nginx.org/download/nginx-$NGINX_VERSION.tar.gz \
    && tar zxvf nginx-$NGINX_VERSION.tar.gz \
    && git clone https://github.com/google/ngx_brotli.git \
    && cd $brotli_folder/ngx_brotli || exit \
    && git submodule update --init \
    && cd $brotli_folder/nginx-$NGINX_VERSION || exit \
    && ./configure --with-compat --add-dynamic-module=../ngx_brotli \
    && make modules \
    && cp $brotli_folder/nginx-$NGINX_VERSION/objs/*.so $brotli_folder/brotli-dist \
    && echo "brotli assembled successfully"

# Second stage to run
FROM nginx:${NGINX_VERSION}-alpine-slim

COPY --from=build /additional/docker-entrypoint.sh /docker-entrypoint.sh
COPY --from=build /usr/lib/nginx/modules/ngx_http_geoip_module.so /usr/lib/nginx/modules/ngx_http_geoip_module.so
COPY --from=build /additional/brotli-dist /usr/lib/nginx/additional-modules


RUN ls -la /usr/lib/nginx/modules
RUN ls -la /usr/lib/nginx
