#!/bin/bash
set -e

# ============================
# 1. Generate DB config
# ============================
cat > /opt/domjudge/domserver/etc/db-config.yaml <<EOF
database:
  host: "${DB_HOST}"
  port: ${DB_PORT}
  name: "${DB_NAME}"
  user: "${DB_USER}"
  password: "${DB_PASS}"
  sslmode: "${DB_SSL}"
EOF

cat > /opt/domjudge/domserver/etc/dbpasswords.secret <<EOF
${DB_PASS}
EOF

# ============================
# 2. Initialize DOMjudge DB
# ============================
cd /opt/domjudge/domserver/webapp

php bin/console doctrine:migrations:migrate --no-interaction
php bin/console domjudge:load-default-data --no-interaction

# ============================
# 3. Generate nginx.conf (DOMjudge 9 正しい構成)
# ============================
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

# ============================
# 4. Start php-fpm + nginx
# ============================
php-fpm8.1 -F &
nginx -g "daemon off;"
