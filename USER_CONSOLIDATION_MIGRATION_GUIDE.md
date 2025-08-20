# User Creation Consolidation Migration Guide

## Overview

This guide explains how to migrate existing roles from individual user creation patterns to the standardized, consolidated user creation system.

## Benefits of Consolidation

1. **Consistency**: Standardized UID/GID mappings across all services
2. **Reduced Duplication**: Single implementation of user creation logic
3. **Error Handling**: Comprehensive error handling and validation
4. **Maintainability**: Changes to user creation logic only need to be made in one place
5. **Documentation**: Automatic documentation of service users and their configurations

## Migration Process

### Step 1: Identify Current User Creation Pattern

Look for patterns like this in your role's `tasks/main.yml`:

```yaml
# OLD PATTERN - Individual user creation
- name: Create service group
  group:
    name: "{{ service_group }}"
    gid: "{{ service_group_id }}"
  become: true

- name: Create service user
  user:
    name: "{{ service_user }}"
    group: "{{ service_group }}"
    uid: "{{ service_user_id }}"
    system: yes
    shell: /usr/sbin/nologin
    create_home: no
  become: true

- name: Create service directories
  file:
    path: "{{ item }}"
    state: directory
    owner: "{{ service_user }}"
    group: "{{ service_group }}"
    mode: '0755'
  loop:
    - "{{ service_data_dir }}"
    - "{{ service_config_dir }}"
  become: true
```

### Step 2: Replace with Standardized Pattern

Replace the entire user creation block with:

```yaml
# NEW PATTERN - Standardized user creation
- name: Setup service user and directories (standardized)
  include_tasks: "{{ role_path }}/../common/tasks/setup_service_user.yml"
  vars:
    service_name: "myservice"
    service_user: "{{ myservice_user }}"
    service_group: "{{ myservice_group }}"
    service_uid: "{{ myservice_user_id | default(omit) }}"
    service_gid: "{{ myservice_group_id | default(omit) }}"
    service_directories:
      - "{{ myservice_data_dir }}"
      - "{{ myservice_config_dir }}"
    directory_mode: "0755"
  when: not ansible_check_mode
```

### Step 3: Add Service Configuration to Common Defaults

Add your service to `/ansible/roles/common/defaults/service_users.yml`:

```yaml
service_users:
  myservice:
    uid: 8001
    gid: 8001
    home: "/opt/myservice"
    shell: "/usr/sbin/nologin"
    additional_groups: [] # Add groups like ["docker"] if needed
```

## Migration Examples

### Example 1: Prometheus Role

**Before:**
```yaml
- name: Setup Prometheus user and directories
  block:
    - name: Create Prometheus group
      group:
        name: "{{ prometheus_group }}"
        gid: "{{ prometheus_group_id }}"
      become: true

    - name: Create Prometheus user
      user:
        name: "{{ prometheus_user }}"
        group: "{{ prometheus_group }}"
        uid: "{{ prometheus_user_id }}"
        system: yes
        shell: /usr/sbin/nologin
        create_home: no
      become: true

    - name: Create Prometheus directories
      file:
        path: "{{ item }}"
        state: directory
        owner: "{{ prometheus_user_id }}"
        group: "{{ prometheus_group_id }}"
        mode: '0755'
      loop:
        - "{{ prometheus_data_dir }}"
        - "{{ prometheus_config_dir }}"
      become: true
```

**After:**
```yaml
- name: Setup Prometheus user and directories (standardized)
  include_tasks: "{{ role_path }}/../common/tasks/setup_service_user.yml"
  vars:
    service_name: "prometheus"
    service_user: "{{ prometheus_user }}"
    service_group: "{{ prometheus_group }}"
    service_uid: "{{ prometheus_user_id | default(omit) }}"
    service_gid: "{{ prometheus_group_id | default(omit) }}"
    service_directories:
      - "{{ prometheus_data_dir }}"
      - "{{ prometheus_config_dir }}"
    directory_mode: "0755"
  when: not ansible_check_mode
```

### Example 2: Jenkins Role (with Docker group)

**Before:**
```yaml
- name: Create Jenkins group
  group:
    name: "{{ jenkins_group }}"
    gid: 1001
  become: true

- name: Create Jenkins user
  user:
    name: "{{ jenkins_user }}"
    group: "{{ jenkins_group }}"
    uid: 1000
    shell: /bin/bash
    home: "{{ jenkins_home }}"
    create_home: false
  become: true

- name: Add Jenkins user to docker group
  user:
    name: "{{ jenkins_user }}"
    groups: docker
    append: true
  become: true
```

**After:**
```yaml
- name: Setup Jenkins user and directories (standardized)
  include_tasks: "{{ role_path }}/../common/tasks/setup_service_user.yml"
  vars:
    service_name: "jenkins"
    service_user: "{{ jenkins_user }}"
    service_group: "{{ jenkins_group }}"
    service_uid: "{{ jenkins_user_id | default(1000) }}"
    service_gid: "{{ jenkins_group_id | default(1001) }}"
    service_shell: "/bin/bash"
    service_home: "{{ jenkins_home }}"
    additional_groups: ["docker"]
    service_directories:
      - "{{ jenkins_home }}"
    directory_mode: "0755"
  when: not ansible_check_mode
```

## Advanced Usage

### Custom Directory Ownership

Some services require different ownership for directories:

```yaml
- name: Setup service with custom directory ownership
  include_tasks: "{{ role_path }}/../common/tasks/setup_service_user.yml"
  vars:
    service_name: "grafana"
    service_directories:
      - "{{ grafana_data_dir }}"
    # Override directory ownership (common for Docker compatibility)
    directory_owner: "0"
    directory_group: "0"
```

### Conditional User Creation

For services that might run in containers and not need system users:

```yaml
- name: Setup service user (when not containerized)
  include_tasks: "{{ role_path }}/../common/tasks/setup_service_user.yml"
  vars:
    service_name: "myservice"
    service_directories:
      - "{{ service_data_dir }}"
  when: 
    - not ansible_check_mode
    - not service_containerized | default(false)
```

### Using Only Directory Creation

If the user already exists and you only need directories:

```yaml
- name: Create service directories only
  include_tasks: "{{ role_path }}/../common/tasks/create_service_directories.yml"
  vars:
    service_name: "myservice"
    service_directories:
      - "{{ service_data_dir }}"
    directory_owner: "{{ existing_user }}"
    directory_group: "{{ existing_group }}"
```

## Migration Checklist

### For Each Role:

- [ ] **Identify** current user creation pattern
- [ ] **Test** current role functionality before migration
- [ ] **Add** service configuration to `common/defaults/service_users.yml`
- [ ] **Replace** user creation block with standardized include
- [ ] **Update** any hardcoded UID/GID references in templates
- [ ] **Test** migrated role functionality
- [ ] **Update** role README with new user creation method

### Role-Specific Updates:

- [ ] **Templates**: Update any templates that reference user/group IDs
- [ ] **Handlers**: Update handlers that might reference users
- [ ] **Variables**: Update default variables if needed
- [ ] **Documentation**: Update role documentation

### Testing:

- [ ] **Syntax Check**: `ansible-playbook --syntax-check`
- [ ] **Dry Run**: `ansible-playbook --check`
- [ ] **Full Deployment**: Test actual deployment
- [ ] **Idempotency**: Run twice to ensure idempotent behavior
- [ ] **User Verification**: Verify users and directories are created correctly

## Troubleshooting

### Common Issues:

1. **User Already Exists**: The system handles existing users gracefully
2. **UID/GID Conflicts**: Check `/etc/passwd` and `/etc/group` for conflicts
3. **Permission Issues**: Ensure the ansible user has sudo privileges
4. **Directory Ownership**: Verify directory ownership matches expectations

### Debug Information:

The standardized system provides detailed debug output. To see more information:

```yaml
- name: Setup service with verbose output
  include_tasks: "{{ role_path }}/../common/tasks/setup_service_user.yml"
  vars:
    service_name: "myservice"
    show_service_setup_summary: true  # Default: true
```

### Validation:

After migration, you can verify the user was created correctly:

```bash
# Check user exists
id myservice_user

# Check directories exist with correct ownership
ls -la /opt/myservice

# Check service user info is available in facts
ansible-playbook your_playbook.yml -v | grep "myservice_user_info"
```

## Benefits Realized

After migration, you'll have:

1. **Consistent UIDs/GIDs** across all deployments
2. **Automatic error handling** and recovery
3. **Detailed logging** of user creation activities
4. **Standardized patterns** that new team members can easily understand
5. **Centralized configuration** for all service users
6. **Reduced maintenance burden** for user-related code

## Best Practices

1. **Test Thoroughly**: Always test migrations in a development environment first
2. **Document Changes**: Update role README files with new patterns
3. **Gradual Migration**: Migrate one role at a time to minimize risk
4. **Backup**: Backup user/group files before migration if on production systems
5. **Consistent Patterns**: Use the same variable naming patterns across all roles

This consolidation significantly improves the maintainability and consistency of user management across your Ansible infrastructure.