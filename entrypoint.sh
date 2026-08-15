#!/bin/bash
set -e

cd /opt/domjudge/domserver/webapp

php bin/console doctrine:migrations:migrate --no-interaction
php bin/console domjudge:load-default-data --no-interaction

# Render が渡す PORT を使って Symfony の Web サーバーを起動
php -S 0.0.0.0:$PORT -t public
