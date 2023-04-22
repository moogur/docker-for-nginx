# Set versions
ARG ALPINE_VERSION=3.17
ARG NGINX_VERSION=1.23.4

# First stage to build
FROM alpine:${ALPINE_VERSION} AS build

WORKDIR /additional

COPY docker-entrypoint.sh docker-entrypoint.sh

RUN mkdir brotli \
    && cd brotli \
    && mkdir dist

ENV nginx_version=${NGINX_VERSION}
ENV brotli_folder=/additional/brotli

RUN apk update \
    && apk add wget git linux-headers openssl-dev pcre2-dev zlib-dev openssl abuild \
      musl-dev libxslt libxml2-utils make mercurial gcc unzip git \
      xz g++ coreutils \
    && wget https://nginx.org/download/nginx-$nginx_version.tar.gz \
    && tar zxvf nginx-$nginx_version.tar.gz \
    && git clone https://github.com/google/ngx_brotli.git \
    && cd $brotli_folder/ngx_brotli || exit \
    && git submodule update --init \
    && cd $brotli_folder/nginx-$nginx_version || exit \
    && ./configure --with-compat --add-dynamic-module=../ngx_brotli \
    && make modules \
    && cp $brotli_folder/nginx-$nginx_version/objs/*.so $brotli_folder/dist \
    && echo "brotli assembled successfully"

# Second stage to run
FROM nginx:${NGINX_VERSION}

COPY --from=build /additional/docker-entrypoint.sh /docker-entrypoint.sh
COPY --from=build /additional/brotli/dist /usr/lib/nginx/additional-modules

CMD ["nginx" "-g" "daemon off;"]