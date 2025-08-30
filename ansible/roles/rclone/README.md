# Rclone Role

This role installs and configures [Rclone](https://rclone.org/) - a command-line program to manage files on cloud storage.

## Requirements

- Ubuntu/Debian-based system
- Internet access for downloading Rclone binary
- Proper permissions for installation and configuration

## Variables

### Required Variables

- `rclone_configs`: Dictionary of Rclone remote configurations
  ```yaml
  rclone_configs:
    myremote:
      type: s3
      provider: AWS
      access_key_id: "your-access-key"
      secret_access_key: "your-secret-key"
      region: us-east-1
  ```

### Optional Variables

- `rclone_version`: Rclone version to install (default: `v1.70.0`)
- `rclone_arch`: System architecture (default: auto-detected from `ansible_architecture`)
- `rclone_install_path`: Installation path for rclone binary (default: `/usr/local/bin`)
- `rclone_conf_path`: Configuration directory path (default: `~/.config/rclone`)

## Usage

### Basic Installation

```yaml
- hosts: servers
  roles:
    - role: rclone
```

### Configure S3 Remote

```yaml
- hosts: servers
  roles:
    - role: rclone
      vars:
        rclone_configs:
          mys3:
            type: s3
            provider: AWS
            access_key_id: "{{ lookup('env', 'AWS_ACCESS_KEY_ID') }}"
            secret_access_key: "{{ lookup('env', 'AWS_SECRET_ACCESS_KEY') }}"
            region: us-east-1
            bucket: my-backup-bucket
```

### Configure Google Drive Remote

```yaml
- hosts: servers
  roles:
    - role: rclone
      vars:
        rclone_configs:
          mydrive:
            type: drive
            client_id: "your-client-id"
            client_secret: "your-client-secret"
            scope: drive
            token: '{"access_token":"...","token_type":"Bearer","refresh_token":"...","expiry":"..."}'
```

### Configure Dropbox Remote

```yaml
- hosts: servers
  roles:
    - role: rclone
      vars:
        rclone_configs:
          mydropbox:
            type: dropbox
            token: '{"access_token":"...","token_type":"bearer","expiry":"..."}'
```

## Supported Storage Types

Rclone supports numerous cloud storage providers and protocols:

- Amazon S3
- Google Drive
- Dropbox
- Microsoft OneDrive
- Google Cloud Storage
- Azure Blob Storage
- SFTP
- FTP
- HTTP
- Local filesystem
- And many more...

## Features

- Installs latest stable Rclone binary
- Auto-detects system architecture
- Creates secure configuration files
- Supports multiple remote configurations
- Idempotent operations
- Proper cleanup of temporary files

## Examples

### Backup to S3

```yaml
rclone_configs:
  backup:
    type: s3
    provider: AWS
    access_key_id: "{{ aws_access_key }}"
    secret_access_key: "{{ aws_secret_key }}"
    region: us-west-2
    bucket: my-backups
```

After installation, you can use:

```bash
rclone copy /local/path backup:/remote/path
rclone sync /local/path backup:/remote/path
```

### Sync with Google Drive

```yaml
rclone_configs:
  gdrive:
    type: drive
    client_id: "your-client-id"
    client_secret: "your-client-secret"
    scope: drive
    token: "{{ google_drive_token }}"
```

Usage:
```bash
rclone copy gdrive:/remote/file /local/path
```

## Notes

- Configuration files are stored with restrictive permissions (0600)
- The role uses temporary directories for downloads that are automatically cleaned up
- All operations are idempotent and can be run multiple times safely
- Environment variables should be used for sensitive credentials instead of storing them in plain text
