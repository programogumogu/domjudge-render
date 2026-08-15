#!/bin/bash
set -e

cd /opt/domjudge/domserver/webapp

php bin/console doctrine:migrations:migrate --no-interaction
php bin/console domjudge:load-default-data --no-interaction

# Render が渡す PORT を使って nginx.conf を生成
cat > /etc/nginx/nginx.conf <<EOF
user www-data;
worker_processes auto;

events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    upstream php-handler {
        server unix:/run/php/php-fpm.sock;
    }

    server {
        listen ${PORT};
        server_name _;
        root /opt/domjudge/domserver/webapp/public;

        include /opt/domjudge/domserver/etc/nginx-conf-inner;
    }
}
EOF

php-fpm8.1 -F &
nginx -g "daemon off;"
