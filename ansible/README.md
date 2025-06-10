# COSMOS Ansible Integration

## Overview
Ansible playbooks and roles for deploying COSMOS/OpenC3 in organizational environments.

## Quick Start

### 1. Prepare Secrets
```bash
# Create vault file for secrets
ansible-vault create group_vars/all/vault.yml

# Add required vault variables:
vault_cosmos_redis_username: openc3
vault_cosmos_redis_password: your_secure_password
vault_cosmos_bucket_username: openc3minio  
vault_cosmos_bucket_password: your_secure_password
vault_cosmos_sr_redis_username: scriptrunner
vault_cosmos_sr_redis_password: your_secure_password
vault_cosmos_sr_bucket_username: scriptrunnerminio
vault_cosmos_sr_bucket_password: your_secure_password
vault_cosmos_service_password: your_secure_password
vault_cosmos_secret_key_base: your_64_character_secret_key
```

### 2. Deploy to Development
```bash
ansible-playbook -i inventories/dev playbooks/cosmos-deploy.yml --ask-vault-pass
```

### 3. Deploy to Production
```bash
ansible-playbook -i inventories/prod playbooks/cosmos-deploy.yml --ask-vault-pass
```

## Playbooks

- **cosmos-prep.yml**: Prepare hosts (install Docker, create users)
- **cosmos-deploy.yml**: Full COSMOS deployment
- **cosmos-destroy.yml**: Cleanup/removal

## Roles

- **cosmos-requirements**: System dependencies and Docker setup
- **cosmos-config**: Environment configuration and secrets
- **cosmos-deploy**: COSMOS application deployment
- **cosmos-plugins**: Plugin management (optional)

## Integration with openc3.sh

Ansible handles infrastructure and configuration, then delegates to `openc3.sh` for COSMOS-specific operations:

```yaml
- name: Deploy COSMOS
  command: "./openc3.sh run {{ cosmos_environment }}"
  become_user: cosmos
```

This preserves COSMOS's native deployment mechanisms while adding organizational standardization.