#!/bin/bash

# Setup service configurations with an interactive wizard

display_banner "Service Configuration Wizard"

# Create configuration directories
mkdir -p "${INSTALL_DIR}/config"
for service in pihole unbound homeassistant prometheus grafana n8n traefik wireguard portainer heimdall dozzle; do
    mkdir -p "${INSTALL_DIR}/config/$service"
done

# Domain name and TLS configuration
read -p "Enter your domain name for accessing services (e.g., home.example.com): " DOMAIN_NAME
if [ -z "$DOMAIN_NAME" ]; then
    DOMAIN_NAME="homelab.local"
    echo "No domain provided. Using default: $DOMAIN_NAME"
fi
save_config "DOMAIN_NAME" "$DOMAIN_NAME"

# Email for Let's Encrypt
read -p "Enter your email address for Let's Encrypt certificates: " EMAIL_ADDRESS
if [ -z "$EMAIL_ADDRESS" ]; then
    echo "No email provided. Will use self-signed certificates."
    USE_LETSENCRYPT=false
else
    USE_LETSENCRYPT=true
fi
save_config "EMAIL_ADDRESS" "$EMAIL_ADDRESS"
save_config "USE_LETSENCRYPT" "$USE_LETSENCRYPT"

# Pi-hole configuration
echo "Configuring Pi-hole..."
read -p "Enter Pi-hole admin password [auto-generate]: " PIHOLE_PASSWORD
if [ -z "$PIHOLE_PASSWORD" ]; then
    PIHOLE_PASSWORD=$(generate_password 12)
    echo "Generated Pi-hole password: $PIHOLE_PASSWORD"
fi
save_config "PIHOLE_PASSWORD" "$PIHOLE_PASSWORD"

# WireGuard configuration
echo "Configuring WireGuard VPN..."
read -p "Enter WireGuard admin password [auto-generate]: " WG_PASSWORD
if [ -z "$WG_PASSWORD" ]; then
    WG_PASSWORD=$(generate_password 12)
    echo "Generated WireGuard password: $WG_PASSWORD"
fi

# Detect external IP
EXTERNAL_IP=$(curl -s https://api.ipify.org)
read -p "Enter your public IP or hostname for WireGuard VPN [$EXTERNAL_IP]: " WG_HOST
if [ -z "$WG_HOST" ]; then
    WG_HOST=$EXTERNAL_IP
fi
save_config "WG_PASSWORD" "$WG_PASSWORD"
save_config "WG_HOST" "$WG_HOST"

# Grafana admin password
read -p "Enter Grafana admin password [auto-generate]: " GRAFANA_PASSWORD
if [ -z "$GRAFANA_PASSWORD" ]; then
    GRAFANA_PASSWORD=$(generate_password 12)
    echo "Generated Grafana password: $GRAFANA_PASSWORD"
fi
save_config "GRAFANA_PASSWORD" "$GRAFANA_PASSWORD"

# Portainer admin password
read -p "Enter Portainer admin password [auto-generate]: " PORTAINER_PASSWORD
if [ -z "$PORTAINER_PASSWORD" ]; then
    PORTAINER_PASSWORD=$(generate_password 12)
    echo "Generated Portainer password: $PORTAINER_PASSWORD"
fi
save_config "PORTAINER_PASSWORD" "$PORTAINER_PASSWORD"

# n8n encryption key
N8N_ENCRYPTION_KEY=$(openssl rand -hex 24)
save_config "N8N_ENCRYPTION_KEY" "$N8N_ENCRYPTION_KEY"

# Backup configuration
echo "Configuring backup schedule..."
read -p "Backup retention period in days [14]: " BACKUP_RETENTION
if [ -z "$BACKUP_RETENTION" ]; then
    BACKUP_RETENTION=14
fi
save_config "BACKUP_RETENTION" "$BACKUP_RETENTION"

read -p "Backup time (24h format, e.g. 02:00) [03:30]: " BACKUP_TIME
if [ -z "$BACKUP_TIME" ]; then
    BACKUP_TIME="03:30"
fi
save_config "BACKUP_TIME" "$BACKUP_TIME"

# Watchtower notification configuration
echo "Configuring Watchtower notifications..."
echo "Select notification method:"
echo "1) Email"
echo "2) Discord"
echo "3) Telegram"
echo "4) Slack"
echo "5) None (console logging only)"
read -p "Enter your choice (1-5): " NOTIFICATION_CHOICE

case $NOTIFICATION_CHOICE in
    1)
        read -p "Enter SMTP server: " SMTP_SERVER
        read -p "Enter SMTP port: " SMTP_PORT
        read -p "Enter SMTP username: " SMTP_USER
        read -s -p "Enter SMTP password: " SMTP_PASS
        echo ""
        read -p "Enter sender email: " SENDER_EMAIL
        read -p "Enter recipient email: " RECIPIENT_EMAIL
        NOTIFICATION_URL="smtp://${SMTP_USER}:${SMTP_PASS}@${SMTP_SERVER}:${SMTP_PORT}/?from=${SENDER_EMAIL}&to=${RECIPIENT_EMAIL}"
        ;;
    2)
        read -p "Enter Discord webhook URL: " DISCORD_WEBHOOK
        NOTIFICATION_URL="discord://${DISCORD_WEBHOOK}"
        ;;
    3)
        read -p "Enter Telegram bot token: " TG_TOKEN
        read -p "Enter Telegram chat ID: " TG_CHAT_ID
        NOTIFICATION_URL="telegram://${TG_TOKEN}@telegram?chats=${TG_CHAT_ID}"
        ;;
    4)
        read -p "Enter Slack webhook URL: " SLACK_WEBHOOK
        NOTIFICATION_URL="slack://${SLACK_WEBHOOK}"
        ;;
    *)
        NOTIFICATION_URL=""
        echo "No notifications configured. Watchtower will only log to console."
        ;;
esac
save_config "NOTIFICATION_URL" "$NOTIFICATION_URL"

echo "✅ Service configurations saved."
