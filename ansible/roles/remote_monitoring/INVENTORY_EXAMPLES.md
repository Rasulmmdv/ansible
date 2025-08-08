# Inventory Configuration Examples

This guide shows how to configure the `remote_monitoring` role for different servers with different IPs and hostnames.

## Basic Inventory Structure

Configure your inventory to set the required variables per host:

```yaml
---
all:
  children:
    production:
      hosts:
        prod-01:
          ansible_host: 188.124.37.101
          ansible_user: root
          # Production server configuration
          monitoring_server_host: "infra-01"  # VPN network hostname
          nginx_status_allowed_ips:
            - "127.0.0.1"
            - "::1"
            - "10.0.0.5"  # infra-01 on VPN network
          remote_monitoring_labels:
            instance: "prod-01"
            environment: "production"
            service: "nginx"
            datacenter: "primary"
            team: "web"
            deployment_type: "docker"
          remote_monitoring_scrape_interval: "15s"
    
    development:
      hosts:
        dev-01:
          ansible_host: 192.168.1.100  # Your dev server IP
          ansible_user: root
          # Development server configuration
          monitoring_server_host: "192.168.1.16"  # Dev monitoring server IP
          nginx_status_allowed_ips:
            - "127.0.0.1"
            - "::1"
            - "192.168.1.16"  # Dev monitoring server
          remote_monitoring_labels:
            instance: "dev-01"
            environment: "development"
            service: "nginx"
            datacenter: "dev"
            team: "web"
            deployment_type: "docker"
          remote_monitoring_scrape_interval: "30s"
    
    testing:
      hosts:
        test-01:
          ansible_host: 82.202.197.209
          ansible_user: root
          # Test server configuration
          monitoring_server_host: "infra-01"  # VPN network hostname
          nginx_status_allowed_ips:
            - "127.0.0.1"
            - "::1"
            - "10.0.0.5"  # infra-01 on VPN network
          remote_monitoring_labels:
            instance: "test-01"
            environment: "testing"
            service: "nginx"
            datacenter: "primary"
            team: "web"
            deployment_type: "docker"
          remote_monitoring_scrape_interval: "60s"
```

## Configuration Variables Explained

### Required Variables (set per host)

#### `monitoring_server_host`
The hostname or IP of your monitoring server where Prometheus runs.

**Examples:**
- `"infra-01"` - VPN network hostname
- `"192.168.1.16"` - Direct IP address
- `"monitoring.example.com"` - DNS hostname

#### `nginx_status_allowed_ips`
List of IP addresses allowed to access the nginx_status endpoint.

**Examples:**
```yaml
nginx_status_allowed_ips:
  - "127.0.0.1"      # Localhost
  - "::1"            # IPv6 localhost
  - "10.0.0.5"       # VPN network monitoring server
  - "192.168.1.16"   # Direct IP monitoring server
  - "10.0.0.0/24"    # Entire VPN subnet
```

#### `remote_monitoring_labels`
Labels applied to Prometheus metrics for organization and filtering.

**Examples:**
```yaml
remote_monitoring_labels:
  instance: "prod-01"
  environment: "production"
  service: "nginx"
  datacenter: "primary"
  team: "web"
  deployment_type: "docker"
  region: "eu-west"
  tier: "frontend"
```

#### `remote_monitoring_scrape_interval`
How often Prometheus scrapes metrics from this server.

**Examples:**
- `"15s"` - Production (frequent)
- `"30s"` - Development (moderate)
- `"60s"` - Testing (less frequent)

## Different Network Scenarios

### 1. VPN Network (Production/Test)
```yaml
prod-01:
  ansible_host: 188.124.37.101
  monitoring_server_host: "infra-01"
  nginx_status_allowed_ips:
    - "127.0.0.1"
    - "::1"
    - "10.0.0.5"  # infra-01 VPN IP
```

### 2. Local Network (Development)
```yaml
dev-01:
  ansible_host: 192.168.1.100
  monitoring_server_host: "192.168.1.16"
  nginx_status_allowed_ips:
    - "127.0.0.1"
    - "::1"
    - "192.168.1.16"  # Local monitoring server
```

### 3. Public Network (Cloud)
```yaml
cloud-01:
  ansible_host: 203.0.113.10
  monitoring_server_host: "monitoring.example.com"
  nginx_status_allowed_ips:
    - "127.0.0.1"
    - "::1"
    - "203.0.113.100"  # Cloud monitoring server
```

## Usage Examples

### Deploy to Specific Environment
```bash
# Deploy to production servers
ansible-playbook -i inventory.yml ansible/playbooks/remote_monitoring.yml --limit production

# Deploy to development servers
ansible-playbook -i inventory.yml ansible/playbooks/remote_monitoring.yml --limit development

# Deploy to test servers
ansible-playbook -i inventory.yml ansible/playbooks/remote_monitoring.yml --limit testing
```

### Deploy to Specific Server
```bash
# Deploy to specific server
ansible-playbook -i inventory.yml ansible/playbooks/remote_monitoring.yml --limit dev-01

# Deploy to multiple specific servers
ansible-playbook -i inventory.yml ansible/playbooks/remote_monitoring.yml --limit "prod-01,test-01"
```

## Verification Commands

### Check Configuration
```bash
# Verify nginx_status is accessible
curl http://your-server:80/nginx_status

# Verify nginx_exporter metrics
curl http://your-server:9113/metrics

# Check Prometheus targets (replace with your monitoring server)
curl http://your-monitoring-server:9090/targets
```

### Check Labels in Prometheus
```prometheus
# Query with specific labels
nginx_requests_total{environment="production"}
nginx_requests_total{environment="development"}
nginx_requests_total{instance="prod-01"}
```

## Tips

1. **Use descriptive hostnames** in your inventory for better organization
2. **Group servers by environment** (production, development, testing)
3. **Use consistent labeling** across similar servers
4. **Test with one server first** before deploying to all
5. **Monitor Prometheus targets** to ensure all servers are being scraped 