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

RUN apt-get update && apt-get install -y --no-install-recommends \
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
    openssl \
    && rm -rf /var/lib/apt/lists/*

COPY config/ /docker-config/
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 80 25

VOLUME ["/etc/sympa", "/var/lib/sympa", "/var/spool/sympa", "/var/spool/postfix"]

ENTRYPOINT ["/entrypoint.sh"]
