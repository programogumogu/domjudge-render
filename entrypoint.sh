#!/bin/bash
set -e

DBURL="$DATABASE_URL"
REST="${DBURL#*://}"

USER="${REST%%:*}"
PASS="$(echo "$REST" | cut -d: -f2 | cut -d@ -f1)"
HOST="$(echo "$REST" | cut -d@ -f2 | cut -d/ -f1)"
DBNAME="$(echo "$REST" | cut -d/ -f2)"

DJBIN="/opt/domjudge/domserver/bin/dj_setup_database"

echo "Initializing database..."
$DJBIN -u "$USER" -p "$PASS" -h "$HOST" install

echo "Adding admin user..."
/opt/domjudge/domserver/bin/dj_admin_user --add admin --password admin || true

php-fpm8.1 -F &
nginx -g "daemon off;"
