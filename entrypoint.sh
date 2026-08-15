#!/bin/bash
set -e

# Render が勝手に入れる DATABASE_URL を無効化
unset DATABASE_URL
export DATABASE_URL=""


# ============================
# 1. Generate DB config
# ============================
cat > /opt/domjudge/domserver/etc/db-config.yaml <<EOF
database:
    host: "${DB_HOST}"
    port: ${DB_PORT}
    dbname: "${DB_NAME}"
    username: "${DB_USER}"
    password: "${DB_PASS}"
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

# Fix permissions (ACL not available on Render)
chown -R www-data:www-data /opt/domjudge/domserver/webapp/var
chmod -R 775 /opt/domjudge/domserver/webapp/var

# DOMjudge base URL (WebApp が読む正しい構造)
cat > /opt/domjudge/domserver/webapp/config/domjudge.yaml <<EOF
domjudge:
    baseurl: "https://domjudge-web.onrender.com"
EOF


# Force Symfony dev mode
echo "APP_ENV=dev" >> /opt/domjudge/domserver/webapp/.env
echo "APP_DEBUG=1" >> /opt/domjudge/domserver/webapp/.env

# Fix missing APP_URL (required by DOMjudge)
echo "APP_URL=https://domjudge-web.onrender.com" >> /opt/domjudge/domserver/webapp/.env

# ============================
# 3. Generate nginx.conf (Render 用・完全版)
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
            try_files \$uri \$uri/ /index.php;
        }

        location ~ \.php$ {
            include fastcgi_params;
            fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
            fastcgi_pass unix:/run/php/php8.1-fpm.sock;
        }

        location ~ /\.ht {
            deny all;
        }
    }
}
EOF

# ============================
# 4. Start php-fpm + nginx
# ============================
/usr/sbin/php-fpm8.1 -F &
nginx -g "daemon off;"
