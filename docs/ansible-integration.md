# Ansible Integration for COSMOS/OpenC3

## Overview
Integration strategy for deploying COSMOS using Ansible while preserving existing Docker Compose and openc3.sh workflows.

## Current State Analysis

### COSMOS Native Deployment
- **openc3.sh**: Handles environment management, Docker Compose orchestration, lifecycle operations
- **Hierarchical config**: `.env.defaults` → `.env.{env}` → `.env.local` → `.env.secrets`
- **Docker Compose**: Container orchestration with service dependencies
- **Self-contained**: Works well for single-server, development scenarios

### Organizational Needs
- Standardized deployment patterns via Ansible
- Multi-environment management (dev/staging/prod)
- Secret management through Ansible Vault
- Integration with existing infrastructure automation
- Compliance and audit requirements

## Integration Strategy: Hybrid Model

### Division of Responsibilities

**Ansible Handles:**
- Host preparation (Docker installation, system configuration)
- Environment-specific configuration templating
- Secret management via Ansible Vault
- Multi-server orchestration
- Infrastructure compliance
- Integration with organizational systems

**openc3.sh Continues to Handle:**
- COSMOS-specific operations
- Docker Compose orchestration
- Plugin management
- Local development workflows
- Container lifecycle management

### Benefits
- **Organizational Compliance**: Follows established Ansible patterns
- **Preserves COSMOS Simplicity**: openc3.sh remains focused on COSMOS operations
- **Scalable**: Easy multi-environment deployment
- **Secure**: Centralized secret management
- **Maintainable**: Clear separation of concerns

## Implementation Approach

### File Structure
```
ansible/
├── playbooks/
│   ├── cosmos-deploy.yml      # Main deployment
│   ├── cosmos-prep.yml        # Host preparation
│   └── cosmos-destroy.yml     # Cleanup
├── roles/
│   ├── cosmos-requirements/   # System dependencies
│   ├── cosmos-config/         # Configuration management
│   ├── cosmos-deploy/         # COSMOS deployment
│   └── cosmos-plugins/        # Plugin management
├── inventories/
│   ├── dev/hosts
│   ├── staging/hosts
│   └── prod/hosts
└── group_vars/
    ├── all.yml               # Common variables
    ├── dev.yml               # Dev environment
    └── prod.yml              # Production environment
```

### Workflow
1. **Preparation**: Ansible installs Docker, creates users, configures system
2. **Configuration**: Templates environment files using Jinja2, deploys secrets
3. **Deployment**: Executes `./openc3.sh run {environment}` via Ansible
4. **Validation**: Health checks and service verification

### Integration Points
- **Environment Variables**: Ansible Vault → templated .env files
- **Configuration**: Jinja2 templates for environment-specific settings
- **Secrets**: Ansible Vault replaces .env.secrets
- **Orchestration**: Ansible coordinates multi-server deployments

## Example Usage
```bash
# Deploy to development
ansible-playbook -i inventories/dev playbooks/cosmos-deploy.yml

# Deploy to production with vault
ansible-playbook -i inventories/prod playbooks/cosmos-deploy.yml --ask-vault-pass

# Cleanup environment
ansible-playbook -i inventories/dev playbooks/cosmos-destroy.yml
```

## Migration Path
1. Create Ansible structure alongside existing setup
2. Template current .env files as Jinja2 templates
3. Move secrets to Ansible Vault
4. Test deployment in development environment
5. Gradually adopt for staging and production

## Compatibility
- **Existing workflows preserved**: Local development continues using openc3.sh
- **No breaking changes**: Current Docker Compose setup remains functional
- **Incremental adoption**: Can be implemented environment by environment