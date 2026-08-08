FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive

# 必要な依存をすべてインストール（DOMjudge公式推奨 + Render向け）
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
    python3 \
    python3-dev \
    python3-distutils \
    nginx \
    tzdata \
    wget \
    ca-certificates

# DOMjudge tarball を取得
RUN wget https://www.domjudge.org/releases/domjudge-8.2.0.tar.gz -O /tmp/domjudge.tar.gz

# 展開
RUN tar xvf /tmp/domjudge.tar.gz -C /opt

# domserver ディレクトリへ移動
WORKDIR /opt/domjudge-8.2.0

# configure → make
RUN ./configure --disable-submitclient --disable-judgehost
RUN make domserver

# Web assets をインストール
RUN make install-domserver WEBROOT=/opt/domjudge/webroot \
    && mkdir -p /opt/domjudge/etc

# entrypoint を追加
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# nginx をフォアグラウンド化
RUN echo "daemon off;" >> /etc/nginx/nginx.conf

# ポート公開
EXPOSE 80

ENTRYPOINT ["/entrypoint.sh"]
