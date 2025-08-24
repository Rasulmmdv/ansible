# Ansible Role Tagging Guide

## Overview
This guide documents the standardized tagging strategy implemented across all Ansible roles in this infrastructure. Tags enable selective execution of specific tasks, improving deployment efficiency and operational flexibility.

## Tag Categories

### 1. Lifecycle Tags (Primary)
| Tag | Description | Usage |
|-----|-------------|-------|
| `prereq` | Prerequisites and dependency checks | System preparation, validation |
| `install` | Package installation and system setup | Software installation, repositories |
| `configure` | Configuration file creation and setup | Templates, configs, directories |
| `deploy` | Service deployment and container startup | Docker compose, systemd services |
| `validate` | Health checks and validation | Service health, connectivity tests |
| `maintain` | Maintenance, updates, and ongoing operations | Updates, cleanup, optimization |

### 2. Functional Tags (Secondary)
| Tag | Description | Usage |
|-----|-------------|-------|
| `security` | Security-related tasks | Firewall, certificates, permissions |
| `networking` | Network configuration and connectivity | Networks, DNS, routing |
| `storage` | Storage, volumes, and data management | Directories, volumes, backups |
| `monitoring` | Monitoring, metrics, and observability | Metrics, alerts, dashboards |
| `backup` | Backup and recovery operations | Data backup, restore procedures |
| `logs` | Logging configuration and management | Log collection, rotation |

### 3. Component Tags (Tertiary)
| Tag | Description | Usage |
|-----|-------------|-------|
| `docker` | Docker-related operations | Containers, compose, networks |
| `systemd` | Systemd service management | Services, timers, units |
| `web` | Web servers and HTTP services | HTTP, HTTPS, proxies |
| `database` | Database operations | DB setup, backup, maintenance |
| `proxy` | Reverse proxy and load balancing | Traefik, Nginx, routing |
| `metrics` | Metrics collection and exposure | Exporters, collectors |

## Usage Examples

### 1. Selective Execution by Phase
```bash
# Install phase only
ansible-playbook site.yml --tags "install"

# Configuration without deployment
ansible-playbook site.yml --tags "configure" --skip-tags "deploy"

# Validation and health checks only
ansible-playbook site.yml --tags "validate"

# Complete deployment without prerequisites
ansible-playbook site.yml --skip-tags "prereq"
```

### 2. Selective Execution by Function
```bash
# Security-related tasks only
ansible-playbook site.yml --tags "security"

# Monitoring stack deployment
ansible-playbook site.yml --tags "monitoring,metrics"

# Network configuration only
ansible-playbook site.yml --tags "networking"

# Storage and backup operations
ansible-playbook site.yml --tags "storage,backup"
```

### 3. Component-Specific Operations
```bash
# Docker-related tasks only
ansible-playbook site.yml --tags "docker"

# Web services only
ansible-playbook site.yml --tags "web"

# Systemd service management
ansible-playbook site.yml --tags "systemd"

# Database operations
ansible-playbook site.yml --tags "database"
```

### 4. Combined Tag Strategies
```bash
# Install and configure, but don't deploy
ansible-playbook site.yml --tags "install,configure" --skip-tags "deploy"

# Deploy web services and validate
ansible-playbook site.yml --tags "deploy,web,validate"

# Security and networking configuration only
ansible-playbook site.yml --tags "security,networking"

# Monitoring setup without web interfaces
ansible-playbook site.yml --tags "monitoring,metrics" --skip-tags "web"
```

## Role-Specific Tag Implementation

### Infrastructure Roles

#### **common**
- `[prereq, install]` - System preparation and package cache
- `[install, configure, systemd]` - Essential utilities installation
- `[install, networking]` - Network utilities
- `[install, monitoring]` - Monitoring tools
- `[configure, docker, systemd]` - Docker service management
- `[configure, docker, networking]` - Docker networks
- `[configure, storage, monitoring]` - Directory structure

#### **docker**
- `[prereq, security, docker]` - Cleanup old installations
- `[prereq, configure, docker]` - Repository configuration
- `[prereq, install, docker]` - Dependency installation
- `[install, configure, docker]` - Docker engine installation
- `[configure, docker, systemd]` - Service configuration
- `[deploy, docker, systemd]` - Service startup
- `[validate, docker]` - Installation validation

#### **iptables**
- `[prereq, validate, docker]` - Docker detection
- `[configure, security, networking]` - Firewall rules
- `[install, security]` - Package installation
- `[validate, security]` - Rule validation

### Application Roles

#### **traefik**
- `[prereq, validate]` - Configuration validation
- `[install, prereq]` - Prerequisites installation
- `[configure, security]` - User and directory setup
- `[configure, networking, security]` - SSL/TLS configuration
- `[deploy, docker, web]` - Service deployment
- `[validate, web]` - Health checks

#### **jenkins**
- `[prereq, validate]` - Configuration validation
- `[install, configure, docker]` - Infrastructure setup
- `[configure, security]` - User permissions and directories
- `[deploy, docker, web]` - Container deployment
- `[validate, web]` - Service validation

#### **monitoring-stack**
- `[install, configure]` - Infrastructure setup
- `[configure]` - Configuration initialization
- `[install, configure, validate]` - Dependency checks
- `[deploy]` - Service deployment
- `[validate]` - Health validation

### Monitoring Roles

#### **prometheus**
- `[install, configure]` - Setup and configuration
- `[configure, deploy]` - Configuration deployment
- `[deploy, start]` - Service startup
- `[validate]` - Health checks

#### **grafana**
- `[configure, deploy]` - Configuration and deployment
- `[deploy, start]` - Service startup
- `[validate]` - Interface validation

#### **node_exporter**
- `[install]` - Package installation
- `[install, configure]` - Service configuration
- `[configure]` - Runtime configuration
- `[validate]` - Metrics validation

## Best Practices

### 1. Tag Assignment Guidelines
- **Every task** should have at least one lifecycle tag
- **Most tasks** should have 2-3 tags (lifecycle + functional + component)
- **Maximum 4 tags** per task to avoid over-tagging
- **Use consistent naming** following the documented conventions

### 2. Tag Naming Conventions
- Use **lowercase only**
- Use **underscores** for multi-word tags (e.g., `health_check`)
- Keep tags **concise but descriptive**
- Avoid **redundant prefixes** (use `docker` not `docker_config`)

### 3. Testing Tag Implementations
```bash
# Test specific tag combinations in check mode
ansible-playbook site.yml --tags "install" --check --diff

# Validate tag coverage
ansible-playbook site.yml --list-tasks --tags "deploy"

# Test skip combinations
ansible-playbook site.yml --skip-tags "deploy,validate" --check
```

## Tag Coverage by Role

| Role | Prereq | Install | Configure | Deploy | Validate | Security | Docker | Web |
|------|--------|---------|-----------|--------|----------|----------|--------|-----|
| common | ✅ | ✅ | ✅ | ➖ | ➖ | ➖ | ✅ | ➖ |
| docker | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ➖ |
| iptables | ✅ | ✅ | ✅ | ➖ | ✅ | ✅ | ✅ | ➖ |
| traefik | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| jenkins | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| monitoring-stack | ✅ | ✅ | ✅ | ✅ | ✅ | ➖ | ✅ | ➖ |

**Legend:** ✅ Implemented | ➖ Not applicable | 🚧 Partial implementation

## Troubleshooting

### Common Issues

1. **Tag not found**: Ensure tag is spelled correctly and exists in the role
2. **Unexpected task execution**: Check for inherited tags from blocks or includes
3. **Tasks skipped**: Verify tag combinations and skip-tags usage
4. **Performance issues**: Avoid running too many small tag combinations

### Debugging Tag Usage
```bash
# List all available tags
ansible-playbook site.yml --list-tags

# List tasks for specific tags
ansible-playbook site.yml --list-tasks --tags "configure,security"

# Dry run with verbose output
ansible-playbook site.yml --tags "deploy" --check --diff -v
```

## Migration Status

### ✅ Completed Roles
- **common** - Full tag implementation
- **iptables** - Core tags implemented
- **traefik** - Strategic tags implemented

### 🚧 Partial Implementation
- **docker** - Needs comprehensive tag updates
- **jenkins** - Basic tags in place, needs completion
- **monitoring-stack** - Has existing tags, needs standardization

### ⏳ Pending Roles
- **restic** - Needs tag implementation
- **tailscale** - Needs standardization
- **prometheus** - Needs validation tags
- **grafana** - Needs component tags
- **node_exporter** - Good baseline, needs completion

---

**Last Updated:** 2025-08-20  
**Strategy Version:** 1.0  
**Implementation Status:** 40% Complete  
**Next Review:** Quarterly