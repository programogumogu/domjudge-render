FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    build-essential \
    gcc \
    g++ \
    make \
    autoconf \
    automake \
    libtool \
    pkg-config \
    libpq-dev \
    libcurl4-openssl-dev \
    libzip-dev \
    libmagic-dev \
    libjansson-dev \
    libcgroup-dev \
    php-cli \
    php-fpm \
    php-mbstring \
    php-xml \
    php-pgsql \
    php-curl \
    php-zip \
    php-intl \
    python3 \
    python3-dev \
    python3-distutils \
    nginx \
    tzdata \
    wget \
    ca-certificates

# 正しい tarball URL（公式サイト）
RUN wget https://www.domjudge.org/releases/domjudge-8.2.0.tar.gz -O /tmp/domjudge.tar.gz
RUN tar xvf /tmp/domjudge.tar.gz -C /opt

WORKDIR /opt/domjudge-8.2.0

# PostgreSQL モードで configure
RUN ./configure --with-db=pgsql --disable-submitclient --disable-judgehost

RUN make domserver
RUN make install-domserver WEBROOT=/opt/domjudge/webroot

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

RUN echo "daemon off;" >> /etc/nginx/nginx.conf

EXPOSE 80

ENTRYPOINT ["/entrypoint.sh"]
