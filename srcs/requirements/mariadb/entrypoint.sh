#!/bin/sh
set -eu

log() { printf "\n[mariadb-entrypoint] %s\n" "$*"; }

: "${MYSQL_DATABASE:?MYSQL_DATABASE is required}"
: "${MYSQL_USER:?MYSQL_USER is required}"

DB_ROOT_SECRET="/run/secrets/db_root_password"
DB_USER_SECRET="/run/secrets/db_password"

[ -f "$DB_ROOT_SECRET" ] || { log "ERROR: missing secret $DB_ROOT_SECRET"; exit 1; }
[ -f "$DB_USER_SECRET" ] || { log "ERROR: missing secret $DB_USER_SECRET"; exit 1; }

MYSQL_ROOT_PASSWORD="$(cat "$DB_ROOT_SECRET")"
MYSQL_PASSWORD="$(cat "$DB_USER_SECRET")"

[ -n "$MYSQL_ROOT_PASSWORD" ] || { log "ERROR: db_root_password is empty"; exit 1; }
[ -n "$MYSQL_PASSWORD" ] || { log "ERROR: db_password is empty"; exit 1; }

export MYSQL_ROOT_PASSWORD MYSQL_PASSWORD

# Always fix perms (this solves ddl_recovery.log Errcode 13 on existing volumes)
mkdir -p /run/mysqld /var/lib/mysql
chown -R mysql:mysql /run/mysqld /var/lib/mysql || true
chmod 755 /run/mysqld || true
chmod 750 /var/lib/mysql || true

# Quick permission sanity check
if ! su -s /bin/sh mysql -c "touch /var/lib/mysql/.perm_test" 2>/dev/null; then
  log "ERROR: mysql user cannot write to /var/lib/mysql (bind-mount permissions)."
  log "Fix on host: mkdir -p ~/data/mariadb && sudo chown -R \$(id -u):\$(id -g) ~/data/mariadb"
  exit 1
fi
rm -f /var/lib/mysql/.perm_test || true

# If already initialized, still enforce grants (host '%' fix) then start normally
if [ -d "/var/lib/mysql/mysql" ]; then
  log "Detected existing MariaDB data directory -> ensuring user grants then starting"

  mysqld --user=mysql --datadir=/var/lib/mysql --skip-networking --socket=/run/mysqld/mysqld.sock &
  pid="$!"

  i=0
  until mysqladmin ping --socket=/run/mysqld/mysqld.sock --silent; do
    i=$((i + 1))
    [ "$i" -lt 60 ] || { log "ERROR: MariaDB did not start in time"; kill "$pid" 2>/dev/null || true; exit 1; }
    sleep 1
  done

  mysql --protocol=socket --socket=/run/mysqld/mysqld.sock -uroot -p"${MYSQL_ROOT_PASSWORD}" <<SQL
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;

CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
ALTER USER '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
SQL

  mysqladmin --protocol=socket --socket=/run/mysqld/mysqld.sock -uroot -p"${MYSQL_ROOT_PASSWORD}" shutdown
  wait "$pid" || true

  exec mysqld --user=mysql --datadir=/var/lib/mysql
fi

log "Empty data directory detected -> first-time initialization"

chown -R mysql:mysql /var/lib/mysql
chmod 750 /var/lib/mysql

mysql_install_db --user=mysql --datadir=/var/lib/mysql > /dev/null

log "Starting temporary mysqld for init"
mysqld --user=mysql --datadir=/var/lib/mysql --skip-networking --socket=/run/mysqld/mysqld.sock &
pid="$!"

i=0
until mysqladmin ping --socket=/run/mysqld/mysqld.sock --silent; do
  i=$((i + 1))
  [ "$i" -lt 60 ] || { log "ERROR: MariaDB did not start in time"; kill "$pid" 2>/dev/null || true; exit 1; }
  sleep 1
done

log "Running first-time SQL setup"
mysql --protocol=socket --socket=/run/mysqld/mysqld.sock -uroot <<SQL
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost');
DROP DATABASE IF EXISTS test;
FLUSH PRIVILEGES;

CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;

CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
SQL

log "Shutting down temporary mysqld"
mysqladmin --protocol=socket --socket=/run/mysqld/mysqld.sock -uroot -p"${MYSQL_ROOT_PASSWORD}" shutdown
wait "$pid" || true

log "Initialization complete -> starting mysqld normally"
exec mysqld --user=mysql --datadir=/var/lib/mysql