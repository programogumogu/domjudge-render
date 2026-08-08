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
    php-cli \
    php-fpm \
    php-mbstring \
    php-xml \
    php-pgsql \
    php-curl \
    php-zip \
    php-intl \
    nginx \
    tzdata \
    python3 \
    python3-dev \
    python3-distutils



# 基本ツール
RUN apt-get update && apt-get install -y \
    build-essential \
    php-cli php-curl php-json php-mbstring php-xml php-zip \
    php-pgsql \
    mariadb-client \
    curl \
    git \
    unzip \
    nginx \
    supervisor \
    && apt-get clean

# DOMjudge を取得
RUN git clone https://github.com/DOMjudge/domjudge.git /domjudge

# domserver ディレクトリに移動
WORKDIR /domjudge/domserver

# domserver をビルド
RUN ./configure --disable-submitclient --disable-judgehost && \
    make domserver

# Web assets をコピー
RUN make install-domserver WEBROOT=/opt/domjudge/webroot \
    && mkdir -p /opt/domjudge/etc

# entrypoint を追加
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# nginx と supervisor の設定（最小構成）
RUN echo "daemon off;" >> /etc/nginx/nginx.conf

# ポート公開
EXPOSE 80

ENTRYPOINT ["/entrypoint.sh"]
