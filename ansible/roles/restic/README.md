# Restic Backup Ansible Role

This Ansible role installs and configures Restic as a backup solution using systemd services and timers. Restic is a fast, secure, and efficient backup program that supports multiple storage backends including S3, local storage, SFTP, and more.

## Features

- **Systemd service deployment** - Runs Restic as native systemd services with proper configuration
- **Multiple storage backends** - Supports S3, local, SFTP, REST, Azure, Google Cloud Storage, and Swift
- **Automated scheduling** - Configurable systemd timers for backups, pruning, and integrity checks
- **Retention policies** - Flexible snapshot retention with keep-last, keep-daily, keep-weekly, keep-monthly, and keep-yearly options
- **Security** - Encrypted backups with configurable passwords
- **Monitoring** - Health checks and comprehensive logging via systemd journal
- **Resource efficiency** - Lightweight native installation without container overhead
- **Exclusion patterns** - Customizable file and directory exclusions
- **Verification** - Optional backup verification after completion

## Requirements

- Target system running a Debian-based Linux distribution (Ubuntu, Debian)
- SSH access to the target system with sudo privileges

**Note**: The role automatically installs all required dependencies including:
- Restic binary from official repository
- Python3 with required libraries
- Required system packages
- Configures systemd timers for scheduled operations

## Role Variables

### Basic Configuration

```yaml
# Project and instance names
project_name: restic_backup
restic_instance_name: backup

# Base directories
restic_base_dir: "/opt/{{ project_name }}/{{ restic_instance_name }}"
restic_config_dir: "{{ restic_base_dir }}/config"
restic_log_dir: "{{ restic_base_dir }}/logs"
restic_cache_dir: "{{ restic_base_dir }}/cache"
restic_scripts_dir: "{{ restic_base_dir }}/scripts"

# User and group
restic_user: "restic"
restic_group: "restic"
```

### Repository Configuration

```yaml
# Repository settings
restic_repository: "s3:s3.amazonaws.com/your-bucket-name"
restic_repository_type: "s3"  # Options: s3, local, sftp, rest, azure, gs, swift
restic_repository_path: ""  # For local repositories
restic_password: "changeme"  # Please change this!

# AWS S3 configuration (when using S3 backend)
restic_aws_access_key_id: ""
restic_aws_secret_access_key: ""
restic_aws_region: "us-east-1"
restic_aws_endpoint: "s3.amazonaws.com"

# Custom S3 endpoint configuration (for providers like Selectel)
restic_s3_endpoint_url: ""  # e.g., "https://s3.ru-7.storage.selcloud.ru"
restic_s3_ca_bundle: "{{ restic_config_dir }}/selectel-ca.crt"
restic_setup_selectel_ca: false  # Set to true for Selectel cloud storage
```

### Backup Configuration

```yaml
# Paths to backup
restic_backup_paths:
  - "/data"
  - "/opt"
  - "/etc"

# Exclusion patterns
restic_exclude_patterns:
  - "*.tmp"
  - "*.log"
  - "*.cache"
  - "/tmp/*"
  - "/var/tmp/*"
  - "/var/cache/*"
  - "node_modules"
  - ".git"
```

### Retention Policy

```yaml
# Retention settings
restic_keep_last: 7      # Keep last 7 snapshots
restic_keep_daily: 7     # Keep daily snapshots for 7 days
restic_keep_weekly: 4    # Keep weekly snapshots for 4 weeks
restic_keep_monthly: 6   # Keep monthly snapshots for 6 months
restic_keep_yearly: 2    # Keep yearly snapshots for 2 years
```

### Scheduling

```yaml
# Systemd timer schedules (systemd calendar format)
restic_backup_schedule: "0 2 * * *"  # Daily at 2 AM
restic_prune_schedule: "0 3 * * 0"   # Weekly on Sunday at 3 AM
restic_check_schedule: "0 4 * * 0"   # Weekly on Sunday at 4 AM
```

### Systemd Service Configuration

```yaml
# Service settings
restic_service_name: "restic_backup"
restic_service_description: "Restic Backup Service"
restic_service_type: "oneshot"
restic_service_restart: "no"
```

### Logging and Monitoring

```yaml
# Logging settings
restic_log_level: "info"
restic_log_file: "{{ restic_log_dir }}/restic.log"
restic_backup_log_file: "{{ restic_log_dir }}/backup.log"

# Health checks
restic_health_check_enabled: true
restic_health_check_interval: 3600  # 1 hour
```

### Security and Verification

```yaml
# Security options
restic_encryption_enabled: true
restic_verify_backups: true

# Notifications (future feature)
restic_notifications_enabled: false
restic_notification_email: ""
restic_notification_webhook: ""
```

### Dependencies

```yaml

# System packages
restic_system_packages:
  - restic
  - python3
  - python3-pip
  - curl
  - gnupg
  - ca-certificates
  - systemd
  - postgresql-client  # Required for database dumps

# Python packages
restic_python_packages: []
```

### PostgreSQL Backup Configuration

The role now supports automatic PostgreSQL database dumps before running restic backups using a **simple configuration file approach**:

```yaml
# Enable PostgreSQL backup functionality
restic_postgresql_backup_enabled: true

# Directory where database dumps will be stored
restic_postgresql_backup_dir: "{{ restic_base_dir }}/db-dumps"

# How long to keep local database dumps (in days)
restic_postgresql_retention_days: 7
```

#### Database Configuration File

Databases are configured in a simple pipe-delimited file: `/opt/restic_backup/backup/config/databases.conf`

**Format:**
```
# Database Backup Configuration
# Format: container_name|database_name|username|password|port
# Lines starting with # are ignored

postgres_test|postgres|postgres|password|5432
postgres_prod|postgres|postgres|password|5432
onprem_postgres|postgres|postgres|password|5432
```

#### Adding New Databases

To add a new database, simply edit the configuration file:

```bash
# Edit the database configuration
sudo -u restic nano /opt/restic_backup/backup/config/databases.conf

# Add a new line:
new_postgres_container|postgres|postgres|newpassword|5432

# Test the configuration
sudo -u restic /opt/restic_backup/backup/scripts/pg_dump.sh
```

**No Ansible deployment required** for adding new databases! ✨

## Restoring PostgreSQL Backups

To restore databases, use the `pg_restore.sh` script generated in `{{ restic_scripts_dir }}`.

### Usage:
- Restore all databases from a snapshot: `./pg_restore.sh <snapshot_id>`
- Restore all databases for a specific container: `./pg_restore.sh <snapshot_id> <container_name> all`
- Restore a specific database: `./pg_restore.sh <snapshot_id> <container_name> <db_name>`

First, list available snapshots with `restic snapshots`. Then run the script as the restic user.

Note: This restores from the latest matching dump files in the snapshot. Ensure the target databases exist or use --create if needed (modify script if required).

## Dependencies

This role **automatically manages its dependencies**:
- **System packages**: Installs Restic and all required system dependencies
- **Systemd services**: Creates and manages systemd services and timers

## Example Playbook

### Basic Usage

```yaml
---
- hosts: servers
  roles:
    - restic
```

### S3 Backend Configuration

```yaml
---
- hosts: servers
  vars:
    # S3 repository configuration
    restic_repository: "s3:s3.amazonaws.com/my-backup-bucket"
    restic_repository_type: "s3"
    restic_password: "your-secure-password"
    restic_aws_access_key_id: "your-access-key"
    restic_aws_secret_access_key: "your-secret-key"
    restic_aws_region: "us-west-2"
    
    # Custom backup paths
    restic_backup_paths:
      - "/data"
      - "/opt/applications"
      - "/etc/nginx"
      - "/var/log"
    
    # Custom retention policy
    restic_keep_daily: 14
    restic_keep_weekly: 8
    restic_keep_monthly: 12
    
    # Custom schedule
    restic_backup_schedule: "0 1 * * *"  # Daily at 1 AM
    
  roles:
    - restic
```

### Local Repository Configuration

```yaml
---
- hosts: servers
  vars:
    # Local repository
    restic_repository: "local:/backup/restic-repo"
    restic_repository_type: "local"
    restic_password: "your-secure-password"
    
    # Minimal backup paths
    restic_backup_paths:
      - "/etc"
      - "/home"
    
    # Aggressive retention for local storage
    restic_keep_last: 3
    restic_keep_daily: 7
    restic_keep_weekly: 4
    
  roles:
    - restic
```

### Selectel S3 Configuration

```yaml
---
- hosts: servers
  vars:
    # Selectel S3 repository configuration
    restic_repository: "s3:s3.ru-7.storage.selcloud.ru/my-backups-server-01"
    restic_repository_type: "s3"
    restic_password: "your-secure-backup-password"
    restic_aws_access_key_id: "your-selectel-access-key-id"
    restic_aws_secret_access_key: "your-selectel-secret-access-key"
    restic_aws_region: "ru-7"
    restic_s3_endpoint_url: "https://s3.ru-7.storage.selcloud.ru"
    restic_setup_selectel_ca: true
    
    # Backup configuration
    restic_backup_paths:
      - "/data"
      - "/opt"
      - "/etc"
      - "/var/log"
    
    # Custom retention policy
    restic_keep_daily: 14
    restic_keep_weekly: 8
    restic_keep_monthly: 12
    restic_keep_yearly: 3
    
    # Custom schedule
    restic_backup_schedule: "0 3 * * *"  # Daily at 3 AM
    
  roles:
    - restic
```

## Repository Types

### S3 Backend
```yaml
restic_repository: "s3:s3.amazonaws.com/bucket-name"
restic_repository_type: "s3"
restic_aws_access_key_id: "your-access-key"
restic_aws_secret_access_key: "your-secret-key"
restic_aws_region: "us-east-1"
```

### Local Backend
```yaml
restic_repository: "local:/path/to/repository"
restic_repository_type: "local"
```

### Selectel S3 Backend
```yaml
restic_repository: "s3:s3.ru-7.storage.selcloud.ru/my-backups-server-01"
restic_repository_type: "s3"
restic_aws_access_key_id: "your-selectel-access-key"
restic_aws_secret_access_key: "your-selectel-secret-key"
restic_aws_region: "ru-7"
restic_s3_endpoint_url: "https://s3.ru-7.storage.selcloud.ru"
restic_setup_selectel_ca: true
```

### SFTP Backend
```yaml
restic_repository: "sftp:user@host:/path/to/repository"
restic_repository_type: "sftp"
```

### REST Backend
```yaml
restic_repository: "rest:https://host:port/path"
restic_repository_type: "rest"
```

## Manual Operations

### Run a manual backup
```bash
sudo systemctl start restic_backup_backup
```

### List snapshots
```bash
sudo -u restic restic snapshots
```

### Restore from backup
```bash
sudo -u restic restic restore latest --target /tmp/restore
```

### Check repository integrity
```bash
sudo systemctl start restic_backup_backup_check
```

### Prune old snapshots
```bash
sudo systemctl start restic_backup_backup_prune
```

## Monitoring

### Check service status
```bash
systemctl status restic_backup_backup*
```

### View logs
```bash
journalctl -u restic_backup_backup -f
journalctl -u restic_backup_backup_prune -f
journalctl -u restic_backup_backup_check -f
```

### Check timer status
```bash
systemctl list-timers restic_backup_backup*
```

### View backup logs
```bash
tail -f /opt/restic_backup/backup/logs/backup.log
tail -f /opt/restic_backup/backup/logs/restic.log
```

## Backup Monitoring and Management Commands

### View Backup History and Status

**Show all snapshots (backup history):**
```bash
sudo -u restic bash -c 'source /opt/restic_backup/backup/config/restic.env && restic snapshots'
```

**Show latest snapshot details:**
```bash
sudo -u restic bash -c 'source /opt/restic_backup/backup/config/restic.env && restic snapshots --last'
```

**Show snapshots in compact format:**
```bash
sudo -u restic bash -c 'source /opt/restic_backup/backup/config/restic.env && restic snapshots --compact'
```

**Get detailed backup statistics:**
```bash
sudo -u restic bash -c 'source /opt/restic_backup/backup/config/restic.env && restic stats'
```

### Browse Backup Contents

**List files in latest backup:**
```bash
sudo -u restic bash -c 'source /opt/restic_backup/backup/config/restic.env && restic ls latest'
```

**List files in specific snapshot:**
```bash
sudo -u restic bash -c 'source /opt/restic_backup/backup/config/restic.env && restic ls SNAPSHOT_ID'
```

**Find specific files in backups:**
```bash
# Find all files containing "nginx"
sudo -u restic bash -c 'source /opt/restic_backup/backup/config/restic.env && restic find nginx'

# Find files under /opt directory
sudo -u restic bash -c 'source /opt/restic_backup/backup/config/restic.env && restic find /opt'
```

**Browse backup like a filesystem:**
```bash
sudo -u restic bash -c 'source /opt/restic_backup/backup/config/restic.env && restic mount /mnt/restic'
```
# Then browse /mnt/restic with normal file commands
# Don't forget to unmount: fusermount -u /mnt/restic
```

### Compare and Analyze Changes

**Compare what changed between backups:**
```bash
sudo -u restic bash -c 'source /opt/restic_backup/backup/config/restic.env && restic diff'
```

**Compare specific snapshots:**
```bash
sudo -u restic bash -c 'source /opt/restic_backup/backup/config/restic.env && restic diff SNAPSHOT1 SNAPSHOT2'
```

### Repository Health and Maintenance

**Check repository health:**
```bash
sudo -u restic bash -c 'source /opt/restic_backup/backup/config/restic.env && restic check'
```

**Check repository with data verification:**
```bash
sudo -u restic bash -c 'source /opt/restic_backup/backup/config/restic.env && restic check --read-data'
```

**Get repository information in JSON format:**
```bash
sudo -u restic bash -c 'source /opt/restic_backup/backup/config/restic.env && restic snapshots --json'
```

### Manual Backup Operations

**Run backup manually:**
```bash
sudo -u restic /opt/restic_backup/backup/scripts/backup.sh
```

**Run backup with custom options:**
```bash
sudo -u restic bash -c 'source /opt/restic_backup/backup/config/restic.env && restic backup /custom/path --tag manual'
```

### Restore Operations

**Restore latest backup to specific location:**
```bash
sudo -u restic bash -c 'source /opt/restic_backup/backup/config/restic.env && restic restore latest --target /tmp/restore'
```

**Restore specific files from backup:**
```bash
sudo -u restic bash -c 'source /opt/restic_backup/backup/config/restic.env && restic restore latest --target /tmp/restore --include "/opt/docker-compose.yml"'
```

**Restore specific snapshot:**
```bash
sudo -u restic bash -c 'source /opt/restic_backup/backup/config/restic.env && restic restore SNAPSHOT_ID --target /tmp/restore'
```

### Backup Deletion and Cleanup

⚠️ **WARNING**: Backup deletion is irreversible. Always check what you're deleting first.

**List all snapshots before deletion:**
```bash
sudo -u restic bash -c 'source /opt/restic_backup/backup/config/restic.env && restic snapshots'
```

**Safe deletion - Remove old snapshots (recommended):**
```bash
# Keep only last 5 snapshots
sudo -u restic bash -c 'source /opt/restic_backup/backup/config/restic.env && restic forget --keep-last 5 --prune'

# Keep snapshots from last 30 days only
sudo -u restic bash -c 'source /opt/restic_backup/backup/config/restic.env && restic forget --keep-within 30d --prune'

# Keep only last week of snapshots
sudo -u restic bash -c 'source /opt/restic_backup/backup/config/restic.env && restic forget --keep-within 7d --prune'
```

**Delete specific snapshots by ID:**
```bash
# First list snapshots to get IDs
sudo -u restic bash -c 'source /opt/restic_backup/backup/config/restic.env && restic snapshots'

# Then delete specific snapshot
sudo -u restic bash -c 'source /opt/restic_backup/backup/config/restic.env && restic forget SNAPSHOT_ID --prune'
```

**Progressive cleanup (safest approach):**
```bash
# Step 1: Check what you have
sudo -u restic bash -c 'source /opt/restic_backup/backup/config/restic.env && restic snapshots'
sudo -u restic bash -c 'source /opt/restic_backup/backup/config/restic.env && restic stats'

# Step 2: Remove older snapshots first
sudo -u restic bash -c 'source /opt/restic_backup/backup/config/restic.env && restic forget --keep-last 3 --prune'

# Step 3: If needed, remove more
sudo -u restic bash -c 'source /opt/restic_backup/backup/config/restic.env && restic forget --keep-last 1 --prune'
```

**🚨 DANGER ZONE - Complete deletion:**
```bash
# Delete ALL snapshots (IRREVERSIBLE)
sudo -u restic bash -c 'source /opt/restic_backup/backup/config/restic.env && restic forget --keep-within 0s --prune'

# Nuclear option - Completely reinitialize repository (DESTROYS EVERYTHING)
sudo -u restic bash -c 'source /opt/restic_backup/backup/config/restic.env && yes | restic init --remove-existing'
```

**Dry run options (safe testing):**
```bash
# Preview what would be deleted without actually deleting
sudo -u restic bash -c 'source /opt/restic_backup/backup/config/restic.env && restic forget --keep-last 5 --dry-run'
```

### System Integration Monitoring

**Check systemd timer status:**
```bash
systemctl list-timers | grep restic
```

**View timer details:**
```bash
systemctl status restic_backup_backup.timer
systemctl status restic_backup_backup_prune.timer
systemctl status restic_backup_backup_check.timer
```

**Check last backup execution:**
```bash
systemctl status restic_backup_backup.service
journalctl -u restic_backup_backup.service --since "24 hours ago"
```

**View recent backup logs:**
```bash
tail -20 /opt/restic_backup/backup/logs/backup.log
```

**Monitor backup in real-time:**
```bash
tail -f /opt/restic_backup/backup/logs/backup.log
```

### Quick Status Check Script

Create a simple status script to run regular checks:

```bash
#!/bin/bash
# Quick backup status check

echo "=== Restic Backup Status ==="
echo "Repository: $(sudo -u restic bash -c 'source /opt/restic_backup/backup/config/restic.env && echo $RESTIC_REPOSITORY')"
echo "Last backup: $(sudo -u restic bash -c 'source /opt/restic_backup/backup/config/restic.env && restic snapshots --last --json | jq -r ".[0].time"')"
echo "Total snapshots: $(sudo -u restic bash -c 'source /opt/restic_backup/backup/config/restic.env && restic snapshots --json | jq length')"
echo "Next scheduled backup: $(systemctl list-timers restic_backup_backup.timer --no-pager | grep restic_backup_backup.timer | awk '{print $1, $2}')"
echo ""
echo "Recent backup log (last 5 lines):"
tail -5 /opt/restic_backup/backup/logs/backup.log
```

## Security Considerations

1. **Repository Password**: Always change the default password in production
2. **AWS Credentials**: Use IAM roles when possible, or store credentials securely
3. **File Permissions**: The role sets appropriate file permissions for security
4. **Network Access**: Restic typically doesn't require inbound firewall rules
5. **Encryption**: All backups are encrypted by default
6. **Service User**: Runs as dedicated `restic` user with minimal privileges

## Troubleshooting

### Common Issues

1. **Repository initialization fails**: Check repository URL and credentials
2. **Backup fails**: Verify backup paths exist and are accessible
3. **Timer not running**: Check systemd timer status and logs
4. **Permission issues**: Verify file permissions and user setup

### Debug Mode

Enable debug logging by setting:
```yaml
restic_log_level: "debug"
```

### Manual Repository Initialization

If automatic initialization fails:
```bash
sudo -u restic restic init
```

### Check Systemd Services

```bash
# List all restic services
systemctl list-units restic_backup_backup*

# Check service logs
journalctl -u restic_backup_backup --no-pager

# Check timer status
systemctl list-timers restic_backup_backup*
```

### Backup Monitoring and Management Commands

**PostgreSQL Database Backup Monitoring:**

```bash
# Check database configuration
cat /opt/restic_backup/backup/config/databases.conf

# Check database dump directory
ls -la /opt/restic_backup/backup/db-dumps/

# Check database dump logs
tail -f /opt/restic_backup/backup/logs/backup.log | grep -i postgres

# Verify database dumps are being created
sudo -u restic /opt/restic_backup/backup/scripts/pg_dump.sh

# Test database connectivity from restic user
sudo -u restic docker exec postgres_test pg_isready -h localhost -p 5432

# Check database dump sizes
du -h /opt/restic_backup/backup/db-dumps/*/*.sql
```

**Restore Database from Backup:**

```bash
# List available database dumps in backup
sudo -u restic bash -c 'source /opt/restic_backup/backup/config/restic.env && restic find db-dumps'

# Restore database dumps to temporary location
sudo -u restic bash -c 'source /opt/restic_backup/backup/config/restic.env && restic restore latest --target /tmp/restore --include "*/db-dumps/*"'

# Restore specific database from dump file
docker exec -i postgres_test pg_restore \
    -h localhost \
    -p 5432 \
    -U postgres \
    -d postgres \
    --clean \
    --verbose < /tmp/restore/opt/restic_backup/backup/db-dumps/postgres_test/postgres_20240315_143022.sql
```

## License

MIT