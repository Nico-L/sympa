#!/bin/bash
# sympa-entrypoint/entrypoint-sympa.sh

set -e

# Wait for MySQL
until mysql -h db -u root -p"$MYSQL_ROOT_PASSWORD" -e "SELECT 1"; do
  >&2 echo "MySQL is unavailable - sleeping"
  sleep 1
done

# Initialize database
mysql -h db -u root -p"$MYSQL_ROOT_PASSWORD" < /tmp/init-db.sql

# Start Sympa
exec "$@"
