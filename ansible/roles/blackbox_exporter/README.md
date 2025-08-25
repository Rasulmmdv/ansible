# Blackbox Exporter Role

This Ansible role deploys the Prometheus Blackbox Exporter for monitoring external endpoints, including website availability.

## Features

- Deploys Blackbox Exporter via Docker Compose
- Configures HTTP, TCP, ICMP, and DNS probing modules
- Integrates with existing Prometheus setup
- Optional website endpoint monitoring with configurable targets

## Configuration

### Default Variables

```yaml
# Basic configuration
blackbox_exporter_image: "prom/blackbox-exporter:latest"
blackbox_exporter_container_name: "blackbox_exporter"
blackbox_exporter_data_dir: "/opt/blackbox_exporter"
blackbox_exporter_ports:
  - "9115:9115"

# Website monitoring configuration
blackbox_enable_website_monitoring: false
blackbox_endpoints_config_file: "/opt/blackbox_exporter/endpoints.yml"

# Multiple endpoints configuration
blackbox_endpoints:
  - name: "main-website"
    url: "http://your-website.com"
    module: "http_2xx"
    interval: "30s"
  - name: "api-endpoint"
    url: "https://api.your-website.com/health"
    module: "http_2xx"
    interval: "60s"

```

### Website Monitoring

#### Multiple Endpoints (Recommended)
```yaml
- hosts: monitoring_servers
  vars:
    blackbox_enable_website_monitoring: true
    blackbox_endpoints:
      - name: "production-website"
        url: "https://example.com"
        module: "http_2xx"
        interval: "30s"
        timeout: "10s"
        headers:
          User-Agent: "Prometheus/Blackbox Exporter"
      - name: "api-health"
        url: "https://api.example.com/health"
        module: "http_2xx"
        interval: "60s"
      - name: "database-connection"
        url: "tcp://db.example.com:5432"
        module: "tcp_connect"
        interval: "30s"
  roles:
    - blackbox_exporter
```

## Usage

### Basic Deployment

```yaml
- hosts: monitoring_servers
  roles:
    - blackbox_exporter
```

### With Website Monitoring

```yaml
- hosts: monitoring_servers
  vars:
    blackbox_enable_website_monitoring: true
    blackbox_target_endpoint: "https://example.com"
  roles:
    - prometheus
    - blackbox_exporter
```

## Metrics

The Blackbox Exporter provides the following key metrics:

- `probe_success`: 1 if the probe succeeded, 0 otherwise
- `probe_duration_seconds`: Duration of the probe in seconds
- `probe_http_status_code`: HTTP status code (for HTTP probes)
- `probe_http_duration_seconds`: Duration of HTTP request

## Available Modules

The role configures several probing modules:

- `http_2xx`: HTTP GET requests expecting 2xx status codes
- `http_post_2xx`: HTTP POST requests expecting 2xx status codes
- `tcp_connect`: TCP connection testing
- `icmp`: ICMP ping testing
- `dns`: DNS query testing

## Configuration Files

### Endpoints Configuration (`endpoints.yml`)
The role creates a configuration file at `{{ blackbox_exporter_data_dir }}/endpoints.yml` that defines all monitored endpoints. This file can be manually edited after deployment to add/remove endpoints without redeploying the entire role.

### Prometheus Integration
When website monitoring is enabled, the role automatically:

1. Creates a separate Prometheus configuration file (`blackbox_targets.yml`)
2. Configures individual scrape jobs for each endpoint
3. Sets up proper relabeling rules for target identification
4. Restarts Prometheus to apply changes

## Integration with Prometheus

When website monitoring is enabled, the role automatically:

1. Creates a separate configuration file for blackbox targets
2. Configures individual scrape jobs for each endpoint with custom intervals
3. Sets up proper relabeling rules for target identification
4. Restarts Prometheus to apply changes

## Example Playbook

See `ansible/playbooks/blackbox_website_monitoring.yml` for a complete example. 