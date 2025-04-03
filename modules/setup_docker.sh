#!/bin/bash

# Check if Docker is installed
if ! command_exists docker; then
    echo "Docker not found. Installing Docker..."
    
    # Update package index
    apt-get update || error_exit "Failed to update package lists"
    
    # Install prerequisites
    apt-get install -y apt-transport-https ca-certificates curl software-properties-common || error_exit "Failed to install prerequisites"
    
    # Add Docker's official GPG key
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - || error_exit "Failed to add Docker GPG key"
    
    # Add Docker repository
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" || error_exit "Failed to add Docker repository"
    
    # Update package index again
    apt-get update || error_exit "Failed to update package lists"
    
    # Install Docker
    apt-get install -y docker-ce docker-ce-cli containerd.io || error_exit "Failed to install Docker"
    
    echo "Docker installed successfully."
else
    echo "Docker is already installed."
fi

# Check if Docker Compose is installed
if ! command_exists docker-compose; then
    echo "Docker Compose not found. Installing Docker Compose..."
    
    # Install Docker Compose
    curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose || error_exit "Failed to download Docker Compose"
    chmod +x /usr/local/bin/docker-compose || error_exit "Failed to set permissions on Docker Compose"
    
    echo "Docker Compose installed successfully."
else
    echo "Docker Compose is already installed."
fi

# Create Docker network for services
if ! docker network inspect web &>/dev/null; then
    echo "Creating Docker network 'web'..."
    docker network create web || error_exit "Failed to create Docker network"
else
    echo "Docker network 'web' already exists."
fi

# Make sure the current user can run Docker commands without sudo
if ! groups | grep -q docker; then
    echo "Adding current user to the docker group..."
    usermod -aG docker $USER || error_exit "Failed to add user to docker group"
    echo "Please log out and log back in for this change to take effect."
fi

echo "✅ Docker environment is ready."
