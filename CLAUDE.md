# CLAUDE.md - COSMOS/OpenC3 Development Guidelines

## 🎯 CORE PRINCIPLE: CONCISENESS
**CRITICAL**: Keep all code, configurations, and documentation CONCISE. Write only what's needed. Every line serves a clear purpose.

## 📋 DEVELOPMENT WORKFLOW
**BEFORE MAJOR UPDATES**:
1. **PLAN FIRST**: Always define a clear plan before significant changes
2. **INCREMENTAL**: Make changes incrementally and test as you go
3. **VALIDATE**: Test each change before proceeding to the next

## Project Overview
COSMOS (OpenC3) cloud-native command and control system in **Core Single Server Architecture** with **Local Mode** enabled.
- **Stack**: Ruby (primary), Python (scripting), Docker, Redis, MinIO, Traefik
- **License**: AGPLv3 (free, open source)
- **Deployment**: Single server, single user

## Local Mode Development
Set `OPENC3_LOCAL_MODE=1` in `.env` for instant file sync:
- Edit files in `plugins/targets_modified/`
- Changes sync automatically to COSMOS
- Use "Reload" button in Script Runner
- No plugin rebuild required

## Key Files
- `openc3.sh`: Main CLI
- `compose.yaml`: Docker Compose config
- `plugins/targets_modified/`: Local development files

## Development Standards

### Ruby/Python Code
- Functions < 20 lines, files < 200 lines
- Minimal dependencies
- Descriptive names: `target_name`, `interface_name`, `microservice_name`
- Use `DONT_CONNECT` for testing interfaces

### Plugin Development
- Keep configs minimal
- Use ERB templating for dynamic values
- One target per plugin (unless demo)
- Define variables in `plugin_instance.json`

### Testing
- Test with `DONT_CONNECT` first
- Use Docker containers for integration
- Validate configs before deployment
- Test simulated targets before hardware

## Container Services
- **openc3-cmd-tlm-api**: Command/Telemetry API
- **openc3-script-runner-api**: Script execution
- **openc3-operator**: Core operations
- **openc3-redis**: Data streaming
- **openc3-minio**: Object storage
- **openc3-traefik**: Reverse proxy

## Common Issues
- **Ports**: Check 7779, 9999, 5025 availability
- **Permissions**: Ensure Docker permissions
- **Configs**: Validate JSON syntax
- **Debugging**: Use `docker compose logs [service]`

## Limitations
- Single user with shared password
- No enterprise features
- Not for production multi-user environments
- AGPLv3 license compliance required