#!/bin/sh
set -eu

log() { printf "\n[mariadb-entrypoint] %s\n" "$*"; }

: "${MYSQL_DATABASE:?MYSQL_DATABASE is required}"
: "${MYSQL_USER:?MYSQL_USER is required}"

MYSQL_ROOT_PASSWORD="$(cat /run/secrets/db_root_password)"
MYSQL_PASSWORD="$(cat /run/secrets/db_password)"

if [ -d "/var/lib/mysql/mysql" ]; then
  log "Existing data directory -> fixing grants then starting"
  mysqld --user=mysql --datadir=/var/lib/mysql --skip-networking \
    --socket=/run/mysqld/mysqld.sock &
  pid="$!"
  until mysqladmin ping --socket=/run/mysqld/mysqld.sock --silent 2>/dev/null; do
    sleep 1
  done
  mysql --protocol=socket --socket=/run/mysqld/mysqld.sock \
    -uroot -p"${MYSQL_ROOT_PASSWORD}" << SQL
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
SQL
  mysqladmin --protocol=socket --socket=/run/mysqld/mysqld.sock \
    -uroot -p"${MYSQL_ROOT_PASSWORD}" shutdown
  wait "$pid" || true

  log "Init complete -> starting mysqld"
  exec mysqld --user=mysql --datadir=/var/lib/mysql
fi

log "First-time initialization"
chown -R mysql:mysql /var/lib/mysql
chmod 750 /var/lib/mysql

mysql_install_db --user=mysql --datadir=/var/lib/mysql > /dev/null

log "Starting temporary mysqld for setup"
mysqld --user=mysql --datadir=/var/lib/mysql --skip-networking \
  --socket=/run/mysqld/mysqld.sock &
pid="$!"

i=0
until mysqladmin ping --socket=/run/mysqld/mysqld.sock --silent 2>/dev/null; do
  i=$((i + 1))
  [ "$i" -ge 60 ] && log "ERROR: timeout" && kill "$pid" && exit 1
  sleep 1
done

log "Running SQL setup"
mysql --protocol=socket --socket=/run/mysqld/mysqld.sock -uroot << SQL
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost');
DROP DATABASE IF EXISTS test;
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
SQL

log "Shutting down temporary mysqld"
mysqladmin --protocol=socket --socket=/run/mysqld/mysqld.sock \
  -uroot -p"${MYSQL_ROOT_PASSWORD}" shutdown
wait "$pid" || true

log "Init complete -> starting mysqld"
exec mysqld --user=mysql --datadir=/var/lib/mysql