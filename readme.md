# Homelab Automation Suite

This repository contains a set of modular scripts to automate the deployment of a complete homelab environment using Docker containers. The system provides network monitoring, DNS ad-blocking, home automation, and secure remote access capabilities.

![Homelab Logo]

## Overview

This automation script installs and configures the following services:

- **Pi-hole**: Network-wide ad blocker and DNS server
- **Unbound**: Recursive DNS resolver for enhanced privacy
- **Home Assistant**: Smart home automation platform
- **Prometheus & Grafana**: Monitoring and visualization suite
- **n8n**: Workflow automation platform
- **WireGuard VPN**: Secure remote access to your homelab
- **Portainer**: Docker container management interface
- **Heimdall**: Application dashboard to organize services
- **Dozzle**: Live Docker container log viewer
- **Watchtower**: Container update monitoring (monitor-only mode)

## System Requirements

- **Hardware**: Intel NUC or any system with similar capabilities
- **OS**: Ubuntu/Debian-based Linux distribution
- **RAM**: Minimum 8GB recommended (16GB preferred)
- **Storage**: At least 30GB free space
- **Network**: Static IP address recommended

## Installation

1. Clone this repository:
   ```bash
   git clone https://github.com/Bartabas/homelab.git
   cd homelab
   ```

2. Make the setup script executable:
   ```bash
   chmod +x setup.sh
   ```

3. Run the script with sudo privileges:
   ```bash
   sudo ./setup.sh
   ```

4. Follow the on-screen prompts to configure your homelab environment.

## What The Script Does

The setup is organized into modular components:

1. **System Requirements Check**: Verifies your hardware meets the minimum requirements
2. **Service Configuration**: Guides you through configuring each service
3. **Docker Setup**: Installs Docker and Docker Compose if needed
4. **HTTPS Configuration**: Sets up Traefik reverse proxy with Let's Encrypt
5. **Backup System**: Configures automated backups with rotation
6. **Service Deployment**: Pulls and starts all Docker containers
7. **Finalization**: Creates documentation and quick reference guides

## Accessing Your Services

After installation, you can access your services at:

- **Pi-hole**: http://your-server-ip/admin
- **Home Assistant**: http://your-server-ip:8123
- **Prometheus**: http://your-server-ip:9090
- **Grafana**: http://your-server-ip:3000
- **n8n**: http://your-server-ip:5678
- **WireGuard VPN**: http://your-server-ip:51821
- **Portainer**: http://your-server-ip:9000
- **Heimdall**: http://your-server-ip:8080
- **Dozzle**: http://your-server-ip:8081

When HTTPS is configured, you can also use secure versions of these URLs.

## Configuration

The script creates a configuration file at `~/homelab/homelab.conf` with your settings. You can:

- Modify resource allocations based on your hardware capabilities
- Change default passwords
- Configure notification preferences for container updates
- Adjust backup retention periods

## Maintenance

### Updating Containers

Watchtower is configured in monitor-only mode and will notify you of available updates. To apply updates:

```bash
cd ~/homelab
docker-compose pull
docker-compose up -d
```

Alternatively, use Portainer's web interface to update individual containers.

### Backup and Restore

Run a manual backup:
```bash
~/homelab/backup.sh
```

Backups are stored in `~/homelab/backups` and are automatically rotated based on your retention settings.

## Directory Structure

```
homelab/
├── backup/                # Backup scripts
│   ├── backup.sh          # Main backup script
│   └── rotate_backups.sh  # Backup rotation script
├── configs/               # Configuration templates
│   ├── homeassistant/     # Home Assistant config
│   ├── prometheus/        # Prometheus config
│   ├── traefik/           # Traefik config
│   ├── unbound/           # Unbound DNS config
│   └── docker-compose.yml.template
├── modules/               # Script modules
│   ├── check_requirements.sh
│   ├── common.sh
│   ├── finalize.sh
│   ├── setup_backups.sh
│   ├── setup_configs.sh
│   ├── setup_docker.sh
│   ├── setup_services.sh
│   └── setup_traefik.sh
└── setup.sh               # Main installer script
```

## Troubleshooting

- **Container not starting**: Check logs with `docker logs container_name`
- **Service not accessible**: Verify that ports are not blocked by a firewall
- **Configuration issues**: Review files in the `~/homelab/configs` directory

## Security Considerations

- All generated passwords are stored in the quick reference guide
- Consider setting up a firewall to restrict access to sensitive ports
- WireGuard provides secure remote access to your homelab
- Traefik can be configured with Let's Encrypt for HTTPS access

## License

This project is released under the MIT License.

## Acknowledgments

This project was inspired by various homelab setups and enhanced with modern container management practices.

