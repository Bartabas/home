#!/bin/bash

# Homelab Automation Suite - Main Installer
# This script orchestrates the setup of a complete homelab environment

# Set script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULES_DIR="${SCRIPT_DIR}/modules"
CONFIG_DIR="${SCRIPT_DIR}/configs"
BACKUP_DIR="${SCRIPT_DIR}/backup"

# Source helper functions
source "${MODULES_DIR}/common.sh"

# Display banner
display_banner "Homelab Automation Suite Installer"
echo "This will set up a complete homelab environment with customized configurations."
echo ""

# Check if running as root or with sudo
if [ "$(id -u)" -ne 0 ]; then
    error_exit "This script must be run as root or with sudo"
fi

# Create installation directory
INSTALL_DIR="${SCRIPT_DIR}"


# 1. Check system requirements
echo "Step 1: Checking system requirements and hardware capabilities..."
source "${MODULES_DIR}/check_requirements.sh"

# 2. Configure services with wizard
echo "Step 2: Setting up service configurations..."
source "${MODULES_DIR}/setup_configs.sh"

# 3. Install Docker and Docker Compose if needed
echo "Step 3: Ensuring Docker environment is properly configured..."
source "${MODULES_DIR}/setup_docker.sh"

# 4. Set up Traefik reverse proxy with HTTPS
echo "Step 4: Setting up secure access with Traefik..."
source "${MODULES_DIR}/setup_traefik.sh"

# 5. Set up backup solution
echo "Step 5: Configuring automated backup system..."
source "${MODULES_DIR}/setup_backups.sh"

# 6. Deploy all services
echo "Step 6: Deploying homelab services..."
source "${MODULES_DIR}/setup_services.sh"

# 7. Finalize setup and display access information
echo "Step 7: Finalizing setup..."
source "${MODULES_DIR}/finalize.sh"

echo "✅ Homelab setup complete! Access your dashboard at https://${DOMAIN_NAME}"
echo "📝 Complete documentation has been saved to ${INSTALL_DIR}/README.md"
