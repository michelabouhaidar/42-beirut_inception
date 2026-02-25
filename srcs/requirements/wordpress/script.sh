#!/bin/sh
set -eu

DB_PW="$(cat /run/secrets/db_password)"
ADMIN_PW="$(cat /run/secrets/wp_admin_password)"
USER_PW="$(cat /run/secrets/wp_user_password)"

mkdir -p /run/php
cd /var/www/html

# wp-cli
if [ ! -f /usr/local/bin/wp ]; then
  curl -sSLo /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
  chmod +x /usr/local/bin/wp
fi

# core files
if [ ! -f wp-settings.php ]; then
  wp core download --allow-root
fi

# wp-config
if [ ! -f wp-config.php ]; then
  wp config create \
    --dbname="${MYSQL_DATABASE}" \
    --dbuser="${MYSQL_USER}" \
    --dbpass="${DB_PW}" \
    --dbhost=mariadb \
    --allow-root
fi

# install
if ! wp core is-installed --allow-root >/dev/null 2>&1; then
  wp core install \
    --url="https://${DOMAIN_NAME}" \
    --title="${WP_TITLE}" \
    --admin_user="${WP_ADMIN_USER}" \
    --admin_password="${ADMIN_PW}" \
    --admin_email="${WP_ADMIN_EMAIL}" \
    --skip-email \
    --allow-root

  # optional extra user
  if ! wp user get "${WP_USER}" --allow-root >/dev/null 2>&1; then
    wp user create "${WP_USER}" "${WP_USER_EMAIL}" --user_pass="${USER_PW}" --role=author --allow-root
  fi
fi

exec php-fpm8.4 -F