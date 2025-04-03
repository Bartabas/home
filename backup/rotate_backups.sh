#!/bin/bash

# Backup rotation script for homelab services
# This script removes backups older than the specified retention period

BACKUP_DIR="$HOME/homelab/backups"
RETENTION_DAYS=14

echo "Checking for backups older than ${RETENTION_DAYS} days..."
find "${BACKUP_DIR}" -type f -name "homelab_backup_*.tar.gz" -mtime +${RETENTION_DAYS} -exec rm {} \;
echo "Backup rotation completed."
