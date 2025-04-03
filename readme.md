# Homelab Automation Script

This script sets up a complete homelab environment with network monitoring, DNS ad-blocking, home automation, and remote access capabilities on an Intel NUC or similar hardware.

## Overview

This automation script installs and configures the following services using Docker:

- **Pi-hole**: Network-wide ad blocker and DNS server
- **Unbound**: Recursive DNS resolver for enhanced privacy
- **Home Assistant**: Smart home automation platform
- **Prometheus & Grafana**: Monitoring and visualization suite
- **n8n**: Workflow automation platform
- **WireGuard VPN**: Secure remote access to your homelab
- **Portainer**: Docker container management interface
- **Heimdall**: Application dashboard to organize services
- **Dozzle**: Live Docker container log viewer
- **Watchtower**: Container update monitoring and notifications

![Homelab Architecture Overview]
*Screenshot: Overview of the homelab architecture*

## System Requirements

- **Hardware**: Intel NUC or any system with similar capabilities
- **OS**: Ubuntu/Debian-based Linux distribution
- **RAM**: Minimum 8GB recommended (16GB preferred)
- **Storage**: At least 30GB free space
- **Network**: Static IP address recommended

![Hardware Requirements]
*Screenshot: Example of compatible hardware*

## Installation

1. Download the script:
   ```bash
   curl -O https://raw.githubusercontent.com/yourusername/homelab/main/setup.sh
   ```

2. Make the script executable:
   ```bash
   chmod +x setup.sh
   ```

3. Run the script with sudo privileges:
   ```bash
   sudo ./setup.sh
   ```

4. Follow the on-screen prompts:
   - Provide your WireGuard VPN public IP or hostname
   - Choose a WireGuard password
   - Select and configure notification preferences for Watchtower

![Installation Process]
*Screenshot: Script execution in progress*

## What The Script Does

1. Checks system requirements and installed dependencies
2. Detects your network configuration
3. Installs Docker and Docker Compose if not already present
4. Creates the necessary directory structure
5. Generates configuration files for all services
6. Downloads and starts the Docker containers
7. Configures initial integrations between services
8. Verifies that all services are running correctly
9. Provides access URLs and credentials for each service

![Script Completion]
*Screenshot: Successful script completion*

## Accessing Your Services

After installation, you can access your services at the following URLs (replace `` with your system's IP address):

- **Pi-hole**: http://``/admin (default password: yourpassword)
- **Home Assistant**: http://``:8123
- **Prometheus**: http://``:9090
- **Grafana**: http://``:3000 (login: admin/admin)
- **n8n**: http://``:5678
- **WireGuard VPN**: http://``:51821 (use your specified password)
- **Portainer**: http://``:9000
- **Heimdall**: http://``:8080
- **Dozzle**: http://``:8081

![Heimdall Dashboard]
*Screenshot: Heimdall dashboard with all services*

## Post-Installation Steps

1. **Update Default Passwords**: Change the default passwords for Pi-hole, Grafana, Portainer, and WireGuard.

   ![Password Update Example]
   *Screenshot: Updating passwords in different services*

2. **Configure Heimdall**: Add your services to Heimdall by:
   - Accessing Heimdall at http://``:8080
   - Clicking "Add Application"
   - Selecting applications from the preset list or creating custom entries
   - Entering the appropriate URLs for each service

   ![Heimdall Configuration]
   *Screenshot: Adding applications to Heimdall*

3. **Set Up WireGuard VPN Clients**:
   - Access the WireGuard interface at http://``:51821
   - Create client configurations for your devices
   - Download the WireGuard client app on your devices
   - Import the configuration or scan the QR code

   ![WireGuard Setup]
   *Screenshot: WireGuard web interface*

4. **Configure Port Forwarding**: For remote access, forward port 51820/UDP on your router to your NUC's IP address.

   ![Port Forwarding]
   *Screenshot: Router port forwarding configuration*

## Docker Management with Portainer

Portainer provides a graphical interface for managing all your Docker containers:

1. Access Portainer at http://``:9000
2. Create an admin password on first login
3. Select "Local" environment
4. Use the dashboard to:
   - Monitor container health
   - View logs
   - Restart services
   - Update containers
   - Manage volumes and networks

![Portainer Dashboard]
*Screenshot: Portainer container management interface*

## Update Management with Watchtower

Watchtower is configured in monitor-only mode to alert you when container updates are available:

- Checks for updates once per day
- Sends notifications through your configured notification method (email, Discord, Telegram, etc.)
- Does NOT automatically update containers

### Applying Updates Manually

When Watchtower notifies you of available updates, you can apply them through Portainer:

1. Log in to Portainer at http://``:9000
2. Navigate to "Containers" in the left sidebar
3. For each container with an available update:
   - Click on the container name
   - Click "Recreate"
   - Check the "Pull latest image" option
   - Click "Recreate" to apply the update

This approach gives you complete control over when updates happen, allowing you to update at convenient times and test each update before moving to the next one.

![Update Management]
*Screenshot: Manually updating containers in Portainer*

## Service Highlights

### Pi-hole and Unbound

Block ads and trackers at the DNS level while enhancing privacy with recursive DNS resolution.

![Pi-hole Dashboard]
*Screenshot: Pi-hole admin interface showing blocked queries*

### Home Assistant

Control and automate your smart home devices from a single, powerful interface.

![Home Assistant]
*Screenshot: Home Assistant dashboard with device controls*

### Prometheus and Grafana

Monitor your system performance and network traffic with detailed graphs and alerts.

![Grafana Dashboard]
*Screenshot: Grafana displaying system metrics*

### n8n Workflow Automation

Create powerful automation workflows connecting your various homelab services.

![n8n Workflows]
*Screenshot: n8n workflow editor*

## Troubleshooting

- **Container not starting**: Check container logs via Dozzle or with `docker logs container_name`
- **Service not accessible**: Verify that ports are not blocked by a firewall
- **Configuration issues**: Most service configurations are stored in the `~/docker` directory
- **Space issues**: Use `docker system prune` to remove unused Docker resources

![Dozzle Log Viewer]
*Screenshot: Viewing container logs in Dozzle*

## Additional Resources

- Home Assistant documentation: https://www.home-assistant.io/docs/
- Pi-hole documentation: https://docs.pi-hole.net/
- Portainer documentation: https://docs.portainer.io/
- n8n documentation: https://docs.n8n.io/

## Advanced Configuration

The script creates a Docker Compose configuration at `~/docker/docker-compose.yml`. You can modify this file to:
- Change port mappings
- Add environment variables
- Modify volume mounts
- Add new services

After any changes, apply them with:
```bash
cd ~/docker
docker-compose up -d
```

![Docker Compose Configuration]
*Screenshot: Example of modified docker-compose.yml file*

## Security Considerations

- This setup includes multiple web interfaces - consider setting up HTTPS for increased security
- Regularly update container images for security patches
- Use strong, unique passwords for all services
- Consider network segmentation for IoT devices

![Security Updates]
*Screenshot: Updating container images for security*

---
Answer from Perplexity: pplx.ai/share