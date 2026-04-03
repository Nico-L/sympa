bash#!/bin/bash
set -e

# Génération de la config Postfix depuis les variables d'env
envsubst < /docker-config/postfix-main.cf.tpl > /etc/postfix/main.cf
envsubst < /docker-config/sasl_passwd.tpl     > /etc/postfix/sasl_passwd
chmod 600 /etc/postfix/sasl_passwd
postmap /etc/postfix/sasl_passwd

# Génération de la config Sympa si absente
if [ ! -f /etc/sympa/sympa/sympa.conf ]; then
    mkdir -p /etc/sympa/sympa
    cat > /etc/sympa/sympa/sympa.conf <<EOF
domain          ${SYMPA_DOMAIN}
listmaster      ${SYMPA_LISTMASTERS}
db_type         MySQL
db_host         ${SYMPA_DB_HOST}
db_port         3306
db_name         ${SYMPA_DB_NAME}
db_user         ${SYMPA_DB_USER}
db_passwd       ${SYMPA_DB_PASS}
sendmail        /usr/sbin/sendmail
wwsympa_url     https://${SYMPA_DOMAIN}/sympa
cookie          $(openssl rand -hex 16)
EOF
fi

# Démarrage des services
rsyslogd
service postfix start
service nginx start
spawn-fcgi -s /var/run/fcgiwrap.socket -u www-data -g www-data /usr/sbin/fcgiwrap

# Démarrage de Sympa
exec /usr/lib/sympa/bin/sympa_start.pl
