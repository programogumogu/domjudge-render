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

    # DOMjudge の公式 nginx 設定（server ブロックを含む）
    include /opt/domjudge/domserver/etc/nginx-conf;

    # Render の PORT を使うように上書き
    server {
        listen ${PORT};
        server_name _;
        root /opt/domjudge/domserver/webapp/public;

        index index.php;

        location / {
            try_files \$uri /index.php?\$args;
        }

        location ~ \.php$ {
            include snippets/fastcgi-php.conf;
            fastcgi_pass unix:/run/php/php-fpm.sock;
        }
    }
}
EOF


# ============================
# 4. Start php-fpm + nginx
# ============================
php-fpm8.1 -F &
nginx -g "daemon off;"
