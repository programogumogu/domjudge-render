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

# DOMjudge 設定ファイル生成
cat <<EOF > /opt/domjudge/etc/db.php
<?php
return [
    'driver' => 'pgsql',
    'host' => '$HOST',
    'database' => '$DBNAME',
    'username' => '$USER',
    'password' => '$PASS',
];
EOF

# 初期 DB セットアップ
/domjudge/domserver/bin/dj_setup_database -u "$USER" -p "$PASS" -H "$HOST"

# 管理者アカウント作成（存在しなければ）
/domjudge/domserver/bin/dj_admin_user --add admin --password admin

# nginx 起動
nginx &

# PHP built-in server（軽量）
php -S 0.0.0.0:80 -t /opt/domjudge/webroot
