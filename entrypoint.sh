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

# 初期 DB セットアップ（tarball 版の正しいパス）
/opt/domjudge/domserver/bin/dj_setup_database -u "$USER" -p "$PASS" -H "$HOST" -d "$DBNAME"

# 管理者アカウント作成
/opt/domjudge/domserver/bin/dj_admin_user --add admin --password admin || true

# PHP-FPM 起動
php-fpm8.1

# nginx 起動
nginx

# DOMjudge Web を提供
php -S 0.0.0.0:80 -t /opt/domjudge/webroot
