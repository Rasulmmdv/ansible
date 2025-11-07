# Reverse Proxy Strategy: Supporting Traefik and Nginx

## Problem Statement
We need to support both Traefik and Nginx in different environments while maintaining a single set of Ansible roles that can work with either proxy.

## Recommended Approaches

### 1. Environment Variable Selection (Recommended)
Use a central variable to select the reverse proxy for each environment.

**Implementation:**
- Add `reverse_proxy` variable in inventory/host_vars/group_vars
- Values: `"traefik"` or `"nginx"`
- Roles check this variable to conditionally run

**Pros:**
- Simple and explicit
- Easy to understand
- Clear per-environment configuration

**Cons:**
- Requires updating dependent roles
- Need validation to prevent both running simultaneously

---

### 2. Conditional Role Inclusion in Orchestration
Modify `group_vars/all/main.yml` to conditionally include reverse proxy roles.

**Implementation:**
```yaml
# In group_vars/all/main.yml or host_vars
reverse_proxy: "traefik"  # or "nginx"

roles_all:
  - docker
  - "{{ reverse_proxy }}"  # Dynamic role selection
  - portainer

role_dependencies:
  portainer: [docker, "{{ reverse_proxy }}"]
```

**Pros:**
- Leverages existing orchestration system
- Dependencies automatically handled
- No role modification needed

**Cons:**
- Ansible variable substitution in lists can be tricky
- Need validation in orchestration playbook

---

### 3. Abstraction Layer Pattern
Create a common interface/pattern that both proxies implement.

**Implementation:**
- Create `roles/reverse-proxy/` wrapper role
- Abstract common operations (SSL certs, routes, backends)
- Map to traefik/nginx implementations

**Pros:**
- Clean separation of concerns
- Easy to add more proxies later
- Consistent interface

**Cons:**
- More complex initially
- Requires refactoring existing roles
- Additional abstraction layer

---

### 4. Host/Group-Level Variables with Mutual Exclusion
Use inventory groups and ensure only one proxy runs per host.

**Implementation:**
- Create `host_vars/prod/traefik.yml` and `host_vars/prod/nginx.yml`
- Use `when` conditions to ensure mutual exclusion
- Validate in pre-tasks

**Pros:**
- Clear separation per environment
- No role modifications
- Easy to see which proxy is used where

**Cons:**
- Need multiple inventory configurations
- More files to manage

---

### 5. Feature Flag Pattern
Use feature flags in inventory to enable/disable proxies.

**Implementation:**
```yaml
# In inventory.yml
vars:
  traefik_enabled: true
  nginx_enabled: false
  
  # Validation
  reverse_proxy_count: "{{ [traefik_enabled, nginx_enabled] | select('bool') | list | length }}"
```

**Pros:**
- Explicit enable/disable
- Easy to validate
- Works with existing roles

**Cons:**
- Need validation logic
- Both roles need to exist (can skip tasks)

---

## Recommended Solution: Hybrid Approach

Combine **Approach 1 (Environment Variable)** + **Approach 5 (Feature Flags)** with validation.

### Step 1: Add Reverse Proxy Selection Variable

```yaml
# In group_vars/all/main.yml or host_vars
reverse_proxy: "traefik"  # Options: "traefik", "nginx", or "none"

# Feature flags (derived from reverse_proxy)
traefik_enabled: "{{ reverse_proxy == 'traefik' }}"
nginx_enabled: "{{ reverse_proxy == 'nginx' }}"
```

### Step 2: Update Orchestration Configuration

```yaml
# In group_vars/all/main.yml
roles_all:
  - docker
  # Conditional reverse proxy
  - traefik
  - nginx
  - portainer

role_dependencies:
  traefik: [docker]
  nginx: [docker]
  portainer: [docker, "{{ reverse_proxy }}"]  # Dynamic dependency
```

### Step 3: Add Validation in Orchestration Playbook

```yaml
# In playbooks/orchestrate.yml pre_tasks
- name: Validate reverse proxy selection
  assert:
    that:
      - reverse_proxy in ['traefik', 'nginx', 'none']
      - not (traefik_enabled and nginx_enabled)
    fail_msg: "reverse_proxy must be 'traefik', 'nginx', or 'none'. Cannot enable both."
```

### Step 4: Conditional Role Execution

```yaml
# In playbooks/orchestrate.yml tasks
- name: "Apply role: {{ item }}"
  include_role:
    name: "{{ item }}"
  loop: "{{ final_roles }}"
  when: |
    (item == 'traefik' and traefik_enabled) or
    (item == 'nginx' and nginx_enabled) or
    (item != 'traefik' and item != 'nginx')
```

### Step 5: Update Dependent Roles

For roles that depend on reverse proxy (like portainer):

```yaml
# In roles/portainer/tasks/main.yml
- name: Check reverse proxy type
  assert:
    that: reverse_proxy in ['traefik', 'nginx']
    fail_msg: "portainer requires a reverse proxy (traefik or nginx)"

# Conditional tasks based on proxy
- name: Configure Portainer for Traefik
  include_tasks: traefik_config.yml
  when: reverse_proxy == 'traefik'

- name: Configure Portainer for Nginx
  include_tasks: nginx_config.yml
  when: reverse_proxy == 'nginx'
```

---

## Alternative: Abstraction Helper Role

Create a helper role `reverse-proxy-common` that provides shared functionality:

```yaml
# roles/reverse-proxy-common/tasks/main.yml
- name: Set proxy facts
  set_fact:
    reverse_proxy_type: "{{ reverse_proxy }}"
    reverse_proxy_network: "{{ reverse_proxy }}-network"
    reverse_proxy_ssl_enabled: "{{ traefik_ssl_enabled | default(nginx_ssl_enabled, true) }}"
```

Then other roles can use these facts instead of checking traefik/nginx directly.

---

## Implementation Checklist

- [ ] Add `reverse_proxy` variable to inventory templates
- [ ] Update `group_vars/all/main.yml` with conditional logic
- [ ] Add validation in orchestration playbook
- [ ] Update orchestration to conditionally execute proxy roles
- [ ] Update dependent roles (portainer, etc.) to work with both
- [ ] Create abstraction tasks/facts if needed
- [ ] Update documentation with examples
- [ ] Test in both environments

---

## Example Inventory Structure

```yaml
# host_vars/prod-server.yml
reverse_proxy: "traefik"
traefik_domain: "prod.example.com"

# host_vars/dev-server.yml  
reverse_proxy: "nginx"
nginx_sites:
  app:
    - server_name dev.example.com
```

This keeps configuration clear and environment-specific while maintaining code reusability.


