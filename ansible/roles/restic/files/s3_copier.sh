#!/bin/bash

# Sync script to copy data from Selectel S3 to Yandex Cloud S3
# This script syncs the entire Restic repository from Selectel to Yandex Cloud

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/opt/{{ project_name }}/backup/logs/sync-to-yandex.log"
LOCK_FILE="/opt/{{ project_name }}/backup/logs/sync-to-yandex.lock"

# Source: Selectel S3
SELECTEL_BUCKET="{{ project_name }}-backups-{{ inventory_hostname }}"
SELECTEL_ENDPOINT="https://s3.ru-7.storage.selcloud.ru"
SELECTEL_ACCESS_KEY="" # TODO: add credentials
SELECTEL_SECRET_KEY="" # TODO: add credentials

# Destination: Yandex Cloud S3
YANDEX_BUCKET="{{ project_name }}-backups-{{ inventory_hostname }}"
YANDEX_ENDPOINT="https://storage.yandexcloud.net"
YANDEX_ACCESS_KEY="" # TODO: add credentials
YANDEX_SECRET_KEY="" # TODO: add credentials

# Selectel certificate path
SELECTEL_CERT_DIR="/opt/{{ project_name }}/backup/certs"
SELECTEL_CERT_FILE="$SELECTEL_CERT_DIR/selectel-root.crt"

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Error handling
error_exit() {
    log "ERROR: $1"
    rm -f "$LOCK_FILE"
    exit 1
}

# Check if already running
if [ -f "$LOCK_FILE" ]; then
    PID=$(cat "$LOCK_FILE" 2>/dev/null || echo "")
    if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
        log "Sync already running with PID $PID"
        exit 0
    else
        log "Removing stale lock file"
        rm -f "$LOCK_FILE"
    fi
fi

# Create lock file
echo $$ > "$LOCK_FILE"

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

log "Starting sync from Selectel S3 to Yandex Cloud S3"

# Check if rclone is installed
if ! command -v rclone &> /dev/null; then
    log "Installing rclone..."
    curl https://rclone.org/install.sh | sudo bash
fi

# Setup Selectel certificate if it doesn't exist
if [ ! -f "$SELECTEL_CERT_FILE" ]; then
    log "Downloading Selectel root certificate..."
    mkdir -p "$SELECTEL_CERT_DIR"
    if wget -q https://secure.globalsign.net/cacert/root-r6.crt -O "$SELECTEL_CERT_FILE.der"; then
        # Convert from DER to PEM format
        if openssl x509 -inform der -in "$SELECTEL_CERT_FILE.der" -out "$SELECTEL_CERT_FILE"; then
            chmod 600 "$SELECTEL_CERT_FILE"
            rm -f "$SELECTEL_CERT_FILE.der"
            log "Certificate downloaded and converted successfully"
        else
            error_exit "Failed to convert certificate from DER to PEM format"
        fi
    else
        error_exit "Failed to download Selectel certificate"
    fi
else
    log "Certificate already exists"
fi

# Create temporary rclone config
RCLONE_CONFIG=$(mktemp)
cat > "$RCLONE_CONFIG" << EOF
[selectel]
type = s3
provider = Other
access_key_id = $SELECTEL_ACCESS_KEY
secret_access_key = $SELECTEL_SECRET_KEY
endpoint = s3.ru-7.storage.selcloud.ru
region = ru-7
ca_cert = $SELECTEL_CERT_FILE

[yandex]
type = s3
provider = Other
access_key_id = $YANDEX_ACCESS_KEY
secret_access_key = $YANDEX_SECRET_KEY
endpoint = storage.yandexcloud.net
region = ru-central1
EOF

# Function to cleanup temp files
cleanup() {
    rm -f "$RCLONE_CONFIG" "$LOCK_FILE"
}

trap cleanup EXIT

# Test Selectel connection first
log "Testing Selectel S3 connection..."
if ! rclone --config "$RCLONE_CONFIG" lsd selectel: >/dev/null 2>&1; then
    log "Testing with verbose output:"
    rclone --config "$RCLONE_CONFIG" lsd selectel:
    error_exit "Cannot connect to Selectel S3 - check credentials and network"
fi

# Check if source bucket exists and has data
log "Checking source bucket: $SELECTEL_BUCKET"
if ! rclone --config "$RCLONE_CONFIG" lsd "selectel:$SELECTEL_BUCKET" >/dev/null 2>&1; then
    log "Listing all buckets to see what's available:"
    rclone --config "$RCLONE_CONFIG" lsd selectel:
    error_exit "Source bucket $SELECTEL_BUCKET does not exist or is not accessible"
fi

# Verify Selectel Restic repository integrity using existing setup
log "Verifying Selectel Restic repository integrity..."
if ! sudo -u restic bash -c 'source /opt/{{ project_name }}/backup/config/restic.env && restic snapshots --compact' >/dev/null 2>&1; then
    log "Testing with verbose output:"
    sudo -u restic bash -c 'source /opt/{{ project_name }}/backup/config/restic.env && restic snapshots --compact'
    error_exit "Cannot access Selectel Restic repository - source may be corrupted"
fi

# Get snapshot count for verification
SELECTEL_SNAPSHOTS=$(sudo -u restic bash -c 'source /opt/{{ project_name }}/backup/config/restic.env && restic snapshots --compact' | wc -l)
log "✓ Selectel Restic repository accessible with $SELECTEL_SNAPSHOTS snapshots"

# Check if destination bucket exists
log "Checking destination bucket: $YANDEX_BUCKET"
if ! rclone --config "$RCLONE_CONFIG" lsd "yandex:$YANDEX_BUCKET" >/dev/null 2>&1; then
    error_exit "Destination bucket $YANDEX_BUCKET does not exist - please create it manually in Yandex Cloud"
fi

# Show what we're about to sync
log "Source bucket contents (Selectel):"
rclone --config "$RCLONE_CONFIG" ls "selectel:$SELECTEL_BUCKET" 2>/dev/null | head -10 || true

log "Destination bucket contents (Yandex) before sync:"
rclone --config "$RCLONE_CONFIG" ls "yandex:$YANDEX_BUCKET" 2>/dev/null | head -10 || true

# Sync data from Selectel to Yandex Cloud using rclone
log "Starting sync operation using rclone..."
if rclone --config "$RCLONE_CONFIG" sync "selectel:$SELECTEL_BUCKET" "yandex:$YANDEX_BUCKET" --progress --transfers=4 --checkers=8; then
    log "✓ Sync completed successfully"
else
    error_exit "Sync failed"
fi

# Verify sync by comparing file counts (basic verification)
SELECTEL_COUNT=$(rclone --config "$RCLONE_CONFIG" ls "selectel:$SELECTEL_BUCKET" | wc -l)
YANDEX_COUNT=$(rclone --config "$RCLONE_CONFIG" ls "yandex:$YANDEX_BUCKET" | wc -l)

log "File count verification - Selectel: $SELECTEL_COUNT, Yandex: $YANDEX_COUNT"

if [ "$SELECTEL_COUNT" -eq "$YANDEX_COUNT" ]; then
    log "File count verification passed"
else
    log "WARNING: File count mismatch - Selectel: $SELECTEL_COUNT, Yandex: $YANDEX_COUNT"
fi

# Verify Yandex Restic repository integrity AFTER copying
log "Verifying Yandex Restic repository integrity..."
# Create temporary environment for Yandex repository in restic user's home
TEMP_ENV="/opt/{{ project_name }}/backup/config/restic_yandex.env"
cat > "$TEMP_ENV" << EOF
$(grep -v "^RESTIC_REPOSITORY=" /opt/{{ project_name }}/backup/config/restic.env 2>/dev/null || true)
RESTIC_REPOSITORY="s3:storage.yandexcloud.net/$YANDEX_BUCKET"
AWS_ACCESS_KEY_ID="$YANDEX_ACCESS_KEY"
AWS_SECRET_ACCESS_KEY="$YANDEX_SECRET_KEY"
AWS_DEFAULT_REGION="ru-central1"
AWS_ENDPOINT_URL="https://storage.yandexcloud.net"
EOF

# Set proper permissions for the restic user
chown restic:restic "$TEMP_ENV"
chmod 600 "$TEMP_ENV"

# Check if we can list snapshots (basic integrity check)
if ! sudo -u restic bash -c "source '$TEMP_ENV' && restic snapshots --compact" >/dev/null 2>&1; then
    log "Testing with verbose output:"
    sudo -u restic bash -c "source '$TEMP_ENV' && restic snapshots --compact"
    rm -f "$TEMP_ENV"
    error_exit "Cannot access Yandex Restic repository - sync may be incomplete"
fi

# Get snapshot count for verification
YANDEX_SNAPSHOTS=$(sudo -u restic bash -c "source '$TEMP_ENV' && restic snapshots --compact" | wc -l)
log "✓ Yandex Restic repository accessible with $YANDEX_SNAPSHOTS snapshots"

# Verify snapshot counts match
if [ "$SELECTEL_SNAPSHOTS" -eq "$YANDEX_SNAPSHOTS" ]; then
    log "✓ Snapshot count verification passed: $SELECTEL_SNAPSHOTS snapshots"
else
    log "WARNING: Snapshot count mismatch - Selectel: $SELECTEL_SNAPSHOTS, Yandex: $YANDEX_SNAPSHOTS"
fi

# Cleanup temp env file
rm -f "$TEMP_ENV"

# Show destination contents after sync
log "Destination bucket contents (Yandex) after sync:"
rclone --config "$RCLONE_CONFIG" ls "yandex:$YANDEX_BUCKET" 2>/dev/null | head -10 || true

log "Sync to Yandex Cloud completed successfully with integrity verification"