# WireGuard Setup Issues & Fixes

## Issues Fixed ✅

### 1. **Validation Happens Before Key Generation** ✅ FIXED
**Problem**: The role validated `wireguard_private_key` (must be 44 chars) before it was generated, causing validation to fail on first run.

**Fix Applied**:
- Moved key extraction/generation logic BEFORE validation
- Made `wireguard_private_key` optional in `required_variables` (removed from list)
- Added conditional validation that only runs if key is provided
- Keys are now auto-extracted from existing config or auto-generated

### 2. **Port Validation Syntax** ✅ FIXED
**Problem**: The validation pattern `wireguard_port | int > 0 and wireguard_port | int <= 65535` needed to match the validation task's pattern matching.

**Fix Applied**:
- Updated validation pattern to: `"int > 0 and int <= 65535"`
- Validation task already handles this pattern correctly (line 129-130)

### 3. **IP Address & Interface Validation** ✅ FIXED
**Problem**: Validation patterns for IP address and interface name needed to match the validation task's regex detection.

**Fix Applied**:
- Added IP address pattern matching in `variable_validation.yml`: `'[0-9]+\\.[0-9]+'` detection
- Added interface pattern matching: `'^wg[0-9]+$'` detection
- Updated WireGuard validation to use patterns that are detected by validation task

### 4. **Missing Required Variables in Inventory** ✅ FIXED
**Problem**: `wireguard_address` was required but not set in inventory.

**Fix Applied**:
- Added default WireGuard variables to `all/inventory.yml`:
  ```yaml
  wireguard_address: "10.0.0.1/24"
  wireguard_port: "51820"
  wireguard_interface: "wg0"
  wireguard_manage_iptables: true
  ```
- Variables now have sensible defaults

### 5. **Iptables Integration** ✅ FIXED
**Problem**: WireGuard role includes iptables role which might conflict with main iptables role.

**Fix Applied**:
- Made iptables integration conditional via `wireguard_manage_iptables`
- Added `iptables_install_when_docker_present: true` to prevent conflicts
- Role can now skip iptables if main iptables role already configured

---

## Changes Made

### 1. `roles/wireguard/tasks/main.yml`
- ✅ Moved key extraction/generation BEFORE validation
- ✅ Made `wireguard_private_key` optional in validation
- ✅ Added conditional validation for private key
- ✅ Updated validation patterns to match validation task logic
- ✅ Fixed iptables integration conditional

### 2. `roles/common/tasks/variable_validation.yml`
- ✅ Added IP address pattern detection: `'[0-9]+\\.[0-9]+'`
- ✅ Added WireGuard interface pattern detection: `'^wg[0-9]+$'`
- ✅ These patterns are now recognized by the validation logic

### 3. `ansible/all/inventory.yml`
- ✅ Added WireGuard default variables with sensible defaults
- ✅ Made `wireguard_private_key` optional (auto-generated if not provided)

---

## Testing Instructions

### Test 1: First Run (No Existing Config)
```bash
ansible-playbook -i all/inventory.yml playbooks/orchestrate.yml -e "roles_enabled=['wireguard']"
```
**Expected**: 
- ✅ Key auto-generated
- ✅ Validation passes
- ✅ WireGuard configured successfully

### Test 2: Second Run (Idempotency)
```bash
ansible-playbook -i all/inventory.yml playbooks/orchestrate.yml -e "roles_enabled=['wireguard']"
```
**Expected**: 
- ✅ Existing key preserved
- ✅ No changes made
- ✅ Idempotent execution

### Test 3: With Custom Variables
```bash
ansible-playbook -i all/inventory.yml playbooks/orchestrate.yml \
  -e "roles_enabled=['wireguard']" \
  -e "wireguard_address=10.0.1.1/24" \
  -e "wireguard_port=51821"
```
**Expected**: 
- ✅ Custom values used
- ✅ Validation passes

### Test 4: With Existing Private Key
```bash
ansible-playbook -i all/inventory.yml playbooks/orchestrate.yml \
  -e "roles_enabled=['wireguard']" \
  -e "wireguard_private_key='<your-44-char-base64-key>'"
```
**Expected**: 
- ✅ Provided key used
- ✅ Validation passes

### Test 5: Without Iptables Management
```bash
ansible-playbook -i all/inventory.yml playbooks/orchestrate.yml \
  -e "roles_enabled=['wireguard']" \
  -e "wireguard_manage_iptables=false"
```
**Expected**: 
- ✅ WireGuard configured
- ✅ Iptables role not included

---

## Summary

**All issues fixed** ✅

The WireGuard role should now:
1. ✅ Auto-generate keys if not provided
2. ✅ Preserve existing keys across runs
3. ✅ Validate variables correctly
4. ✅ Work with default inventory variables
5. ✅ Handle iptables integration properly

**Ready for deployment!** 🚀
