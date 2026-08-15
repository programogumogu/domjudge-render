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
    libcurl4-openssl-dev \
    libzip-dev \
    libmagic-dev \
    libjansson-dev \
    libcgroup-dev \
    php-cli \
    php-fpm \
    php-mbstring \
    php-xml \
    php-curl \
    php-zip \
    php-intl \
    php-mysql \
    python3 \
    python3-dev \
    python3-distutils \
    nginx \
    tzdata \
    wget \
    ca-certificates \
    curl \
    mysql-client

# Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# DOMjudge
RUN wget https://www.domjudge.org/releases/domjudge-9.0.1.tar.gz -O /tmp/domjudge.tar.gz
RUN tar xvf /tmp/domjudge.tar.gz -C /opt

WORKDIR /opt/domjudge-9.0.1

# DOMjudge 9 の正しい configure
RUN ./configure --with-domjudge-user=root

RUN make install-domserver WEBROOT=/opt/domjudge/domserver/webapp/public

RUN find /opt -name Version20221004135409.php -delete

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 80

ENTRYPOINT ["/entrypoint.sh"]
