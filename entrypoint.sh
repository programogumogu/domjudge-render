#!/bin/bash
set -e

cd /opt/domjudge/domserver/webapp

php bin/console doctrine:migrations:migrate --no-interaction
php bin/console domjudge:load-default-data --no-interaction

php-fpm8.1 -F &
nginx -g "daemon off;"
