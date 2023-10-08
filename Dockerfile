FROM alpine AS build-deps

LABEL maintainer="Tony <i@tony.moe>"

ENV NGINX_VERSION 1.24.0
ENV ZLIB_VERSION 1.3
ENV OPENSSL_VERSION 1.1.1w
ENV HEADERS_MORE_NGINX_MODULE_VERSION 0.34

RUN apk add --no-cache --virtual .build-deps \
    curl \
    gcc \
    gd-dev \
    geoip-dev \
    git \
    libc-dev \
    libxslt-dev \
    linux-headers \
    make \
    pcre-dev \
  \
  && mkdir /usr/src \
  && cd /usr/src \
  \
  && mkdir zlib \
  && curl -sL https://github.com/madler/zlib/archive/v${ZLIB_VERSION}.tar.gz \
    | tar --strip-components 1 -C zlib -xzf - \
  && cd zlib \
  && make -f Makefile.in distclean \
  && cd .. \
  \
  && mkdir openssl \
  && curl -sL https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz \
    | tar --strip-components 1 -C openssl -xzf - \
  \
  && mkdir headers-more-nginx-module \
  && curl -sL https://github.com/openresty/headers-more-nginx-module/archive/v${HEADERS_MORE_NGINX_MODULE_VERSION}.tar.gz \
    | tar --strip-components 1 -C headers-more-nginx-module -xzf - \
  \
  && git clone --recursive https://github.com/eustas/ngx_brotli.git \
  \
  && mkdir nginx \
  && curl -sL https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz \
    | tar --strip-components 1 -C nginx -xzf - \
  && cd nginx \
  && ./configure \
    --prefix=/etc/nginx \
    --sbin-path=/usr/sbin/nginx \
    --modules-path=/usr/lib/nginx/modules \
    --conf-path=/etc/nginx/nginx.conf \
    --error-log-path=/var/log/nginx/error.log \
    --http-log-path=/var/log/nginx/access.log \
    --pid-path=/var/run/nginx.pid \
    --lock-path=/var/run/nginx.lock \
    --http-client-body-temp-path=/var/cache/nginx/client_temp \
    --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
    --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
    --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
    --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
    --with-perl_modules_path=/usr/lib/perl5/vendor_perl \
    --user=nginx \
    --group=nginx \
    --with-compat \
    --with-file-aio \
    --with-threads \
    --with-http_addition_module \
    --with-http_auth_request_module \
    --with-http_dav_module \
    --with-http_flv_module \
    --with-http_gunzip_module \
    --with-http_gzip_static_module \
    --with-http_mp4_module \
    --with-http_random_index_module \
    --with-http_realip_module \
    --with-http_secure_link_module \
    --with-http_slice_module \
    --with-http_ssl_module \
    --with-http_stub_status_module \
    --with-http_sub_module \
    --with-http_v2_module \
    --with-mail \
    --with-mail_ssl_module \
    --with-stream \
    --with-stream_realip_module \
    --with-stream_ssl_module \
    --with-stream_ssl_preread_module \
    --with-cc-opt='-Os -fomit-frame-pointer' \
    --with-ld-opt='-Wl,--as-needed' \
    \
    --with-zlib=../zlib \
    --with-openssl=../openssl \
    --with-openssl-opt='zlib' \
    --add-module=../headers-more-nginx-module \
    --add-module=../ngx_brotli \
  && make \
  && make install DESTDIR=/usr/src/build-deps \
  \
  && cd .. \
  && strip build-deps/usr/sbin/nginx \
  && rm -rf build-deps/etc/nginx/html

FROM alpine

COPY --from=build-deps /usr/src/build-deps/etc /etc
COPY --from=build-deps /usr/src/build-deps/usr /usr

RUN addgroup -S nginx \
  && adduser -D -S -h /var/cache/nginx -s /sbin/nologin -G nginx nginx \
  \
  && runDeps=$( \
    scanelf --needed --nobanner --format '%n#p' /usr/sbin/nginx \
      | tr ',' '\n' \
      | sort -u \
      | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
  ) \
  && apk add --no-cache --virtual .nginx-rundeps $runDeps \
  \
  && mkdir -p /var/log/nginx \
  && ln -sf /dev/stdout /var/log/nginx/access.log \
  && ln -sf /dev/stderr /var/log/nginx/error.log

COPY nginx /etc/nginx

VOLUME ["/etc/nginx", "/data/wwwroot", "/data/wwwlogs"]
EXPOSE 80 443

ENTRYPOINT ["nginx"]
CMD ["-g", "daemon off;"]
