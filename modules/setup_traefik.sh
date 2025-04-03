#!/bin/bash

# Setup Traefik reverse proxy with HTTPS

display_banner "Setting up Traefik for secure HTTPS access"

# Create Traefik configuration directory
mkdir -p "${INSTALL_DIR}/config/traefik"
mkdir -p "${INSTALL_DIR}/config/traefik/acme"
touch "${INSTALL_DIR}/config/traefik/acme/acme.json"
chmod 600 "${INSTALL_DIR}/config/traefik/acme/acme.json"

# Generate Traefik configuration file
cat > "${INSTALL_DIR}/config/traefik/traefik.toml" <<EOL
[entryPoints]
  [entryPoints.web]
    address = ":80"
    [entryPoints.web.http.redirections.entryPoint]
      to = "websecure"
      scheme = "https"
      permanent = true
  
  [entryPoints.websecure]
    address = ":443"
    [entryPoints.websecure.http.tls]
      certResolver = "letsencrypt"

[api]
  dashboard = true
  insecure = false

[providers.docker]
  endpoint = "unix:///var/run/docker.sock"
  exposedByDefault = false
  network = "web"

[providers.file]
  directory = "/etc/traefik/dynamic"
  watch = true

[certificatesResolvers.letsencrypt.acme]
  email = "${EMAIL_ADDRESS}"
  storage = "/etc/traefik/acme/acme.json"
  [certificatesResolvers.letsencrypt.acme.tlsChallenge]
EOL

# Generate Traefik dashboard config
mkdir -p "${INSTALL_DIR}/config/traefik/dynamic"
cat > "${INSTALL_DIR}/config/traefik/dynamic/dashboard.toml" <<EOL
[http.routers.traefik]
  rule = "Host(\`traefik.${DOMAIN_NAME}\`)"
  entryPoints = ["websecure"]
  service = "api@internal"
  [http.routers.traefik.middlewares]
    middlewares = ["auth"]
  
[http.middlewares.auth.basicAuth]
  users = ["admin:$(htpasswd -nb admin $(generate_password 12) | sed 's/\$/\$\$/g')"]
EOL

echo "✅ Traefik has been configured with HTTPS support."
