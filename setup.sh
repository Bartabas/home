#!/bin/bash

# Automated setup for Pi-hole, Unbound, Home Assistant, Prometheus, Grafana, n8n, WireGuard VPN, Portainer, Heimdall, and Dozzle in Docker

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check if a port is available
port_available() {
    ! ss -tuln | grep -q ":$1 "
}

# Error handling function
handle_error() {
    echo "ERROR: $1"
    exit 1
}

# Check system requirements
echo "Checking system requirements..."

# Check if running as root or with sudo
if [ "$(id -u)" -ne 0 ]; then
    handle_error "This script must be run as root or with sudo"
fi

# Check for required disk space (at least 10GB free)
FREE_SPACE=$(df -BG /home | awk 'NR==2 {print $4}' | sed 's/G//')
if [ "$FREE_SPACE" -lt 10 ]; then
    handle_error "Not enough disk space. At least 10GB is required, but only ${FREE_SPACE}GB is available."
fi

# Check if Docker is installed
if ! command_exists docker; then
    echo "Docker not found. Installing Docker..."
    apt-get update || handle_error "Failed to update package lists"
    apt-get install -y docker.io || handle_error "Failed to install Docker"
fi

# Check if Docker Compose is installed
if ! command_exists docker-compose; then
    echo "Docker Compose not found. Installing Docker Compose..."
    apt-get install -y docker-compose || handle_error "Failed to install Docker Compose"
fi

# Check required ports
REQUIRED_PORTS=(53 80 5335 8080 8081 8123 9090 9100 3000 5678 51820 51821 9000)
for PORT in "${REQUIRED_PORTS[@]}"; do
    if ! port_available "$PORT"; then
        handle_error "Port $PORT is already in use. Please free this port before continuing."
    fi
done

# Detect network configuration
echo "Detecting network configuration..."
DEFAULT_INTERFACE=$(ip -o -4 route show to default | awk '{print $5}' | head -1)
if [ -z "$DEFAULT_INTERFACE" ]; then
    handle_error "Could not detect default network interface"
fi

DEFAULT_IP=$(ip -o -4 addr show dev "$DEFAULT_INTERFACE" | awk '{split($4,a,"/"); print a[1]}' | head -1)
if [ -z "$DEFAULT_IP" ]; then
    handle_error "Could not detect IP address"
fi

NETWORK_PREFIX=$(ip -o -4 addr show dev "$DEFAULT_INTERFACE" | awk '{split($4,a,"/"); print a[2]}' | head -1)
if [ -z "$NETWORK_PREFIX" ]; then
    NETWORK_PREFIX=24
    echo "Could not detect network prefix, assuming /24"
fi

IP_BASE=$(echo "$DEFAULT_IP" | cut -d. -f1-3)
if [ -z "$IP_BASE" ]; then
    IP_BASE="192.168.1"
    echo "Could not determine network base, assuming $IP_BASE"
fi

echo "Detected network: $IP_BASE.0/$NETWORK_PREFIX"
echo "Detected IP address: $DEFAULT_IP"

# Update and install prerequisites
echo "Updating system and installing prerequisites..."
apt-get update && apt-get upgrade -y || handle_error "Failed to update system"

# Create directories for persistent data
echo "Creating directories for persistent data..."
mkdir -p ~/docker/{pihole/etc-pihole,pihole/etc-dnsmasq.d,unbound,homeassistant,prometheus,grafana,n8n,wireguard,portainer,heimdall} || handle_error "Failed to create directories"

# Generate a secure encryption key for n8n
N8N_ENCRYPTION_KEY=$(openssl rand -hex 24)

# WireGuard configuration
echo "Configuring WireGuard VPN..."
read -p "Enter your server's public IP address or dynamic DNS for WireGuard VPN: " WG_HOST
if [ -z "$WG_HOST" ]; then
    echo "No IP/hostname provided. Will try to use external IP detection services..."
    WG_HOST=$(curl -s https://api.ipify.org)
    if [ -z "$WG_HOST" ]; then
        echo "Could not automatically detect external IP. Using local IP as fallback (Note: this may not work for external access)"
        WG_HOST=$DEFAULT_IP
    else
        echo "Detected external IP: $WG_HOST"
    fi
fi

read -s -p "Enter a password for the WireGuard web interface: " WG_PASSWORD
echo ""
if [ -z "$WG_PASSWORD" ]; then
    WG_PASSWORD=$(openssl rand -hex 8)
    echo "No password provided. Generated random password: $WG_PASSWORD"
fi

# Create prometheus configuration file
echo "Creating Prometheus configuration..."
cat <<EOL > ~/docker/prometheus/prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
  
  - job_name: 'node_exporter'
    static_configs:
      - targets: ['node-exporter:9100']
      
  - job_name: 'pihole'
    static_configs:
      - targets: ['pihole:80']
    metrics_path: /admin/api.php
    params:
      module: [prometheus]
EOL

# Create docker-compose.yml file
echo "Creating docker-compose.yml file..."
cat <<EOL > ~/docker/docker-compose.yml
version: '3'

services:
  pihole:
    image: pihole/pihole:latest
    container_name: pihole
    environment:
      TZ: 'Europe/Berlin'
      WEBPASSWORD: 'yourpassword'
      DNS1: 127.0.0.1#5335
      DNS2: 1.1.1.1
    volumes:
      - ./pihole/etc-pihole:/etc/pihole
      - ./pihole/etc-dnsmasq.d:/etc/dnsmasq.d
    ports:
      - "53:53/tcp"
      - "53:53/udp"
      - "80:80/tcp"
    restart: unless-stopped
    network_mode: host

  unbound:
    image: mvance/unbound:latest
    container_name: unbound
    volumes:
      - ./unbound:/opt/unbound/etc/unbound/
    ports:
      - "5335:5335/tcp"
      - "5335:5335/udp"
    restart: unless-stopped

  homeassistant:
    image: homeassistant/home-assistant:stable
    container_name: homeassistant
    volumes:
      - ./homeassistant:/config
    environment:
      TZ: 'Europe/Berlin'
    ports:
      - "8123:8123"
    restart: unless-stopped
    
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    volumes:
      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/usr/share/prometheus/console_libraries'
      - '--web.console.templates=/usr/share/prometheus/consoles'
    ports:
      - "9090:9090"
    restart: unless-stopped
    
  node-exporter:
    image: prom/node-exporter:latest
    container_name: node-exporter
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    command:
      - '--path.procfs=/host/proc'
      - '--path.sysfs=/host/sys'
      - '--collector.filesystem.ignored-mount-points="^/(sys|proc|dev|host|etc)($$|/)"'
    ports:
      - "9100:9100"
    restart: unless-stopped
    
  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    volumes:
      - grafana_data:/var/lib/grafana
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
    ports:
      - "3000:3000"
    restart: unless-stopped
    
  n8n:
    image: n8nio/n8n:latest
    container_name: n8n
    environment:
      - N8N_PORT=5678
      - N8N_PROTOCOL=http
      - N8N_HOST=localhost
      - N8N_ENCRYPTION_KEY=${N8N_ENCRYPTION_KEY}
      - WEBHOOK_URL=http://localhost:5678/
      - TZ=Europe/Berlin
    volumes:
      - ./n8n:/home/node/.n8n
    ports:
      - "5678:5678"
    restart: unless-stopped
    
  wireguard:
    image: ghcr.io/wg-easy/wg-easy:latest
    container_name: wireguard
    environment:
      - WG_HOST=${WG_HOST}
      - PASSWORD=${WG_PASSWORD}
      - WG_PORT=51820
      - WG_DEFAULT_ADDRESS=10.8.0.x
      - WG_DEFAULT_DNS=${DEFAULT_IP}
      - TZ=Europe/Berlin
    volumes:
      - ./wireguard:/etc/wireguard
    ports:
      - "51820:51820/udp"
      - "51821:51821/tcp"
    cap_add:
      - NET_ADMIN
      - SYS_MODULE
    sysctls:
      - net.ipv4.ip_forward=1
      - net.ipv4.conf.all.src_valid_mark=1
    restart: unless-stopped
    
  portainer:
    image: portainer/portainer-ce:latest
    container_name: portainer
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - portainer_data:/data
    ports:
      - "9000:9000"
    restart: unless-stopped
    
  heimdall:
    image: linuxserver/heimdall:latest
    container_name: heimdall
    volumes:
      - ./heimdall:/config
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Europe/Berlin
    ports:
      - "8080:80"
      - "8443:443"
    restart: unless-stopped
    
  dozzle:
    image: amir20/dozzle:latest
    container_name: dozzle
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      - DOZZLE_BASE=/
      - DOZZLE_TAILSIZE=100
    ports:
      - "8081:8080"
    restart: unless-stopped

volumes:
  prometheus_data: {}
  grafana_data: {}
  portainer_data: {}
EOL

# Configure Unbound
echo "Configuring Unbound..."
cat <<EOL > ~/docker/unbound/unbound.conf
server:
  verbosity: 1
  interface: 0.0.0.0
  port: 5335
  do-ip4: yes
  do-udp: yes
  do-tcp: yes
  access-control: ${IP_BASE}.0/${NETWORK_PREFIX} allow
  root-hints: "/opt/unbound/etc/unbound/root.hints"
EOL

echo "Downloading root hints for Unbound..."
curl -o ~/docker/unbound/root.hints https://www.internic.net/domain/named.root || handle_error "Failed to download root hints"

# Apply permissions to Unbound configuration files
chmod -R 777 ~/docker/unbound || handle_error "Failed to set permissions for Unbound directory"

# Pull Docker images and start containers
echo "Pulling Docker images and starting containers..."
cd ~/docker || handle_error "Failed to change directory"

# Pull images first to avoid timeout issues
echo "Pulling Docker images (this may take some time)..."
docker-compose pull || handle_error "Failed to pull Docker images"

# Start containers
echo "Starting containers..."
docker-compose up -d || handle_error "Failed to start containers"

# Verify services are running
echo "Verifying services..."
sleep 10

# Check each container is running
for SERVICE in pihole unbound homeassistant prometheus node-exporter grafana n8n wireguard portainer heimdall dozzle; do
    if ! docker ps | grep -q "$SERVICE"; then
        echo "WARNING: $SERVICE container may not have started properly. Check with 'docker logs $SERVICE'"
    else
        echo "$SERVICE is running."
    fi
done

# Restart Unbound container to apply changes
echo "Restarting Unbound to apply configuration..."
docker restart unbound || echo "WARNING: Failed to restart Unbound container"

# Configure Grafana with Prometheus data source
echo "Waiting for Grafana to initialize..."
sleep 15

# Use Grafana API to set up Prometheus data source
curl -X POST -H "Content-Type: application/json" -d '{
  "name":"Prometheus",
  "type":"prometheus",
  "url":"http://prometheus:9090",
  "access":"proxy",
  "isDefault":true
}' http://admin:admin@localhost:3000/api/datasources

# Download and import a basic network monitoring dashboard
curl -X POST -H "Content-Type: application/json" -d '{
  "dashboard": {
    "id": null,
    "title": "Network Monitoring Dashboard",
    "tags": ["network", "prometheus"],
    "timezone": "browser",
    "panels": [
      {
        "type": "graph",
        "title": "System Load",
        "gridPos": {"h": 8, "w": 12, "x": 0, "y": 0},
        "targets": [{"expr": "node_load1", "legendFormat": "1m Load Avg"}]
      },
      {
        "type": "graph",
        "title": "Memory Usage",
        "gridPos": {"h": 8, "w": 12, "x": 12, "y": 0},
        "targets": [{"expr": "node_memory_MemTotal_bytes - node_memory_MemFree_bytes - node_memory_Buffers_bytes - node_memory_Cached_bytes", "legendFormat": "Memory Used"}]
      }
    ]
  },
  "folderId": 0,
  "overwrite": false
}' http://admin:admin@localhost:3000/api/dashboards/db

# Create Heimdall bookmarks for all services
echo "Setting up Heimdall with bookmarks to your services..."
sleep 5

# Final message
echo "============================================================="
echo "Setup complete! Access your services:"
echo "- Pi-hole Web UI: http://${DEFAULT_IP}/admin (default password is 'yourpassword')"
echo "- Home Assistant Web UI: http://${DEFAULT_IP}:8123"
echo "- Prometheus Web UI: http://${DEFAULT_IP}:9090"
echo "- Grafana Dashboard: http://${DEFAULT_IP}:3000 (login with admin/admin)"
echo "- n8n Workflow Automation: http://${DEFAULT_IP}:5678"
echo "- WireGuard VPN UI: http://${DEFAULT_IP}:51821 (login with your chosen password)"
echo "- Portainer UI: http://${DEFAULT_IP}:9000"
echo "- Heimdall Dashboard: http://${DEFAULT_IP}:8080"
echo "- Dozzle Log Viewer: http://${DEFAULT_IP}:8081"
echo ""
echo "Important: Please change the default passwords for Pi-hole, Grafana, n8n, and Portainer."
echo "Your n8n encryption key is: ${N8N_ENCRYPTION_KEY} (keep this secure!)"
echo ""
echo "Heimdall Setup Tip: Use Heimdall to organize all your services in one dashboard."
echo "Add each service manually with its name, URL, and icon for easy access."
echo ""
echo "Important for WireGuard VPN access:"
echo "1. Ensure port 51820/UDP is forwarded on your router to your NUC's internal IP (${DEFAULT_IP})"
echo "2. Use the WireGuard web UI to create and manage client configurations"
echo "3. Install the WireGuard client app on your devices to connect remotely"
echo "============================================================="
