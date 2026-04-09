#!/bin/sh
set -eu

DB_PW="$(cat /run/secrets/db_password)"
ADMIN_PW="$(cat /run/secrets/wp_admin_password)"
USER_PW="$(cat /run/secrets/wp_user_password)"

echo "[wp-entrypoint] waiting for MariaDB..."
until mysqladmin ping -h mariadb -u"${MYSQL_USER}" -p"${DB_PW}" --silent 2>/dev/null; do
  sleep 1
done
echo "[wp-entrypoint] MariaDB is up"

if [ ! -f /var/www/html/wp-includes/version.php ]; then
  echo "[wp-entrypoint] Copying WordPress files to volume..."
  cp -r /usr/src/wordpress/. /var/www/html/
  chown -R www-data:www-data /var/www/html
fi

cd /var/www/html

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

  if ! wp user get "${WP_USER}" --allow-root >/dev/null 2>&1; then
    wp user create "${WP_USER}" "${WP_USER_EMAIL}" \
      --user_pass="${USER_PW}" --role=author --allow-root
  fi
fi

exec /usr/sbin/php-fpm7.4 -F