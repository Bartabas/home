#!/bin/bash

# Common functions for all modules

# Function to display stylized banners
display_banner() {
    local text="$1"
    local width=80
    local line=$(printf '%*s' "$width" | tr ' ' '=')
    echo "$line"
    echo "$(printf '%*s' $(( (width + ${#text}) / 2 )) "$text" | sed 's/^ *//')"
    echo "$line"
}

# Error handling function
error_exit() {
    echo "ERROR: $1"
    exit 1
}

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if a port is available
port_available() {
    ! ss -tuln | grep -q ":$1 "
}

# Generate a random password
generate_password() {
    local length=${1:-16}
    openssl rand -base64 $length | tr -dc 'a-zA-Z0-9!@#$%^&*()_+?><~=' | head -c $length
}

# Get user confirmation
confirm() {
    local prompt="$1"
    local default="$2"
    
    if [ "$default" = "Y" ]; then
        prompt="$prompt [Y/n]"
    else
        prompt="$prompt [y/N]"
    fi
    
    read -p "$prompt " answer
    
    if [ -z "$answer" ]; then
        answer=$default
    fi
    
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        return 0
    else
        return 1
    fi
}

# Save variable to config file
save_config() {
    local name="$1"
    local value="$2"
    local config_file="${INSTALL_DIR}/homelab.conf"
    
    if grep -q "^${name}=" "$config_file" 2>/dev/null; then
        # Update existing variable
        sed -i "s|^${name}=.*|${name}=\"${value}\"|" "$config_file"
    else
        # Create new variable
        echo "${name}=\"${value}\"" >> "$config_file"
    fi
}

# Load config file
load_config() {
    local config_file="${INSTALL_DIR}/homelab.conf"
    if [ -f "$config_file" ]; then
        source "$config_file"
    fi
}
