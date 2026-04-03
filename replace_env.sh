version: '3.8'

services:
  sympa:
    image: ghcr.io/votre-utilisateur/sympa-custom:latest
    container_name: sympa
    restart: unless-stopped
    environment:
      - SYMPA_DOMAIN=${SYMPA_DOMAIN}
      - SYMPA_LISTMASTERS=${SYMPA_LISTMASTERS}
      - SYMPA_DB_NAME=${SYMPA_DB_NAME}
      - SYMPA_DB_USER=${SYMPA_DB_USER}
      - SYMPA_DB_PASS=${SYMPA_DB_PASS}
      - MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
      - MAILJET_SMTP_HOST=${MAILJET_SMTP_HOST}
      - MAILJET_SMTP_PORT=${MAILJET_SMTP_PORT}
      - MAILJET_SMTP_USER=${MAILJET_SMTP_USER}
      - MAILJET_SMTP_PASS=${MAILJET_SMTP_PASS}
    volumes:
      - ./sympa-data/includes:/etc/sympa/includes
      - ./sympa-data/shared:/etc/sympa/shared
    depends_on:
      - db
      - postfix

  postfix:
    image: tozd/postfix:latest
    container_name: postfix
    restart: unless-stopped
    environment:
      - MYNETWORKS=172.16.0.0/12
      - SMTP_ONLY=1
    volumes:
      - ./sympa-data/shared:/etc/sympa/shared
      - ./postfix-data/main.cf:/etc/postfix/main.cf
      - ./postfix-data/sasl_passwd:/etc/postfix/sasl_passwd
      - ./postfix-data/entrypoint.sh:/entrypoint.sh
    entrypoint: /entrypoint.sh
    command: postfix start-fg
    ports:
      - "25:25"

  db:
    image: mysql:5.7
    container_name: sympa-db
    restart: unless-stopped
    environment:
      - MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
    volumes:
      - ./mysql-data:/var/lib/mysql
