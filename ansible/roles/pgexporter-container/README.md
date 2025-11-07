# PostgreSQL Exporter Container Role

This Ansible role deploys PostgreSQL Exporter as a Docker container for monitoring PostgreSQL databases with Prometheus.

## Features

- Deploys PostgreSQL Exporter as a Docker container
- Uses Docker Compose for container orchestration
- Configurable container networking and port mapping
- Health checks for container monitoring
- Service discovery integration with Prometheus
- Firewall management with UFW/iptables
- Idempotent and check-mode safe

## Requirements

- Docker and Docker Compose installed on target hosts
- PostgreSQL database accessible from the container
- Ansible 2.9+ with docker collection

## Role Variables

### Required Variables

These variables must be provided in your playbook or inventory:

```yaml
pgexporter_postgres_host: "localhost"          # PostgreSQL host
pgexporter_postgres_port: 5432                 # PostgreSQL port
pgexporter_postgres_user: "postgres"           # PostgreSQL user
pgexporter_postgres_password: "changeme"       # PostgreSQL password
pgexporter_postgres_db: "postgres"             # PostgreSQL database
```

### Optional Variables

```yaml
# Container configuration
pgexporter_container_name: "postgres-exporter"
pgexporter_container_image: "prometheuscommunity/postgres-exporter"
pgexporter_container_tag: "v0.17.1"
pgexporter_container_restart_policy: "unless-stopped"

# Networking
pgexporter_container_port: "9187"
pgexporter_host_port: "9187"
pgexporter_container_network: "monitoring"

# Service discovery
pgexporter_service_discovery_enabled: true
pgexporter_generate_prometheus_targets: false

# Firewall
pgexporter_manage_firewall: true
pgexporter_allowed_sources: [10.0.0.0/24]
```

## Usage

### Basic Usage

```yaml
- hosts: all
  become: true
  roles:
    - pgexporter-container
  vars:
    pgexporter_postgres_host: "db.example.com"
    pgexporter_postgres_user: "monitoring"
    pgexporter_postgres_password: "secure_password"
    pgexporter_postgres_db: "postgres"
```

### With Custom Configuration

```yaml
- hosts: all
  become: true
  roles:
    - pgexporter-container
  vars:
    pgexporter_postgres_host: "db.example.com"
    pgexporter_postgres_user: "monitoring"
    pgexporter_postgres_password: "secure_password"
    pgexporter_postgres_db: "postgres"
    pgexporter_host_port: "9188"
    pgexporter_container_network: "custom-monitoring"
    pgexporter_manage_firewall: true
    pgexporter_allowed_sources: 
      - "10.0.0.0/24"
      - "192.168.1.0/24"
```

## Tags

The role supports the following tags for selective execution:

- `install`: Install Docker and create directories
- `configure`: Configure containers and networking
- `monitoring`: Set up monitoring and service discovery
- `docker`: Docker-specific tasks
- `networking`: Network configuration tasks

### Example: Run only configuration tasks

```bash
ansible-playbook pgexporter-container.yml --tags configure
```

## Service Discovery

The role can generate Prometheus service discovery files. Enable this on your Prometheus host:

```yaml
pgexporter_generate_prometheus_targets: true
pgexporter_prometheus_config_dir: "/opt/monitoring/prometheus/config"
```

## Health Checks

The container includes built-in health checks that verify the metrics endpoint is accessible:

- Check interval: 30s
- Timeout: 10s
- Retries: 3
- Start period: 40s

## Firewall Management

The role can manage firewall rules to allow access to the PostgreSQL Exporter:

- Allows access from monitoring subnet
- Allows access from explicitly defined sources
- Uses iptables for rule management

## Dependencies

- Docker and Docker Compose
- Common role for variable validation

## License

This role follows the same license as the main project.

## Author Information

Created as a containerized version of the pgexporter role for Docker-based deployments.


