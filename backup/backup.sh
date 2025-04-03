#!/bin/bash

# Automated backup script for homelab services
# This script creates backups of all service volumes and configurations

BACKUP_DIR="$HOME/homelab/backups"
BACKUP_DATE=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="${BACKUP_DIR}/homelab_backup_${BACKUP_DATE}.tar.gz"

# 1. Stop services if needed
if [[ "$1" == "--stop-services" ]]; then
  echo "Stopping services for consistent backup..."
  cd "$HOME/homelab" && docker-compose stop
fi

# 2. Create backup directory for this run
TEMP_BACKUP_DIR="${BACKUP_DIR}/temp_${BACKUP_DATE}"
mkdir -p "${TEMP_BACKUP_DIR}"

# 3. Backup configuration files
echo "Backing up configuration files..."
cp -r "$HOME/homelab/configs" "${TEMP_BACKUP_DIR}/"
cp "$HOME/homelab/docker-compose.yml" "${TEMP_BACKUP_DIR}/"

# 4. Backup Docker volumes
echo "Backing up Docker volumes..."
VOLUMES=$(docker volume ls -q --filter "label=homelab.backup=true")
for VOLUME in $VOLUMES; do
  echo "Backing up volume: $VOLUME"
  docker run --rm -v $VOLUME:/volume -v ${TEMP_BACKUP_DIR}:/backup \
    busybox tar czf "/backup/${VOLUME}.tar.gz" -C /volume ./
done

# 5. Create the final backup archive
echo "Creating final backup archive..."
tar czf "${BACKUP_FILE}" -C "${TEMP_BACKUP_DIR}" .

# 6. Clean up temporary files
echo "Cleaning up temporary files..."
rm -rf "${TEMP_BACKUP_DIR}"

# 7. Start services if they were stopped
if [[ "$1" == "--stop-services" ]]; then
  echo "Starting services..."
  cd "$HOME/homelab" && docker-compose start
fi

# 8. Log the backup
echo "Backup completed: ${BACKUP_FILE}"
echo "$(date): Backup completed: ${BACKUP_FILE}" >> "${BACKUP_DIR}/backup_log.txt"

# 9. Call rotation script
$HOME/homelab/backup/rotate_backups.sh
