# COSMOS Documentation

## Quick Reference

### Local Development
```bash
./openc3.sh run          # Start with dev environment  
./openc3.sh run prod     # Start with production config
./openc3.sh stop         # Stop services
./openc3.sh cleanup      # Remove data volumes
```

### Environment Management
**Hierarchical Configuration Loading:**
1. `.env.defaults` - Base configuration
2. `.env.{env}` - Environment overrides (dev/prod/airgap) 
3. `.env.local` - Personal overrides (gitignored)
4. `.env.secrets` - Sensitive data (gitignored)

### Ansible Deployment
```bash
# Deploy to development
ansible-playbook -i ansible/inventories/dev ansible/playbooks/cosmos-deploy.yml

# Deploy to air-gapped environment  
ansible-playbook -i ansible/inventories/airgap ansible/playbooks/cosmos-deploy.yml
```

## Key Architectural Decisions

### Hybrid Deployment Model
- **Local Development**: Direct openc3.sh usage with local .env files
- **Organizational Deployment**: Ansible generates .env files from group_vars, then calls openc3.sh
- **No Duplication**: Ansible templates create target host .env files from single source (group_vars)

### Air-Gapped Support
- **Built-in container bundling**: `./openc3.sh util save/load`
- **Configurable dependencies**: All external URLs overridable via environment variables
- **Bundle creation**: `./scripts/bundle-for-airgap.sh` for offline transfers

## Detailed Documentation
- [Ansible Integration](ansible-integration.md) - Organizational deployment strategy
- [OpenC3 Plugin Development](openc3-plugin-development.md) - Plugin creation guide