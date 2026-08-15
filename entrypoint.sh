#!/bin/bash
set -e

cd /opt/domjudge/domserver/webapp

# Remove problematic migration (MySQL does not have lazy_eval_results)
rm -f /opt/domjudge/domserver/lib/vendor/domjudge/domjudge/doctrine-migrations/DoctrineMigrations/Version20221004135409.php

echo "Running Doctrine migrations..."
php bin/console doctrine:migrations:migrate --no-interaction

echo "Loading initial data..."
php bin/console domjudge:load-data --no-interaction

echo "Creating admin user..."
php bin/console domjudge:admin --add admin --password admin

php-fpm8.1 -F &
nginx -g "daemon off;"
