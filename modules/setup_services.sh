#!/bin/bash

# Deploy all services using Docker Compose

# Process template files
echo "Processing docker-compose template..."
cp "${CONFIG_DIR}/docker-compose.yml.template" "${INSTALL_DIR}/docker-compose.yml"

# Replace variables in docker-compose.yml
sed -i "s|\${PIHOLE_PASSWORD}|${PIHOLE_PASSWORD}|g" "${INSTALL_DIR}/docker-compose.yml"
sed -i "s|\${PIHOLE_MEM_LIMIT}|${PIHOLE_MEM_LIMIT}|g" "${INSTALL_DIR}/docker-compose.yml"
sed -i "s|\${UNBOUND_MEM_LIMIT}|${UNBOUND_MEM_LIMIT}|g" "${INSTALL_DIR}/docker-compose.yml"
sed -i "s|\${HOMEASSISTANT_MEM_LIMIT}|${HOMEASSISTANT_MEM_LIMIT}|g" "${INSTALL_DIR}/docker-compose.yml"
sed -i "s|\${PROMETHEUS_MEM_LIMIT}|${PROMETHEUS_MEM_LIMIT}|g" "${INSTALL_DIR}/docker-compose.yml"
sed -i "s|\${GRAFANA_MEM_LIMIT}|${GRAFANA_MEM_LIMIT}|g" "${INSTALL_DIR}/docker-compose.yml"
sed -i "s|\${N8N_MEM_LIMIT}|${N8N_MEM_LIMIT}|g" "${INSTALL_DIR}/docker-compose.yml"
sed -i "s|\${GRAFANA_PASSWORD}|${GRAFANA_PASSWORD}|g" "${INSTALL_DIR}/docker-compose.yml"
sed -i "s|\${N8N_ENCRYPTION_KEY}|${N8N_ENCRYPTION_KEY}|g" "${INSTALL_DIR}/docker-compose.yml"
sed -i "s|\${WG_HOST}|${WG_HOST}|g" "${INSTALL_DIR}/docker-compose.yml"
sed -i "s|\${WG_PASSWORD}|${WG_PASSWORD}|g" "${INSTALL_DIR}/docker-compose.yml"
sed -i "s|\${DEFAULT_IP}|${DEFAULT_IP}|g" "${INSTALL_DIR}/docker-compose.yml"
sed -i "s|\${DOMAIN_NAME}|${DOMAIN_NAME}|g" "${INSTALL_DIR}/docker-compose.yml"
sed -i "s|\${NOTIFICATION_URL}|${NOTIFICATION_URL}|g" "${INSTALL_DIR}/docker-compose.yml"

# Copy configuration files
echo "Copying configuration files..."
mkdir -p "${INSTALL_DIR}/configs/pihole/etc-pihole" "${INSTALL_DIR}/configs/pihole/etc-dnsmasq.d"
cp -r "${CONFIG_DIR}/prometheus/"* "${INSTALL_DIR}/configs/prometheus/"
cp -r "${CONFIG_DIR}/unbound/"* "${INSTALL_DIR}/configs/unbound/"
cp -r "${CONFIG_DIR}/traefik/"* "${INSTALL_DIR}/configs/traefik/"
cp -r "${CONFIG_DIR}/homeassistant/"* "${INSTALL_DIR}/configs/homeassistant/"

# Download root hints for Unbound
echo "Downloading root hints for Unbound..."
curl -o "${INSTALL_DIR}/configs/unbound/root.hints" https://www.internic.net/domain/named.root || 
    error_exit "Failed to download root hints"

# Set permissions
chmod -R 777 "${INSTALL_DIR}/configs/unbound" || 
    error_exit "Failed to set permissions for Unbound directory"

# Pull Docker images
echo "Pulling Docker images (this may take some time)..."
cd "${INSTALL_DIR}" || error_exit "Failed to change to installation directory"
docker-compose pull || error_exit "Failed to pull Docker images"

# Start containers
echo "Starting containers..."
docker-compose up -d || error_exit "Failed to start containers"

# Verify services are running
echo "Verifying services..."
sleep 10

# Check each container is running
SERVICES=("pihole" "unbound" "homeassistant" "prometheus" "node-exporter" 
          "grafana" "n8n" "wireguard" "portainer" "heimdall" "dozzle" "watchtower")

for SERVICE in "${SERVICES[@]}"; do
    if ! docker ps | grep -q "$SERVICE"; then
        echo "WARNING: $SERVICE container may not have started properly. Check with 'docker logs $SERVICE'"
    else
        echo "✅ $SERVICE is running."
    fi
done

echo "✅ Services deployed successfully."
