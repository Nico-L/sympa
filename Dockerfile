# Dockerfile
FROM debian:stable

# Install dependencies
RUN apt-get update && apt-get install -y \
    wget gnupg lsb-release curl sudo mysql-client \
    postfix sympa fcgiwrap nginx supervisor && \
    rm -rf /var/lib/apt/lists/*

# Copy template files
COPY sympa-config/ /tmp/sympa-templates/
COPY postfix/ /tmp/postfix-templates/
COPY sympa-entrypoint/entrypoint-sympa.sh /entrypoint-sympa.sh
RUN chmod +x /entrypoint-sympa.sh

# Script to replace env vars in templates at runtime
COPY replace_env.sh /replace_env.sh
RUN chmod +x /replace_env.sh

ENTRYPOINT ["/replace_env.sh"]
CMD ["supervisord", "-n"]
