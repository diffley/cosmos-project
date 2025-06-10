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
│   │   ├── defaults/main.yml  # Default variables
│   │   └── tasks/main.yml     # Role tasks
│   ├── cosmos-config/         # Configuration management
│   │   ├── defaults/main.yml  # Default variables
│   │   ├── tasks/main.yml     # Role tasks
│   │   └── templates/         # Jinja2 templates
│   └── cosmos-deploy/         # COSMOS deployment
│       ├── defaults/main.yml  # Default variables
│       └── tasks/main.yml     # Role tasks
└── inventories/
    ├── dev/
    │   ├── hosts
    │   └── group_vars/
    │       ├── all/
    │       │   ├── main.yml   # Common variables
    │       │   └── vault.yml  # Encrypted secrets
    │       └── cosmos_servers/
    │           └── main.yml   # Dev-specific variables
    ├── prod/ (same structure)
    ├── airgap/ (same structure)
    └── localhost/ (same structure)
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

### Configuration Architecture
**No Duplication Design:**
```
Local Development:
Project Root/.env.dev → openc3.sh → Direct usage

Ansible Deployment: 
group_vars/dev.yml → Jinja2 template → Target Host/.env.dev → openc3.sh
```

**Key Insight:** Ansible generates .env files on target hosts from group_vars, then openc3.sh uses those generated files. Local and remote deployment use the same openc3.sh mechanisms but different configuration sources.

## Example Usage
```bash
# Deploy to development
ansible-playbook -i inventories/dev/hosts playbooks/cosmos-deploy.yml

# Deploy to production with vault
ansible-playbook -i inventories/prod/hosts playbooks/cosmos-deploy.yml --ask-vault-pass

# Cleanup environment
ansible-playbook -i inventories/dev/hosts playbooks/cosmos-destroy.yml

# Air-gapped deployment
ansible-playbook -i inventories/airgap/hosts playbooks/cosmos-deploy.yml
```

## Migration Path
1. Create Ansible structure alongside existing setup
2. Template current .env files as Jinja2 templates
3. Move secrets to Ansible Vault
4. Test deployment in development environment
5. Gradually adopt for staging and production

## Air-Gapped / Offline Deployment

### Overview
COSMOS is well-suited for air-gapped deployment due to its configurable external dependencies and container-based architecture.

### External Dependencies
**Container Registries**: All configurable via environment variables
- `OPENC3_REGISTRY` (default: docker.io)
- `OPENC3_ENTERPRISE_REGISTRY` (default: ghcr.io)

**Package Repositories**: All configurable via environment variables
- `APK_URL` (Alpine packages)
- `RUBYGEMS_URL` (Ruby gems)
- `PYPI_URL` (Python packages)
- `NPM_URL` (Node.js packages)

**Additional Dependencies**:
- Git repositories (for Ansible deployment)
- SSL/TLS certificates
- Health check endpoints

### Air-Gapped Implementation

#### 1. Infrastructure Setup
- **Container Registry**: Use Nexus, Harbor, or similar for internal container hosting
- **Package Mirrors**: Mirror APK, RubyGems, PyPI, NPM repositories
- **Certificate Management**: Provide internal CA bundle
- **Git Repository**: Use internal Git server or file-based deployment

#### 2. COSMOS Bundle Creation
```bash
# Create air-gapped bundle
./scripts/bundle-for-airgap.sh 6.4.2

# Transfers cosmos-airgap-6.4.2.tar.gz containing:
# - COSMOS source code
# - Pre-saved container images
# - Deployment scripts
```

#### 3. Ansible Configuration
**Environment Variables (group_vars/airgap.yml)**:
```yaml
cosmos_airgap_registry: nexus.company.com
cosmos_airgap_namespace: cosmos
cosmos_airgap_apk_url: https://nexus.company.com/repository/alpine
cosmos_airgap_rubygems_url: https://nexus.company.com/repository/rubygems
cosmos_airgap_pypi_url: https://nexus.company.com/repository/pypi
cosmos_airgap_npm_url: https://nexus.company.com/repository/npm
```

**Template Generation**: Jinja2 templates automatically generate air-gapped .env files:
```jinja2
# templates/env.airgap.j2
OPENC3_REGISTRY={{ cosmos_airgap_registry }}
APK_URL={{ cosmos_airgap_apk_url }}
# ... other overrides
```

#### 4. Deployment Workflow
```bash
# Prepare air-gapped environment
ansible-playbook -i inventories/airgap playbooks/cosmos-airgap-prep.yml

# Deploy COSMOS in air-gapped mode
ansible-playbook -i inventories/airgap playbooks/cosmos-deploy.yml
```

### Key Benefits for Air-Gapped
- **Built-in container bundling** via `openc3.sh util save/load`
- **All external dependencies configurable** via environment variables
- **No internet required at runtime** after proper preparation
- **Ansible templates** automatically handle environment-specific configuration
- **Security compliance** through internal infrastructure usage

### Difficulty Assessment: **EASY** ⭐⭐☆☆☆
Air-gapped deployment is straightforward due to COSMOS's configurable architecture and your existing Nexus container solution.

## Compatibility
- **Existing workflows preserved**: Local development continues using openc3.sh
- **No breaking changes**: Current Docker Compose setup remains functional
- **Incremental adoption**: Can be implemented environment by environment
- **Air-gapped ready**: Full offline deployment capability with proper preparation