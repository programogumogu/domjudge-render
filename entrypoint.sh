#!/bin/bash
set -e

# DATABASE_URL を分解（クエリなし前提）
DBURL="$DATABASE_URL"
REST="${DBURL#*://}"

USER="${REST%%:*}"
PASS="$(echo "$REST" | cut -d: -f2 | cut -d@ -f1)"
HOST="$(echo "$REST" | cut -d@ -f2 | cut -d/ -f1)"
DBNAME="$(echo "$REST" | cut -d/ -f2)"

# 正しい場所に db.php を作成
mkdir -p /opt/domjudge/domserver/etc

cat <<EOF > /opt/domjudge/domserver/etc/db.php
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

# PostgreSQL モードの正しい呼び出し
$DJBIN --user="$USER" --password="$PASS" --host="$HOST" --dbname="$DBNAME" install

# 管理者アカウント作成
/opt/domjudge/domserver/bin/dj_admin_user --add admin --password admin || true

php-fpm8.1
nginx
php -S 0.0.0.0:80 -t /opt/domjudge/webroot
