# Utilise une image Debian stable avec les dépôts Sympa
FROM debian:stable

# Installe les dépendances nécessaires pour ajouter les dépôts Sympa
RUN apt-get update && apt-get install -y \
    wget \
    gnupg \
    lsb-release \
    curl \
    sudo \
    apt-transport-https \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Ajoute le dépôt officiel de Sympa (pour Debian)
RUN echo "deb http://ftp.debian.org/debian $(lsb_release -sc) main" > /etc/apt/sources.list.d/debian.list && \
    echo "deb http://ftp.debian.org/debian $(lsb_release -sc)-backports main" >> /etc/apt/sources.list.d/debian.list && \
    wget -O /etc/apt/trusted.gpg.d/debian-archive-keyring.gpg https://ftp-master.debian.org/keys/archive-key-$(lsb_release -sc).asc && \
    apt-get update

# Installe les dépendances pour Sympa, Postfix, etc.
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
