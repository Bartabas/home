#!/bin/bash

# Check system requirements and recommend resource allocation

# Detect system resources
CPU_CORES=$(nproc)
TOTAL_MEM=$(free -m | awk '/^Mem:/{print $2}')
FREE_SPACE=$(df -BG /home | awk 'NR==2 {print $4}' | sed 's/G//')

echo "System resources detected:"
echo "- CPU Cores: $CPU_CORES"
echo "- Total Memory: $TOTAL_MEM MB"
echo "- Free Disk Space: $FREE_SPACE GB"

# Check minimum requirements
if [ "$CPU_CORES" -lt 2 ]; then
    error_exit "Insufficient CPU cores. At least 2 cores are required."
fi

if [ "$TOTAL_MEM" -lt 4000 ]; then
    error_exit "Insufficient memory. At least 4GB RAM is required."
fi

if [ "$FREE_SPACE" -lt 20 ]; then
    error_exit "Insufficient disk space. At least 20GB is required."
fi

# Determine resource profile based on available hardware
if [ "$TOTAL_MEM" -lt 8000 ]; then
    RESOURCE_PROFILE="low"
    echo "Based on your hardware, using low resource profile."
elif [ "$TOTAL_MEM" -lt 16000 ]; then
    RESOURCE_PROFILE="medium"
    echo "Based on your hardware, using medium resource profile."
else
    RESOURCE_PROFILE="high"
    echo "Based on your hardware, using high resource profile."
fi

# Ask user if they want to override the resource profile
if confirm "Would you like to override the recommended resource profile?" "N"; then
    echo "Select resource profile:"
    echo "1) Low    - Minimal resource usage, suitable for systems with 4-8GB RAM"
    echo "2) Medium - Balanced resource usage, suitable for systems with 8-16GB RAM"
    echo "3) High   - Optimal performance, suitable for systems with 16GB+ RAM"
    while true; do
        read -p "Enter profile number (1-3): " profile_choice
        case $profile_choice in
            1) RESOURCE_PROFILE="low"; break;;
            2) RESOURCE_PROFILE="medium"; break;;
            3) RESOURCE_PROFILE="high"; break;;
            *) echo "Invalid selection. Please enter 1, 2, or 3.";;
        esac
    done
fi

# Define resource limits based on profile
case $RESOURCE_PROFILE in
    low)
        # Conservative resource limits
        PIHOLE_MEM_LIMIT="256M"
        UNBOUND_MEM_LIMIT="256M"
        HOMEASSISTANT_MEM_LIMIT="512M"
        PROMETHEUS_MEM_LIMIT="512M"
        GRAFANA_MEM_LIMIT="256M"
        N8N_MEM_LIMIT="512M"
        ;;
    medium)
        # Balanced resource limits
        PIHOLE_MEM_LIMIT="512M"
        UNBOUND_MEM_LIMIT="512M"
        HOMEASSISTANT_MEM_LIMIT="1G"
        PROMETHEUS_MEM_LIMIT="1G"
        GRAFANA_MEM_LIMIT="512M"
        N8N_MEM_LIMIT="1G"
        ;;
    high)
        # Performance-oriented resource limits
        PIHOLE_MEM_LIMIT="1G"
        UNBOUND_MEM_LIMIT="1G"
        HOMEASSISTANT_MEM_LIMIT="2G"
        PROMETHEUS_MEM_LIMIT="2G"
        GRAFANA_MEM_LIMIT="1G"
        N8N_MEM_LIMIT="2G"
        ;;
esac

# Save resource profile settings
save_config "RESOURCE_PROFILE" "$RESOURCE_PROFILE"
save_config "PIHOLE_MEM_LIMIT" "$PIHOLE_MEM_LIMIT"
save_config "UNBOUND_MEM_LIMIT" "$UNBOUND_MEM_LIMIT"
save_config "HOMEASSISTANT_MEM_LIMIT" "$HOMEASSISTANT_MEM_LIMIT"
save_config "PROMETHEUS_MEM_LIMIT" "$PROMETHEUS_MEM_LIMIT"
save_config "GRAFANA_MEM_LIMIT" "$GRAFANA_MEM_LIMIT"
save_config "N8N_MEM_LIMIT" "$N8N_MEM_LIMIT"

echo "✅ System requirements checked and resource profile configured."
