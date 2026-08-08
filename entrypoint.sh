#!/bin/bash
set -e

# DATABASE_URL を分解（クエリ文字列なし前提）
DBURL="$DATABASE_URL"

# プロトコル除去
REST="${DBURL#*://}"

# USER:PASSWORD@HOST/DBNAME を分解
USER="${REST%%:*}"
PASS="$(echo "$REST" | cut -d: -f2 | cut -d@ -f1)"
HOST="$(echo "$REST" | cut -d@ -f2 | cut -d/ -f1)"
DBNAME="$(echo "$REST" | cut -d/ -f2)"

# DOMjudge 設定ファイル生成（DBNAME はここで設定する）
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

DJBIN="/opt/domjudge/domserver/bin/dj_setup_database"

# あなたの DOMjudge は DBNAME を引数で受け取らない
$DJBIN -u "$USER" -p "$PASS"

# 管理者アカウント作成
/opt/domjudge/domserver/bin/dj_admin_user --add admin --password admin || true

# PHP-FPM 起動
php-fpm8.1

# nginx 起動
nginx

# DOMjudge Web を提供
php -S 0.0.0.0:80 -t /opt/domjudge/webroot
