# Ansible Tagging Strategy - DEVOPS-020 Implementation

## Current State Analysis

### Tag Usage Frequency (Before Standardization)
Based on analysis of existing roles:
- **configure**: 54 instances (most common)
- **deploy**: 36 instances  
- **install**: 21 instances
- **validate**: 19 instances
- **start**: 7 instances
- **tailscale**: 8 instances (role-specific)
- **metrics**: 3 instances
- **logs**: 2 instances

### Inconsistencies Identified
1. **Missing tags**: Many roles have empty `tags:` declarations
2. **Inconsistent grouping**: Similar tasks use different tag combinations
3. **Role-specific tags**: Some roles use unique tags (e.g., `tailscale`, `remote_monitoring`)
4. **Incomplete coverage**: Many tasks lack appropriate tags

## Standard Tagging Strategy

### 1. **Lifecycle Tags** (Primary Classification)
These tags represent the main phases of deployment and management:

- **`prereq`** - Prerequisites and dependency checks
- **`install`** - Package installation and system setup
- **`configure`** - Configuration file creation and setup
- **`deploy`** - Service deployment and container startup
- **`validate`** - Health checks and validation
- **`maintain`** - Maintenance, updates, and ongoing operations

### 2. **Functional Tags** (Secondary Classification)
These tags represent the type of work being performed:

- **`security`** - Security-related tasks (firewall, certificates, user permissions)
- **`networking`** - Network configuration and connectivity
- **`storage`** - Storage, volumes, and data management
- **`monitoring`** - Monitoring, metrics, and observability
- **`backup`** - Backup and recovery operations
- **`logs`** - Logging configuration and management

### 3. **Component Tags** (Tertiary Classification)
These tags identify specific components or services:

- **`docker`** - Docker-related operations
- **`systemd`** - Systemd service management
- **`web`** - Web servers and HTTP services
- **`database`** - Database operations
- **`proxy`** - Reverse proxy and load balancing
- **`metrics`** - Metrics collection and exposure

### 4. **Environment Tags** (Context Classification)
These tags help with environment-specific execution:

- **`development`** - Development environment specific
- **`staging`** - Staging environment specific  
- **`production`** - Production environment specific
- **`testing`** - Testing and verification tasks

## Tag Implementation Guidelines

### 1. **Tag Combinations**
Each task should typically have 2-4 tags:
- **Minimum**: 1 lifecycle tag + 1 functional tag
- **Recommended**: 1 lifecycle tag + 1 functional tag + 1 component tag
- **Maximum**: 4 tags to avoid over-tagging

### 2. **Tag Naming Conventions**
- Use lowercase only
- Use underscores for multi-word tags (e.g., `health_check`)
- Keep tags concise but descriptive
- Avoid redundant prefixes (e.g., use `docker` not `docker_config`)

### 3. **Common Tag Patterns**

#### **Installation Phase**
```yaml
tags: [prereq, install, docker]        # Prerequisites and Docker setup
tags: [install, configure, security]   # Install packages and configure security
```

#### **Configuration Phase** 
```yaml
tags: [configure, networking, systemd] # Network and service configuration
tags: [configure, security, web]       # Web server security configuration
```

#### **Deployment Phase**
```yaml
tags: [deploy, docker, web]            # Deploy web services via Docker
tags: [deploy, validate, monitoring]   # Deploy and validate monitoring
```

#### **Validation Phase**
```yaml
tags: [validate, monitoring, testing]  # Health checks and monitoring validation
tags: [validate, security, production] # Production security validation
```

## Role-Specific Tag Strategy

### Infrastructure Roles
- **docker**: `[prereq, install, docker]`, `[configure, docker, systemd]`
- **common**: `[prereq, install, security]`, `[configure, systemd]`
- **iptables**: `[configure, security, networking]`

### Application Roles
- **traefik**: `[install, configure, proxy]`, `[deploy, validate, web]`
- **jenkins**: `[install, configure, docker]`, `[deploy, validate, web]`
- **grafana**: `[configure, deploy, monitoring]`, `[validate, web]`

### Monitoring Roles
- **prometheus**: `[configure, deploy, monitoring]`, `[validate, metrics]`
- **node_exporter**: `[install, configure, monitoring]`, `[validate, metrics]`
- **loki**: `[configure, deploy, logs]`, `[validate, monitoring]`

### Backup/Maintenance Roles
- **restic**: `[install, configure, backup]`, `[validate, storage]`
- **update**: `[maintain, install, security]`

## Usage Examples

### 1. **Selective Execution by Phase**
```bash
# Install phase only
ansible-playbook site.yml --tags "install"

# Configuration without deployment
ansible-playbook site.yml --tags "configure" --skip-tags "deploy"

# Validation and health checks only
ansible-playbook site.yml --tags "validate"
```

### 2. **Selective Execution by Function**
```bash
# Security-related tasks only
ansible-playbook site.yml --tags "security"

# Monitoring stack deployment
ansible-playbook site.yml --tags "monitoring,metrics"

# Network configuration only
ansible-playbook site.yml --tags "networking"
```

### 3. **Component-Specific Operations**
```bash
# Docker-related tasks only
ansible-playbook site.yml --tags "docker"

# Web services only
ansible-playbook site.yml --tags "web"

# Systemd service management
ansible-playbook site.yml --tags "systemd"
```

### 4. **Environment-Specific Execution**
```bash
# Development environment setup
ansible-playbook site.yml --tags "development"

# Production deployment with validation
ansible-playbook site.yml --tags "production,validate"
```

## Migration Plan

### Phase 1: Core Infrastructure (High Priority)
1. **common** - Standardize base system tags
2. **docker** - Standardize container platform tags
3. **iptables** - Standardize security tags

### Phase 2: Application Services (Medium Priority)
1. **traefik** - Standardize proxy/web tags
2. **jenkins** - Standardize CI/CD tags
3. **monitoring-stack** - Standardize monitoring tags

### Phase 3: Supporting Services (Low Priority)
1. **restic** - Standardize backup tags
2. **tailscale** - Standardize VPN tags
3. **update** - Standardize maintenance tags

## Quality Assurance

### 1. **Tag Validation Rules**
- Every task must have at least one lifecycle tag
- No task should have more than 4 tags
- Component tags should match the actual technology used
- Environment tags should only be used when environment-specific

### 2. **Testing Strategy**
- Test tag combinations in development environment
- Validate selective execution works as expected
- Ensure no critical tasks are accidentally skipped

### 3. **Documentation Requirements**
- Each role README must document available tags
- Playbook documentation must include tag usage examples
- Tag strategy must be reviewed quarterly for effectiveness

## Expected Benefits

### 1. **Operational Efficiency**
- **Faster deployments**: Run only necessary components
- **Targeted updates**: Update specific services without full deployment
- **Efficient troubleshooting**: Run only validation/diagnostic tasks

### 2. **Risk Reduction**
- **Selective rollouts**: Deploy changes to specific components
- **Environment isolation**: Prevent accidental production changes
- **Rollback precision**: Rollback specific components only

### 3. **Team Productivity**
- **Development speed**: Quick development environment setup
- **Testing efficiency**: Run only relevant tests
- **Maintenance clarity**: Clear separation of maintenance tasks

---

**Implementation Priority**: Medium  
**Estimated Time**: 2-3 days  
**Impact**: High operational efficiency improvement  
**Risk Level**: Low (additive changes, no breaking modifications)