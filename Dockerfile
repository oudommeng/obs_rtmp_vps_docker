FROM alpine:latest AS build

RUN apk add --no-cache build-base pcre2-dev openssl-dev zlib-dev git

ARG NGINX_VERSION=1.26.2
ARG RTMP_MODULE_VERSION=1.2.2

RUN wget -q https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && \
    tar xzf nginx-${NGINX_VERSION}.tar.gz && \
    git clone --depth 1 -b v${RTMP_MODULE_VERSION} https://github.com/arut/nginx-rtmp-module.git

RUN cd nginx-${NGINX_VERSION} && \
    ./configure \
    --prefix=/usr/local/nginx \
    --with-http_ssl_module \
    --add-module=../nginx-rtmp-module \
    --conf-path=/etc/nginx/nginx.conf \
    --error-log-path=/var/log/nginx/error.log \
    --http-log-path=/var/log/nginx/access.log && \
    make -j$(nproc) && make install

FROM alpine:latest
RUN apk add --no-cache pcre2 openssl zlib
COPY --from=build /usr/local/nginx /usr/local/nginx
COPY --from=build /nginx-rtmp-module/stat.xsl /www/static/stat.xsl
COPY nginx-rtmp.conf /etc/nginx/nginx.conf
RUN mkdir -p /var/log/nginx /tmp/hls
EXPOSE 1935 8080
CMD ["/usr/local/nginx/sbin/nginx"]