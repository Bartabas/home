#!/bin/bash

# Setup automated backups for all services

display_banner "Setting up Automated Backup System"

# Create backup directory
mkdir -p "${INSTALL_DIR}/backups"

# Copy backup scripts
cp "${BACKUP_DIR}/backup.sh" "${INSTALL_DIR}/backup.sh"
cp "${BACKUP_DIR}/rotate_backups.sh" "${INSTALL_DIR}/rotate_backups.sh"

# Make the scripts executable
chmod +x "${INSTALL_DIR}/backup.sh"
chmod +x "${INSTALL_DIR}/rotate_backups.sh"

# Update paths in the backup scripts
sed -i "s|HOME/homelab|INSTALL_DIR|g" "${INSTALL_DIR}/backup.sh"
sed -i "s|HOME/homelab|INSTALL_DIR|g" "${INSTALL_DIR}/rotate_backups.sh"

# Set up cron job for automated backups
CRON_HOUR=$(echo $BACKUP_TIME | cut -d':' -f1)
CRON_MINUTE=$(echo $BACKUP_TIME | cut -d':' -f2)

(crontab -l 2>/dev/null || echo "") | grep -v "${INSTALL_DIR}/backup.sh" | \
{ cat; echo "$CRON_MINUTE $CRON_HOUR * * * ${INSTALL_DIR}/backup.sh > ${INSTALL_DIR}/backups/cron_backup.log 2>&1"; } | \
crontab -

echo "✅ Automated backup system configured to run daily at ${BACKUP_TIME}."
echo "   Backups will be retained for ${BACKUP_RETENTION} days."
