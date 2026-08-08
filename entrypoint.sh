#!/bin/bash
set -e

# DATABASE_URL を分解
DBURL=$DATABASE_URL
PROTO="$(echo $DBURL | sed -e's,^\(.*://\).*,\1,g')"
REST="$(echo ${DBURL/$PROTO/})"
USER="$(echo $REST | cut -d: -f1)"
PASS="$(echo $REST | cut -d: -f2 | cut -d@ -f1)"
HOST="$(echo $REST | cut -d@ -f2 | cut -d/ -f1)"
DBNAME="$(echo $REST | cut -d/ -f2)"

DJBIN="/opt/domjudge/domserver/bin/dj_setup_database"

# 引数形式を自動判定
if $DJBIN --help 2>&1 | grep -q -- "--host"; then
    # 新形式（GitHub版）
    $DJBIN --user="$USER" --password="$PASS" --host="$HOST" --dbname="$DBNAME"
elif $DJBIN --help 2>&1 | grep -q "Usage:"; then
    # 古い形式（tarballの一部）
    $DJBIN -u "$USER" -p "$PASS" "$DBNAME"
else
    # 最後の fallback（host を受け取らない古い版）
    $DJBIN -u "$USER" -p "$PASS"
fi

# 管理者アカウント作成
/opt/domjudge/domserver/bin/dj_admin_user --add admin --password admin || true

# PHP-FPM 起動
php-fpm8.1

# nginx 起動
nginx

# DOMjudge Web を提供
php -S 0.0.0.0:80 -t /opt/domjudge/webroot
