myhostname = ${SYMPA_DOMAIN}
mydomain = ${SYMPA_DOMAIN}
myorigin = ${SYMPA_DOMAIN}
inet_interfaces = all
mydestination = localhost
mynetworks = 127.0.0.0/8

# Relay Mailjet
relayhost = [in-v3.mailjet.com]:587
smtp_sasl_auth_enable = yes
smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
smtp_sasl_security_options = noanonymous
smtp_tls_security_level = encrypt
smtp_tls_CAfile = /etc/ssl/certs/ca-certificates.crt

# Sympa aliases
alias_maps = hash:/etc/aliases, hash:/etc/sympa/aliases
alias_database = hash:/etc/aliases
transport_maps = regexp:/etc/sympa/transport_regexp
sympa_destination_recipient_limit = 1
sympabounce_destination_recipient_limit = 1

mailbox_size_limit = 0
recipient_delimiter = +
