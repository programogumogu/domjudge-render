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

# GitHub 版はこの形式で確実に動く
echo "Running dj_setup_database..."
$DJBIN --user="$USER" --password="$PASS" --host="$HOST" --dbname="$DBNAME" --sslmode=require install
echo "Adding admin user..."
/opt/domjudge/domserver/bin/dj_admin_user --add admin --password admin || true


echo "Running migrations..."
php bin/console doctrine:migrations:migrate --no-interaction || echo "Migration failed"
echo "Loading initial data..."
php bin/console domjudge:load-data --no-interaction || echo "Load-data failed"

# Run DB migrations (only once needed)
php bin/console doctrine:migrations:migrate --no-interaction

# Load initial data (admin user, languages, etc.)
php bin/console domjudge:load-data --no-interaction


php-fpm8.1 -F &
nginx -g "daemon off;"
