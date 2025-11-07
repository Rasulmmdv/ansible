# Reverse Proxy Implementation - Phase 1: Traefik Support

## Summary

This document describes the implementation of reverse proxy selection support, starting with Traefik (Phase 1). The goal is to allow different environments to use different reverse proxies (Traefik or Nginx) while maintaining backward compatibility.

## Changes Made

### 1. Central Configuration (`group_vars/all/main.yml`)

- **Added `reverse_proxy` variable**: Defaults to `"traefik"` for backward compatibility
- **Added `nginx` to `roles_all`**: Both traefik and nginx are now in the master role list
- **Updated `role_dependencies`**: 
  - Added `nginx: [docker]` dependency
  - Changed `portainer: [docker, traefik]` to `portainer: [docker]` (reverse proxy dependency resolved dynamically)

### 2. Orchestration Playbook (`playbooks/orchestrate.yml`)

**Added reverse proxy handling:**
- **Pre-task**: Set reverse proxy feature flags (`traefik_enabled`, `nginx_enabled`)
- **Pre-task**: Validate reverse proxy selection (must be 'traefik', 'nginx', or 'none')
- **Dependency resolution**: Dynamic resolution of reverse proxy dependency for portainer
- **Conditional execution**: Reverse proxy roles only execute when enabled

**Key Logic:**
```yaml
# Feature flags
traefik_enabled: "{{ reverse_proxy == 'traefik' }}"
nginx_enabled: "{{ reverse_proxy == 'nginx' }}"

# Conditional role execution
when: |
  (item == 'traefik' and traefik_enabled) or
  (item == 'nginx' and nginx_enabled) or
  (item != 'traefik' and item != 'nginx')
```

### 3. Inventory (`all/inventory.yml`)

- **Added `reverse_proxy` variable**: Set to `"traefik"` (default for this environment)

## Backward Compatibility

✅ **Fully backward compatible**:
- Default value is `"traefik"` - existing configurations continue to work
- If `reverse_proxy` is not set, it defaults to `"traefik"`
- All existing roles that use traefik continue to work as before

## Testing

### Test Case 1: Traefik role execution
```bash
ansible-playbook -i all/inventory.yml playbooks/orchestrate.yml \
  -e '{"roles_enabled": ["traefik"]}' --check
```
**Expected**: Traefik role executes, nginx role is skipped

### Test Case 2: Portainer with traefik (default)
```bash
ansible-playbook -i all/inventory.yml playbooks/orchestrate.yml \
  -e '{"roles_enabled": ["portainer"]}' --check
```
**Expected**: Docker → Traefik → Portainer (in order)

### Test Case 3: Portainer with nginx (when implemented)
```bash
ansible-playbook -i all/inventory.yml playbooks/orchestrate.yml \
  -e '{"roles_enabled": ["portainer"], "reverse_proxy": "nginx"}' --check
```
**Expected**: Docker → Nginx → Portainer (in order)

### Test Case 4: Both proxies explicitly requested (should fail)
```bash
ansible-playbook -i all/inventory.yml playbooks/orchestrate.yml \
  -e '{"roles_enabled": ["traefik", "nginx"]}' --check
```
**Expected**: Validation fails (cannot enable both)

## Current Status

- ✅ Traefik conditional execution implemented
- ✅ Nginx role added to master list (ready for Phase 2)
- ✅ Portainer dependency resolution working
- ✅ Validation and backward compatibility ensured
- ⏳ Nginx role implementation (Phase 2 - next step)
- ⏳ Portainer dual-proxy support (Phase 2 - next step)

## Next Steps (Phase 2: Nginx Implementation)

1. Implement nginx role (if not fully complete)
2. Update portainer role to support both traefik and nginx configurations
3. Create portainer templates for both proxies
4. Test end-to-end with nginx selection

## Usage Examples

### Using Traefik (default)
```yaml
# In inventory.yml or group_vars
reverse_proxy: "traefik"  # or omit (defaults to traefik)
```

### Using Nginx (Phase 2)
```yaml
# In inventory.yml or group_vars
reverse_proxy: "nginx"
```

### No Reverse Proxy
```yaml
# In inventory.yml or group_vars
reverse_proxy: "none"
```

## Files Modified

1. `ansible/group_vars/all/main.yml` - Added reverse_proxy config and nginx role
2. `ansible/playbooks/orchestrate.yml` - Added conditional logic and validation
3. `ansible/all/inventory.yml` - Added reverse_proxy variable

## Breaking Changes

**None** - This implementation is fully backward compatible. Existing configurations continue to work without modification.


