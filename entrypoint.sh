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
# 3. Generate nginx.conf
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

    server {
        listen ${PORT};
        server_name _;
        root /opt/domjudge/domserver/webapp/public;

        index index.php;

        location / {
            try_files \$uri /index.php?\$args;
        }

        location ~ \.php$ {
            include fastcgi_params;
            fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
            fastcgi_pass unix:/run/php/php-fpm.sock;
        }
    }
}
EOF

# ============================
# 4. Start php-fpm + nginx
# ============================
/usr/sbin/php-fpm8.1 -F &
nginx -g "daemon off;"
