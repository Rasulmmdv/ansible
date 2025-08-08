# Alertmanager Ansible Role

This role deploys Prometheus Alertmanager as a Docker container for centralized alert management with email and Telegram notifications.

## Features
- Installs Alertmanager using Docker Compose
- Configures email notifications via SMTP
- Configures Telegram notifications via bot API
- Integrates with existing Prometheus setup
- Provides alert routing based on severity levels
- Includes alert inhibition rules

## Usage
Include this role in your playbook:
```yaml
- hosts: all
  vars:
    alertmanager_email_smtp: "smtp.gmail.com:587"
    alertmanager_email_from: "alertmanager@yourdomain.com"
    alertmanager_email_to: "admin@yourdomain.com"
    alertmanager_email_auth_username: "your-email@gmail.com"
    alertmanager_email_auth_password: "your-app-password"
    alertmanager_telegram_bot_token: "your_bot_token"
    alertmanager_telegram_chat_id: "your_chat_id"
  roles:
    - prometheus
    - alertmanager
```

## Architecture

```
+-------------------+        +-------------------+
|     Prometheus    |        |   Alertmanager    |
|  +-------------+  |        |  +-------------+  |
|  | Alert Rules |  |------->|  | Email       |  |
|  | Metrics     |  |        |  | Telegram    |  |
|  +-------------+  |        |  +-------------+  |
+-------------------+        +-------------------+
         |                              |
         |                              |
         v                              v
+-------------------+        +-------------------+
|    Email Server   |        |   Telegram Bot    |
+-------------------+        +-------------------+
```

## Configuration

### Default Variables

```yaml
# Container configuration
alertmanager_image: "prom/alertmanager:latest"
alertmanager_container_name: "alertmanager"
alertmanager_data_dir: "/opt/alertmanager"
alertmanager_ports:
  - "9093:9093"

# Email configuration
alertmanager_email_smtp: "smtp.gmail.com:587"
alertmanager_email_from: "alertmanager@example.com"
alertmanager_email_to: "admin@example.com"
alertmanager_email_auth_username: ""
alertmanager_email_auth_password: ""

# Telegram configuration (optional)
alertmanager_telegram_bot_token: ""
alertmanager_telegram_chat_id: 0
alertmanager_telegram_api_url: "https://api.telegram.org"

# Alert routing
alertmanager_route_group_by: ['alertname']
alertmanager_route_group_wait: "30s"
alertmanager_route_group_interval: "5m"
alertmanager_route_repeat_interval: "4h"
```

### Alert Routing

The role configures three receivers:

1. **Default**: Sends both email and Telegram for all alerts
2. **Email**: Sends only email for warning-level alerts
3. **Telegram**: Sends only Telegram for critical-level alerts

### Alert Inhibition

Critical alerts will inhibit warning alerts for the same alert name and instance.

## Integration

### With Prometheus
- Automatically updates Prometheus configuration to include Alertmanager
- Configures alert rule file path
- Restarts Prometheus to apply changes

### With Grafana
- Alertmanager UI accessible at http://your-server:9093
- Alerts can be viewed and managed through the web interface
- Integration with Grafana for alert visualization

## Alert Rules

Create alert rules in `/opt/prometheus/rules/` directory. Example:

```yaml
groups:
  - name: node_alerts
    rules:
      - alert: HighCPUUsage
        expr: 100 - (avg by(instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High CPU usage on {{ $labels.instance }}"
          description: "CPU usage is above 80% for more than 5 minutes"

      - alert: HighMemoryUsage
        expr: (node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100 > 90
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "Critical memory usage on {{ $labels.instance }}"
          description: "Memory usage is above 90% for more than 2 minutes"
```

## Monitoring

- Alertmanager exposes metrics on port 9093
- Web UI available at http://your-server:9093
- Alert status and history tracking
- Integration with Prometheus for metrics collection

## Troubleshooting

### Check Alertmanager Status
```bash
docker ps | grep alertmanager
docker logs alertmanager
```

### Check Configuration
```bash
curl http://localhost:9093/api/v1/status
```

### Verify Prometheus Integration
1. Access Prometheus at http://your-server:9090
2. Go to Status → Alertmanagers
3. Verify Alertmanager is "Up"

### Test Alerts
1. Create a test alert rule
2. Trigger the alert condition
3. Check email and Telegram notifications

### Common Issues

1. **Email not sending**: Check SMTP credentials and firewall
2. **Telegram not sending**: Verify bot token and chat ID
3. **Prometheus not connecting**: Ensure containers are on same network
4. **Permission denied**: Check file ownership and permissions 