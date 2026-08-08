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
    python3-yaml \
    **python3-sphinx** \
    **python3-sphinx-rtd-theme** \
    nginx \
    tzdata \
    git \
    wget \
    ca-certificates


# GitHub 版 DOMjudge を取得
RUN git clone https://github.com/DOMjudge/domjudge.git /domjudge
WORKDIR /domjudge

# ビルド準備
RUN ./bootstrap

# PostgreSQL モードで configure
RUN ./configure --with-db=pgsql --disable-submitclient --disable-judgehost --disable-docs


RUN make domserver
RUN make install-domserver WEBROOT=/opt/domjudge/webroot

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

RUN echo "daemon off;" >> /etc/nginx/nginx.conf

EXPOSE 80

ENTRYPOINT ["/entrypoint.sh"]
