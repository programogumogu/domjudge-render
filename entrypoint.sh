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

DJBIN="/opt/domjudge/domserver/bin/dj_setup_database"

# 引数形式を自動判定（バージョン差異吸収）
if $DJBIN --help 2>&1 | grep -q -- "--host"; then
    # 新形式（GitHub版）
    $DJBIN --user="$USER" --password="$PASS" --host="$HOST" --dbname="$DBNAME"
else
    # 古い形式（tarball版）
    $DJBIN -u "$USER" -p "$PASS" "$DBNAME"
fi

# 管理者アカウント作成
/opt/domjudge/domserver/bin/dj_admin_user --add admin --password admin || true

# PHP-FPM 起動
php-fpm8.1

# nginx 起動
nginx

# DOMjudge Web を提供
php -S 0.0.0.0:80 -t /opt/domjudge/webroot
