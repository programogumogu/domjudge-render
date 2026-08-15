#!/bin/bash
set -e

DBURL="$DATABASE_URL"
REST="${DBURL#*://}"

USER="${REST%%:*}"
PASS="$(echo "$REST" | cut -d: -f2 | cut -d@ -f1)"
HOST="$(echo "$REST" | cut -d@ -f2 | cut -d/ -f1)"
DBNAME="$(echo "$REST" | cut -d/ -f2)"

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

echo "Running dj_setup_database (old format)..."
$DJBIN -u "$USER" -p "$PASS" "$DBNAME" || echo "bare-install failed"

echo "Installing example data..."
$DJBIN -u "$USER" -p "$PASS" install-examples || echo "install-examples failed"

echo "Adding admin user..."
/opt/domjudge/domserver/bin/dj_admin_user --add admin --password admin || echo "admin user failed"

php-fpm8.1 -F &
nginx -g "daemon off;"
