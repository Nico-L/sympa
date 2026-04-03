FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

# Installation de Sympa + Postfix + Nginx + dépendances
RUN apt-get update && apt-get install -y --no-install-recommends \
    sympa \
    postfix \
    postfix-pcre \
    libsasl2-modules \
    libsasl2-2 \
    sasl2-bin \
    ca-certificates \
    nginx \
    fcgiwrap \
    spawn-fcgi \
    gettext-base \
    procps \
    rsyslog \
    && rm -rf /var/lib/apt/lists/*

# Dossier de scripts
COPY config/ /docker-config/
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 80 25

VOLUME ["/etc/sympa", "/var/lib/sympa", "/var/spool/sympa", "/var/spool/postfix"]

ENTRYPOINT ["/entrypoint.sh"]
