# Inventory Management Guide

## Overview

This Ansible setup uses an **inventory directory** structure that allows you to maintain separate inventory files for different environments (personal vs customer) without copy-pasting.

## Directory Structure

```
ansible/
├── all/                          # Inventory directory
│   ├── inventory.yml             # Personal infrastructure
│   ├── customer.yml              # Customer infrastructure
│   ├── common_vars.yml           # Shared variables for all hosts
│   └── group_vars/               # Group-specific variables
│       ├── all.yml
│       └── ...
└── ansible.cfg                   # Points to ./all directory
```

## How It Works

When `ansible.cfg` points to a directory (instead of a single file), Ansible automatically:
1. Reads all `.yml` files in that directory
2. Combines them into a single inventory
3. Merges variables (with later files taking precedence)

## Inventory Files

### `inventory.yml` (Personal)
Contains your personal servers organized under the `personal` group:
- infra-01 (GitLab server)
- prod-01, prod-02 (Production servers)
- test-01 (Test server)
- vpn-01 (VPN server)
- jitsi-01 (Jitsi server)

### `customer.yml` (Customer)
Contains customer servers organized under the `customer` group. Add your customer's hosts here.

### `common_vars.yml` (Shared Variables)
Contains variables that apply to all hosts across both personal and customer inventories.

## Usage Examples

### List all hosts
```bash
ansible-playbook playbooks/orchestrate.yml --list-hosts
```

### Target only personal servers
```bash
ansible-playbook playbooks/orchestrate.yml -e "target_hosts=personal"
```

### Target only customer servers
```bash
ansible-playbook playbooks/orchestrate.yml -e "target_hosts=customer"
```

### Target specific host from either inventory
```bash
ansible-playbook playbooks/orchestrate.yml -e "target_hosts=infra-01"
ansible-playbook playbooks/orchestrate.yml -e "target_hosts=customer-prod-01"
```

### Use inventory groups in playbooks
```yaml
- name: Deploy to personal infrastructure
  hosts: personal
  tasks:
    - ...

- name: Deploy to customer infrastructure
  hosts: customer
  tasks:
    - ...
```

## Adding Customer Hosts

1. Edit `ansible/all/customer.yml`
2. Add hosts under the `customer` group:
   ```yaml
   customer:
     hosts:
       customer-prod-01:
         ansible_host: 192.168.1.100
         ansible_user: root
         ansible_become: true
         # Add customer-specific variables
         project_name: customer_project
   ```
3. Remove the `pass:` placeholder line if present
4. Save the file - no need to modify `ansible.cfg` or other files

## Benefits

✅ **No Copy-Pasting**: Each inventory is maintained in its own file  
✅ **Automatic Combination**: Ansible merges all inventory files automatically  
✅ **Group Separation**: Use `personal` and `customer` groups to target specific environments  
✅ **Shared Variables**: Common settings in `common_vars.yml` apply to all hosts  
✅ **Easy Maintenance**: Add/remove hosts without touching other files  
✅ **Version Control Friendly**: Each inventory can be managed independently  

## Advanced: Using Multiple Customer Inventories

If you have multiple customers, you can create separate files:
- `customer_a.yml`
- `customer_b.yml`
- `customer_c.yml`

Each can have its own group structure:
```yaml
all:
  children:
    customer_a:
      hosts:
        ...
    customer_b:
      hosts:
        ...
```

Then target them with:
```bash
ansible-playbook playbooks/orchestrate.yml -e "target_hosts=customer_a"
```

## Overriding Inventory

You can still override the inventory on the command line:
```bash
# Use a specific inventory file
ansible-playbook playbooks/orchestrate.yml -i all/inventory.yml

# Use a different inventory directory
ansible-playbook playbooks/orchestrate.yml -i /path/to/other/inventory/
```

## Troubleshooting

### Check what hosts are available
```bash
ansible all --list-hosts
ansible personal --list-hosts
ansible customer --list-hosts
```

### Verify inventory structure
```bash
ansible-inventory --list
ansible-inventory --graph
```

### Test connectivity
```bash
ansible personal -m ping
ansible customer -m ping
```
