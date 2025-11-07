# Implementation Example: Supporting Traefik and Nginx

## Step 1: Add Reverse Proxy Configuration Variable

### In `host_vars` or `group_vars`:

```yaml
# host_vars/prod-server.yml
reverse_proxy: "traefik"

# host_vars/dev-server.yml
reverse_proxy: "nginx"
```

Or at the group level:

```yaml
# group_vars/prod/main.yml
reverse_proxy: "traefik"

# group_vars/dev/main.yml
reverse_proxy: "nginx"
```

## Step 2: Update Central Orchestration Config

### Modified `group_vars/all/main.yml`:

```yaml
# Add at the top
reverse_proxy: "{{ reverse_proxy | default('traefik') }}"  # Default to traefik

# Feature flags
traefik_enabled: "{{ reverse_proxy == 'traefik' }}"
nginx_enabled: "{{ reverse_proxy == 'nginx' }}"

roles_all:
  # ... existing roles ...
  - docker
  - traefik              # Always listed, conditionally executed
  - nginx                # Always listed, conditionally executed
  - portainer
  # ... rest ...

role_dependencies:
  # ... existing dependencies ...
  traefik: [docker]
  nginx: [docker]
  portainer: [docker]  # Remove hard dependency on traefik
```

## Step 3: Update Orchestration Playbook

### Modified `playbooks/orchestrate.yml` pre_tasks:

```yaml
pre_tasks:
  # ... existing pre_tasks ...
  
  - name: Set reverse proxy flags
    set_fact:
      traefik_enabled: "{{ reverse_proxy | default('traefik') == 'traefik' }}"
      nginx_enabled: "{{ reverse_proxy | default('traefik') == 'nginx' }}"
    tags: always

  - name: Validate reverse proxy selection
    assert:
      that:
        - reverse_proxy | default('traefik') in ['traefik', 'nginx', 'none']
        - not (traefik_enabled and nginx_enabled)
      fail_msg: |
        Invalid reverse_proxy value: {{ reverse_proxy | default('traefik') }}.
        Must be 'traefik', 'nginx', or 'none'. Cannot enable both proxies.
    tags: always

  # ... rest of pre_tasks ...
```

### Modified `playbooks/orchestrate.yml` tasks:

```yaml
tasks:
  - name: "Apply role: {{ item }}"
    include_role:
      name: "{{ item }}"
      apply:
        tags: "{{ ansible_playbook_tags | default([]) }}"
    loop: "{{ final_roles }}"
    when: |
      (item == 'traefik' and traefik_enabled) or
      (item == 'nginx' and nginx_enabled) or
      (item != 'traefik' and item != 'nginx')
    loop_control:
      label: "{{ item }}"
```

## Step 4: Update Portainer Role for Both Proxies

### Create separate config templates:

```yaml
# roles/portainer/templates/docker-compose-traefik.yml.j2
# (current docker-compose.yml.j2 content with Traefik labels)

# roles/portainer/templates/docker-compose-nginx.yml.j2
version: '3'

services:
  portainer:
    image: "{{ portainer_image }}"
    container_name: portainer
    restart: "{{ portainer_restart_policy }}"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - "{{ portainer_data_directory }}:/data"
    ports:
      - "127.0.0.1:9000:9000"  # Internal only, nginx proxies
    networks:
      - "{{ portainer_nginx_network }}"

networks:
  "{{ portainer_nginx_network }}":
    external: true
```

### Update portainer tasks:

```yaml
# roles/portainer/tasks/main.yml additions

- name: Check reverse proxy availability
  assert:
    that: reverse_proxy in ['traefik', 'nginx']
    fail_msg: "portainer requires a reverse proxy (traefik or nginx)"
  tags: always

- name: Template docker-compose file for portainer (Traefik)
  ansible.builtin.template:
    src: docker-compose-traefik.yml.j2
    dest: /etc/portainer/docker-compose.yml
    mode: "0644"
  when: reverse_proxy == 'traefik'

- name: Template docker-compose file for portainer (Nginx)
  ansible.builtin.template:
    src: docker-compose-nginx.yml.j2
    dest: /etc/portainer/docker-compose.yml
    mode: "0644"
  when: reverse_proxy == 'nginx'

# Then create nginx site config
- name: Create nginx site configuration for portainer
  ansible.builtin.template:
    src: portainer-nginx.conf.j2
    dest: "{{ nginx_configs_dir }}/conf.d/portainer.conf"
    mode: "0644"
  when: reverse_proxy == 'nginx'
  notify: reload nginx
```

## Step 5: Create Nginx Site Template

### `roles/portainer/templates/portainer-nginx.conf.j2`:

```nginx
# Portainer Nginx Configuration
upstream portainer {
    server 127.0.0.1:9000;
}

server {
    listen 80;
    server_name {{ portainer_domain }};

    # Redirect HTTP to HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name {{ portainer_domain }};

    # SSL configuration
    ssl_certificate {{ portainer_ssl_cert_path }};
    ssl_certificate_key {{ portainer_ssl_key_path }};
    
    # ... SSL settings ...

    location / {
        proxy_pass http://portainer;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # WebSocket support for Portainer
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

## Step 6: Abstract Common Reverse Proxy Operations

### Create `roles/common/tasks/reverse_proxy_facts.yml`:

```yaml
---
# Set common facts about reverse proxy configuration
# This can be included by any role that needs proxy information

- name: Set reverse proxy facts
  set_fact:
    reverse_proxy_type: "{{ reverse_proxy | default('traefik') }}"
    reverse_proxy_network: >-
      {%- if reverse_proxy == 'nginx' -%}
        {{ nginx_docker_network | default('nginx-network') }}
      {%- else -%}
        {{ traefik_network_name | default('traefik-network') }}
      {%- endif -%}
    reverse_proxy_enabled: "{{ reverse_proxy | default('traefik') != 'none' }}"
  
- name: Validate reverse proxy is available
  assert:
    that: reverse_proxy_type in ['traefik', 'nginx']
    fail_msg: "Reverse proxy '{{ reverse_proxy_type }}' not supported or not configured"
  when: reverse_proxy_enabled | bool
```

### Usage in dependent roles:

```yaml
# In any role that needs reverse proxy
- name: Get reverse proxy facts
  include_tasks: "{{ role_path }}/../common/tasks/reverse_proxy_facts.yml"

- name: Configure service for reverse proxy
  include_tasks: "{{ reverse_proxy_type }}_config.yml"
  when: reverse_proxy_enabled | bool
```

## Step 7: Update Inventory Examples

### `inventory/prod.yml`:

```yaml
all:
  hosts:
    prod-web:
      ansible_host: 192.168.1.10
  vars:
    reverse_proxy: "traefik"
    traefik_domain: "prod.example.com"
```

### `inventory/dev.yml`:

```yaml
all:
  hosts:
    dev-web:
      ansible_host: 192.168.1.20
  vars:
    reverse_proxy: "nginx"
    nginx_sites:
      app:
        - server_name dev.example.com
```

## Benefits of This Approach

1. **Flexible**: Easy to switch proxies per environment
2. **Maintainable**: Clear separation of concerns
3. **Validated**: Ensures only one proxy runs per host
4. **Backward Compatible**: Defaults to traefik if not specified
5. **Extensible**: Easy to add more proxy types later

## Migration Path

1. Add `reverse_proxy` variable to all inventories
2. Update orchestration playbook with conditional logic
3. Gradually update dependent roles (start with portainer)
4. Test in dev environment with nginx
5. Keep traefik as default for existing environments


