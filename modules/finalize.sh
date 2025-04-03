#!/bin/bash

# Finalize setup and create documentation

# Create README file
echo "Creating documentation..."

cat > "${INSTALL_DIR}/README.md" <<EOL
# Homelab Setup Documentation

## Overview
This document provides information about your homelab setup, including access information
and basic maintenance tasks.

## Access Information

Access your services at the following URLs (replace \`${DEFAULT_IP}\` with your system's IP address if needed):

- **Pi-hole**: http://${DEFAULT_IP}/admin (password: ${PIHOLE_PASSWORD})
- **Home Assistant**: http://${DEFAULT_IP}:8123
- **Prometheus**: http://${DEFAULT_IP}:9090
- **Grafana**: http://${DEFAULT_IP}:3000 (login: admin/${GRAFANA_PASSWORD})
- **n8n**: http://${DEFAULT_IP}:5678
- **WireGuard VPN**: http://${DEFAULT_IP}:51821 (password: ${WG_PASSWORD})
- **Portainer**: http://${DEFAULT_IP}:9000
- **Heimdall**: http://${DEFAULT_IP}:8080
- **Dozzle**: http://${DEFAULT_IP}:8081

## Maintenance Tasks

### Updating Containers
Watchtower is configured in monitor-only mode. When notified about available updates,
you can apply them through Portainer or run:

\`\`\`bash
cd ${INSTALL_DIR}
docker-compose pull
docker-compose up -d
\`\`\`

### Backup and Restore
Run a manual backup:
\`\`\`bash
${INSTALL_DIR}/backup.sh
\`\`\`

Backups are stored in \`${INSTALL_DIR}/backups\` and are automatically rotated.

### Adding New Services
Edit the \`docker-compose.yml\` file and run:
\`\`\`bash
cd ${INSTALL_DIR}
docker-compose up -d
\`\`\`

## Resource Usage
Your homelab is configured with the ${RESOURCE_PROFILE} resource profile.
Monitor system resources through Grafana or with \`docker stats\`.

## Security Notes
- Change default passwords regularly
- Keep all containers updated
- Configure a firewall to restrict access to sensitive ports
- Consider setting up HTTPS for all services

EOL

# Create quick reference card
cat > "${INSTALL_DIR}/quick_reference.md" <<EOL
# Homelab Quick Reference

## Service URLs
- Pi-hole: http://${DEFAULT_IP}/admin
- Home Assistant: http://${DEFAULT_IP}:8123
- Grafana: http://${DEFAULT_IP}:3000
- Portainer: http://${DEFAULT_IP}:9000
- Heimdall: http://${DEFAULT_IP}:8080

## Common Commands
- Start all: \`cd ${INSTALL_DIR} && docker-compose up -d\`
- Stop all: \`cd ${INSTALL_DIR} && docker-compose down\`
- Restart service: \`cd ${INSTALL_DIR} && docker-compose restart SERVICE_NAME\`
- View logs: \`cd ${INSTALL_DIR} && docker-compose logs -f SERVICE_NAME\`
- Backup: \`${INSTALL_DIR}/backup.sh\`

## Passwords
- Pi-hole: ${PIHOLE_PASSWORD}
- Grafana: ${GRAFANA_PASSWORD}
- WireGuard: ${WG_PASSWORD}
- n8n encryption key: ${N8N_ENCRYPTION_KEY}
EOL

# Set permissions on data directories
echo "Setting file permissions..."
chmod 600 "${INSTALL_DIR}/quick_reference.md"

echo "✅ Setup finalized. Documentation created at ${INSTALL_DIR}/README.md"
