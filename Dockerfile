# Utilise une image Debian stable
FROM debian:stable

# Installe les dépendances de base
RUN apt-get update && apt-get install -y \
    wget \
    gnupg \
    lsb-release \
    curl \
    sudo \
    apt-transport-https \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Télécharge et installe la clé GPG pour les dépôts Debian
RUN mkdir -p /etc/apt/trusted.gpg.d && \
    wget -qO- https://ftp-master.debian.org/keys/archive-key-$(lsb_release -sc).asc | gpg --dearmor -o /etc/apt/trusted.gpg.d/debian-archive-$(lsb_release -sc).gpg

# Ajoute les dépôts Debian officiels
RUN echo "deb http://deb.debian.org/debian $(lsb_release -sc) main" > /etc/apt/sources.list && \
    echo "deb http://deb.debian.org/debian $(lsb_release -sc)-updates main" >> /etc/apt/sources.list && \
    echo "deb http://deb.debian.org/debian $(lsb_release -sc)-backports main" >> /etc/apt/sources.list && \
    apt-get update

# Installe les dépendances pour Sympa
RUN apt-get update && apt-get install -y \
    mysql-client \
    postfix \
    sympa \
    fcgiwrap \
    nginx \
    supervisor \
    gettext \
    && rm -rf /var/lib/apt/lists/*

# Copie les templates et scripts
COPY sympa-config/ /tmp/sympa-templates/
COPY postfix/ /tmp/postfix-templates/
COPY sympa-entrypoint/entrypoint-sympa.sh /entrypoint-sympa.sh
COPY replace_env.sh /replace_env.sh
RUN chmod +x /entrypoint-sympa.sh /replace_env.sh

ENTRYPOINT ["/replace_env.sh"]
CMD ["supervisord", "-n"]
