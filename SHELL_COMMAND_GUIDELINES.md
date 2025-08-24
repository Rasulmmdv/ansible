# Shell Command Usage Guidelines

## Overview

This document explains when shell commands are necessary in Ansible roles, best practices for their usage, and security considerations.

## When Shell Commands Are Acceptable

### 1. **Complex System Operations**
Shell commands are necessary when operations require:
- Complex pipelines that would be difficult to replicate with modules
- Multi-step operations that depend on previous step output
- Integration with system tools that don't have Ansible modules

**Examples:**
```yaml
# Complex iptables emergency recovery scheduling
- name: Schedule emergency recovery
  ansible.builtin.shell: |
    set -euo pipefail
    for job in $(atq | awk '{print $1}' 2>/dev/null || echo ""); do
      if [[ -n "$job" ]]; then
        atrm "$job" 2>/dev/null || true
      fi
    done
    printf '%s\n' "/usr/local/bin/emergency-iptables-recovery.sh" | at now + 3 minutes
```

### 2. **Cryptographic Operations**
When working with keys and certificates:
```yaml
# GPG key processing (fallback when get_url fails)
- name: Add Docker apt key (fallback method using curl)
  ansible.builtin.shell: |
    set -euo pipefail
    curl -fsSL "{{ docker_apt_gpg_key }}" | gpg --dearmor -o /etc/apt/keyrings/docker.asc
  args:
    creates: /etc/apt/keyrings/docker.asc
    executable: /bin/bash
```

### 3. **Network-Specific Operations**
Operations requiring specific network tools:
```yaml
# Wireguard key generation
- name: Generate WireGuard private key
  ansible.builtin.command: wg genkey
  register: wg_private_key
  changed_when: false
```

### 4. **Parsing Complex Configuration Files**
When standard file modules aren't sufficient:
```yaml
# Extract specific patterns from config files
- name: Extract private key from existing config
  ansible.builtin.shell: |
    set -eo pipefail
    grep -oP 'PrivateKey\s*=\s*\K.*' "/etc/wireguard/{{ interface }}.conf" || echo ""
  args:
    executable: /bin/bash
```

## Shell Command Best Practices

### 1. **Always Use Error Handling**
```yaml
# ✅ GOOD: Proper error handling
- name: Safe shell operation
  ansible.builtin.shell: |
    set -euo pipefail  # Exit on error, undefined vars, pipe failures
    command_that_might_fail || handle_error
  args:
    executable: /bin/bash

# ❌ BAD: No error handling
- name: Unsafe shell operation
  shell: command_that_might_fail
```

### 2. **Proper Quoting and Variable Handling**
```yaml
# ✅ GOOD: Proper quoting
- name: Process user input safely
  ansible.builtin.shell: |
    set -euo pipefail
    process_file "{{ file_path | quote }}"
  args:
    executable: /bin/bash

# ❌ BAD: Injection vulnerability
- name: Unsafe variable usage
  shell: process_file {{ file_path }}
```

### 3. **Use Appropriate Shell**
```yaml
# ✅ GOOD: Specify bash for advanced features
- name: Use bash features
  ansible.builtin.shell: |
    set -euo pipefail
    # Bash-specific operations
  args:
    executable: /bin/bash

# ✅ GOOD: Use command for simple operations
- name: Simple command execution
  ansible.builtin.command: simple_command arg1 arg2
```

### 4. **Idempotency Considerations**
```yaml
# ✅ GOOD: Idempotent shell operation
- name: Idempotent file operation
  ansible.builtin.shell: |
    set -euo pipefail
    if [[ ! -f /target/file ]]; then
      create_file
    fi
  args:
    creates: /target/file
    executable: /bin/bash

# ✅ GOOD: Check before action
- name: Conditional operation
  ansible.builtin.shell: command
  args:
    creates: /path/to/result
```

### 5. **Change Detection**
```yaml
# ✅ GOOD: Proper change detection
- name: Operation with change detection
  ansible.builtin.shell: |
    if [[ condition ]]; then
      make_change
      echo "changed"
    else
      echo "no change needed"
    fi
  register: result
  changed_when: "'changed' in result.stdout"
```

## When to Use Ansible Modules Instead

### 1. **File Operations**
```yaml
# ✅ PREFER: Ansible modules
- name: Copy file
  ansible.builtin.copy:
    src: source
    dest: destination

# ❌ AVOID: Shell commands
- name: Copy file with shell
  shell: cp source destination
```

### 2. **Package Management**
```yaml
# ✅ PREFER: Package module
- name: Install packages
  ansible.builtin.package:
    name: ["pkg1", "pkg2"]
    state: present

# ❌ AVOID: Shell commands
- name: Install with shell
  shell: apt-get install pkg1 pkg2
```

### 3. **Service Management**
```yaml
# ✅ PREFER: Service module
- name: Start service
  ansible.builtin.systemd:
    name: myservice
    state: started
    enabled: true

# ❌ AVOID: Shell commands
- name: Start service with shell
  shell: systemctl start myservice
```

### 4. **HTTP Requests**
```yaml
# ✅ PREFER: URI module
- name: Make HTTP request
  ansible.builtin.uri:
    url: "http://example.com/api"
    method: GET
    status_code: 200

# ❌ AVOID: curl commands
- name: HTTP request with curl
  shell: curl http://example.com/api
```

### 5. **User Management**
```yaml
# ✅ PREFER: User module with getent
- name: Get user information
  ansible.builtin.getent:
    database: passwd
    key: "{{ username }}"
  register: user_info

# ❌ AVOID: Shell commands
- name: Get user info with shell
  shell: id -u {{ username }}
```

## Security Considerations

### 1. **Input Validation**
- Always validate and quote user inputs
- Use `| quote` filter for shell variables
- Avoid direct variable interpolation in shell commands

### 2. **Privilege Escalation**
- Use `become: true` only when necessary
- Specify the minimum required privileges
- Document why elevated privileges are needed

### 3. **Logging and Secrets**
- Use `no_log: true` for sensitive operations
- Avoid logging credentials or keys
- Use Ansible Vault for secrets

### 4. **Error Handling**
- Always use `set -euo pipefail` in shell scripts
- Handle expected errors gracefully
- Provide meaningful error messages

## Migration Examples

### Before: Shell Commands
```yaml
# Old approach with multiple issues
- name: Get Docker gateway IP
  shell: |
    docker network inspect monitoring --format '{{range .IPAM.Config}}{{.Gateway}}{{end}}' || echo "172.17.0.1"
  register: gateway_ip

- name: Start Docker service
  shell: docker compose up -d
  args:
    chdir: /opt/app

- name: Check service health
  shell: curl -f http://localhost:8080/health
  retries: 5
```

### After: Improved Implementation
```yaml
# Modern approach with proper modules and error handling
- name: Get Docker gateway IP
  block:
    - name: Inspect monitoring network
      community.docker.docker_network_info:
        name: "monitoring"
      register: network_info
      failed_when: false
      
    - name: Set gateway IP
      ansible.builtin.set_fact:
        gateway_ip: "{{ network_info.network.IPAM.Config[0].Gateway | default('172.17.0.1') }}"

- name: Start Docker service
  community.docker.docker_compose_v2:
    project_src: /opt/app
    state: present

- name: Check service health
  ansible.builtin.uri:
    url: "http://localhost:8080/health"
    method: GET
    status_code: 200
  retries: 5
  delay: 10
```

## Conclusion

While Ansible provides extensive module coverage, shell commands remain necessary for:
- Complex system operations requiring multiple tools
- Cryptographic operations and key management
- Advanced text processing and parsing
- Integration with specialized tools

When using shell commands:
1. **Justify the necessity** - Ensure no suitable module exists
2. **Follow security best practices** - Proper quoting, error handling, privilege management
3. **Document the rationale** - Explain why the shell command is required
4. **Test thoroughly** - Verify idempotency and error conditions
5. **Consider future migration** - Monitor for new modules that could replace shell commands

The goal is to minimize shell command usage while maintaining functionality, security, and maintainability.