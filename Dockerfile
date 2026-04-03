#triger
FROM ubuntu:22.04

ARG COOLIFY_FQDN
ARG MAILJET_API_KEY
ARG SERVICE_URL_SYMPA
ARG SERVICE_FQDN_SYMPA
ARG MYSQL_ROOT_PASSWORD
ARG SYMPA_DOMAIN
ARG SYMPA_LISTMASTERS
ARG MYSQL_DATABASE
ARG MYSQL_USER
ARG MYSQL_PASSWORD
ARG MAILJET_SECRET_KEY
ARG COOLIFY_BUILD_SECRETS_HASH

ENV DEBIAN_FRONTEND=noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN=true

RUN apt-get update && \
    apt-get install -y software-properties-common debconf-utils && \
    add-apt-repository universe && \
    apt-get update

RUN echo "postfix postfix/mailname string localhost" | debconf-set-selections && \
    echo "postfix postfix/main_mailer_type select No configuration" | debconf-set-selections

RUN mkdir -p /etc/sympa/sympa && \
    echo "domain localhost.localdomain" > /etc/sympa/sympa/sympa.conf && \
    echo "listmaster listmaster@localhost.localdomain" >> /etc/sympa/sympa/sympa.conf && \
    echo "db_type SQLite" >> /etc/sympa/sympa/sympa.conf && \
    echo "db_name /var/lib/sympa/sympa.sqlite" >> /etc/sympa/sympa/sympa.conf

RUN apt-get install -y --no-install-recommends \
        sympa \
        postfix \
        postfix-pcre \
        libsasl2-modules \
        libsasl2-2 \
        ca-certificates \
        nginx \
        fcgiwrap \
        gettext-base \
        procps \
        rsyslog \
        openssl && \
    rm -rf /var/lib/apt/lists/*

COPY config/ /docker-config/

RUN printf '#!/bin/bash\nset -e\n\n' > /entrypoint.sh && \
    echo '# Supprimer les sockets/pid qui trainent au redémarrage' >> /entrypoint.sh && \
    echo 'rm -f /run/fcgiwrap.socket /run/rsyslogd.pid' >> /entrypoint.sh && \
    echo '' >> /entrypoint.sh && \
    echo '# Désactiver imklog qui nécessite /proc/kmsg (interdit en conteneur)' >> /entrypoint.sh && \
    echo 'sed -i "/imklog/d" /etc/rsyslog.conf' >> /entrypoint.sh && \
    echo 'sed -i "/imklog/d" /etc/rsyslog.d/*.conf 2>/dev/null || true' >> /entrypoint.sh && \
    echo 'rsyslogd' >> /entrypoint.sh && \
    echo 'sleep 1' >> /entrypoint.sh && \
    echo '' >> /entrypoint.sh && \
    echo 'envsubst < /docker-config/postfix-main.cf.tpl > /etc/postfix/main.cf' >> /entrypoint.sh && \
    echo 'envsubst < /docker-config/sasl_passwd.tpl > /etc/postfix/sasl_passwd' >> /entrypoint.sh && \
    echo 'chmod 600 /etc/postfix/sasl_passwd' >> /entrypoint.sh && \
    echo 'postmap /etc/postfix/sasl_passwd' >> /entrypoint.sh && \
    echo '' >> /entrypoint.sh && \
    echo 'mkdir -p /etc/sympa/sympa' >> /entrypoint.sh && \
    echo 'echo "domain ${SYMPA_DOMAIN}" > /etc/sympa/sympa/sympa.conf' >> /entrypoint.sh && \
    echo 'echo "listmaster ${SYMPA_LISTMASTERS}" >> /etc/sympa/sympa/sympa.conf' >> /entrypoint.sh && \
    echo 'echo "db_type MySQL" >> /etc/sympa/sympa/sympa.conf' >> /entrypoint.sh && \
    echo 'echo "db_host ${SYMPA_DB_HOST}" >> /etc/sympa/sympa/sympa.conf' >> /entrypoint.sh && \
    echo 'echo "db_port 3306" >> /etc/sympa/sympa/sympa.conf' >> /entrypoint.sh && \
    echo 'echo "db_name ${SYMPA_DB_NAME}" >> /etc/sympa/sympa/sympa.conf' >> /entrypoint.sh && \
    echo 'echo "db_user ${SYMPA_DB_USER}" >> /etc/sympa/sympa/sympa.conf' >> /entrypoint.sh && \
    echo 'echo "db_passwd ${SYMPA_DB_PASS}" >> /etc/sympa/sympa/sympa.conf' >> /entrypoint.sh && \
    echo 'echo "sendmail /usr/sbin/sendmail" >> /etc/sympa/sympa/sympa.conf' >> /entrypoint.sh && \
    echo 'echo "wwsympa_url https://${SYMPA_DOMAIN}/sympa" >> /etc/sympa/sympa/sympa.conf' >> /entrypoint.sh && \
    echo 'echo "cookie $(openssl rand -hex 16)" >> /etc/sympa/sympa/sympa.conf' >> /entrypoint.sh && \
    echo '' >> /entrypoint.sh && \
    echo '# Config nginx' >> /entrypoint.sh && \
    echo 'cat > /etc/nginx/sites-available/sympa << NGINXEOF' >> /entrypoint.sh && \
    echo 'server {' >> /entrypoint.sh && \
    echo '    listen 80;' >> /entrypoint.sh && \
    echo '    server_name _;' >> /entrypoint.sh && \
    echo '    location /sympa {' >> /entrypoint.sh && \
    echo '        include /etc/nginx/fastcgi_params;' >> /entrypoint.sh && \
    echo '        fastcgi_pass unix:/run/fcgiwrap.socket;' >> /entrypoint.sh && \
    echo '        fastcgi_param SCRIPT_FILENAME /usr/lib/cgi-bin/sympa/wwsympa.fcgi;' >> /entrypoint.sh && \
    echo '        fastcgi_param SCRIPT_NAME /sympa;' >> /entrypoint.sh && \
    echo '        fastcgi_param DOCUMENT_ROOT /usr/share/sympa/static_content;' >> /entrypoint.sh && \
    echo '    }' >> /entrypoint.sh && \
    echo '    location /static-sympa {' >> /entrypoint.sh && \
    echo '        alias /usr/share/sympa/static_content;' >> /entrypoint.sh && \
    echo '    }' >> /entrypoint.sh && \
    echo '}' >> /entrypoint.sh && \
    echo 'NGINXEOF' >> /entrypoint.sh && \
    echo 'ln -sf /etc/nginx/sites-available/sympa /etc/nginx/sites-enabled/sympa' >> /entrypoint.sh && \
    echo 'rm -f /etc/nginx/sites-enabled/default' >> /entrypoint.sh && \
    echo '' >> /entrypoint.sh && \
    echo '# Démarrer fcgiwrap sur socket unix' >> /entrypoint.sh && \
    echo 'fcgiwrap -s unix:/run/fcgiwrap.socket &' >> /entrypoint.sh && \
    echo 'sleep 1' >> /entrypoint.sh && \
    echo 'chown www-data:www-data /run/fcgiwrap.socket' >> /entrypoint.sh && \
    echo '' >> /entrypoint.sh && \
    echo 'service postfix start' >> /entrypoint.sh && \
    echo 'service nginx start' >> /entrypoint.sh && \
    echo '' >> /entrypoint.sh && \
    echo 'exec /usr/lib/sympa/bin/sympa_msg.pl --debug 2>&1' >> /entrypoint.sh && \
    chmod +x /entrypoint.sh

EXPOSE 80 25

VOLUME ["/etc/sympa", "/var/lib/sympa", "/var/spool/sympa", "/var/spool/postfix"]

ENTRYPOINT ["/entrypoint.sh"]
