#!/bin/bash

# --- Configuration ---
SOURCE_DIR="/var/log/audit"
DEST_DIR="/mnt/data/audit/$(hostname)"
LOG_PATTERN="audit.log.*"
TIMESTAMP=$(date +%Y-%m-%d_%H%M%S)
ARCHIVE_NAME="audit_logs_$TIMESTAMP.tar.gz"
PERMISSIONS="700"
ACTUAL_MOUNT_POINT="/mnt/data"

# --- Safety Checks ---
if ! mountpoint -q $ACTUAL_MOUNT_POINT; then
    echo "Error: Target drive not mounted. Aborting." >&2
    exit 1
fi

mkdir -p "$DEST_DIR"

# --- Maintenance Operation ---
echo "Starting log maintenance: $(date)"

# 1. Check for rotated logs
if ls "$SOURCE_DIR"/$LOG_PATTERN >/dev/null 2>&1; then
    
    # 2. Sync files to a temporary "staging" folder on the network drive
    mkdir -p "$DEST_DIR/staging"
    rsync -avz --remove-source-files "$SOURCE_DIR"/$LOG_PATTERN "$DEST_DIR/staging/"
    
    # 3. Tar the synced files into a single archive
    # -C changes directory so the tar doesn't contain full system paths
    tar -czf "$DEST_DIR/$ARCHIVE_NAME" -C "$DEST_DIR/staging" .
    chmod "$PERMISSIONS" "$DEST_DIR/$ARCHIVE_NAME"
    
    # 4. Clean up the staging folder
    rm -rf "$DEST_DIR/staging"
    
    echo "Logs successfully archived to $ARCHIVE_NAME"
else
    echo "No rotated logs found to move. Skipping."
fi

echo "Maintenance complete: $(date)"
