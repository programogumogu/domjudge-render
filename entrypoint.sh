#!/bin/bash
set -e

# DATABASE_URL を分解（クエリなし前提）
DBURL="$DATABASE_URL"
REST="${DBURL#*://}"

USER="${REST%%:*}"
PASS="$(echo "$REST" | cut -d: -f2 | cut -d@ -f1)"
HOST="$(echo "$REST" | cut -d@ -f2 | cut -d/ -f1)"
DBNAME="$(echo "$REST" | cut -d/ -f2)"

# db.php を生成（DBNAME はここで設定）
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

# あなたの DOMjudge は「install」コマンドを使う
$DJBIN -u "$USER" -p "$PASS" install

# 管理者アカウント作成
/opt/domjudge/domserver/bin/dj_admin_user --add admin --password admin || true

php-fpm8.1
nginx
php -S 0.0.0.0:80 -t /opt/domjudge/webroot
