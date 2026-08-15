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

RUN ./configure --with-domjudge-user=root --with-db=mysql
RUN make install-domserver WEBROOT=/opt/domjudge/domserver/webapp/public

# Remove problematic migration
RUN find /opt -name Version20221004135409.php -delete

# Install DOMjudge nginx config correctly
RUN printf "user www-data;\nworker_processes auto;\n\nevents {\n    worker_connections 1024;\n}\n\nhttp {\n    include /etc/nginx/mime.types;\n    default_type application/octet-stream;\n\n    upstream php-handler {\n        server unix:/run/php/php-fpm.sock;\n    }\n\n    server {\n        listen 80;\n        server_name _;\n        root /opt/domjudge/domserver/webapp/public;\n\n        include /opt/domjudge/domserver/etc/nginx-conf-inner;\n    }\n}\n" > /etc/nginx/nginx.conf

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 80

ENTRYPOINT ["/entrypoint.sh"]
