# CLAUDE.md - COSMOS/OpenC3 Development Guidelines

## Project Overview
This is a COSMOS (OpenC3) cloud-native command and control system project running in **Core Single Server Architecture** with **Local Mode** enabled. COSMOS uses a containerized microservices architecture with Ruby as the primary language and Python support for scripting and interfaces.

## 🎯 CORE DEVELOPMENT PRINCIPLE: CONCISENESS
**CRITICAL**: Keep all code, configurations, and documentation CONCISE. Write only what's needed for functionality and human readability. Avoid verbose patterns, unnecessary abstractions, and code sprawl. Every line should serve a clear purpose.

### Documentation Standards
- **BRIEF & ESSENTIAL**: Document only what's necessary - avoid redundant explanations
- **NO DOCUMENTATION SPRAWL**: Don't create extensive docs for simple concepts
- **ACTIONABLE ONLY**: Focus on what users need to DO, not exhaustive background
- **NEVER CREATE**: Documentation files unless explicitly requested

## Architecture & Deployment Model

### Core Single Server Architecture
- **Deployment**: Single server using Docker Desktop/Docker
- **License**: AGPLv3 (free, open source)
- **Best For**: Evaluation, development, university teams, localized lab work
- **Limitations**: Single user, shared admin password, no enterprise features
- **Advantages**: Free, easy to deploy and configure

### Local Mode Configuration
- **Local Mode**: Enabled via `OPENC3_LOCAL_MODE=1` in `.env`
- **Development Workflow**: Edit files locally with automatic sync to COSMOS
- **File Location**: `plugins/targets_modified/` for modified components
- **Instant Updates**: No plugin rebuild required for script/screen changes

## Tech Stack
- **Primary Language**: Ruby (Rails framework)
- **Secondary Language**: Python (for scripting and interfaces)
- **Containerization**: Docker & Docker Compose
- **Reverse Proxy**: Traefik
- **Data Storage**: Redis (streaming/caching) + MinIO (object storage)
- **Frontend**: Web-based (Vue.js/React support)

## Development Environment

### Required Tools
- Docker Desktop
- Visual Studio Code (recommended)
- Ruby (for plugin development)
- Python (for interface/scripting development)
- Git

### Key Files
- `compose.yaml`: Main Docker Compose configuration
- `.env`: Environment variables and version configuration (set `OPENC3_LOCAL_MODE=1`)
- `openc3.sh`/`openc3.bat`: Main CLI entry points
- `plugins/`: Plugin directory structure
- `plugins/targets_modified/`: Local mode development files (auto-synced)

## Development Workflow

### Starting the System
```bash
# Build containers and dependencies
./openc3.sh build

# Run in development mode (enables localhost access)
./openc3.sh run

# Stop the system
./openc3.sh stop

# Clean up volumes and data
./openc3.sh cleanup
```

### Local Mode Development
With `OPENC3_LOCAL_MODE=1` enabled in `.env`:

1. **Edit Files Locally**: Modify scripts and screens in `plugins/targets_modified/`
2. **Automatic Sync**: Changes sync instantly to COSMOS
3. **Reload in COSMOS**: Use "Reload" button in Script Runner for scripts
4. **No Rebuild Required**: Immediate testing without plugin reinstallation

#### Local Mode File Structure
```
plugins/
├── targets_modified/
│   ├── INST/
│   │   ├── procedures/          # Ruby scripts
│   │   ├── screens/             # Screen definitions
│   │   └── lib/                 # Shared libraries
│   └── EXAMPLE/
│       ├── procedures/
│       └── screens/
```

#### Local Mode Best Practices
- Use Visual Studio Code for editing
- Configuration manage the entire project directory
- Copy modified files back to original plugin for releases
- Rebuild plugins with: `./openc3.sh cli rake build VERSION=1.0.1`

### Plugin Development

#### Plugin Structure
```
plugins/
├── DEFAULT/
│   ├── plugin-name/
│   │   ├── plugin-name-version.gem  # Ruby gem package
│   │   └── plugin_instance.json     # Plugin configuration
│   └── targets_modified/            # Modified target configurations
```

#### Plugin Configuration Best Practices
- **LEAN CONFIGURATIONS**: Keep configs minimal - only define what's necessary
- **AVOID OVER-ENGINEERING**: Don't create complex abstractions for simple needs
- Use ERB templating for dynamic configurations
- Define variables in `plugin_instance.json` for reusability
- Follow the pattern: one target per plugin (unless demo/example)
- Use conditional logic with `<% if variable %>` blocks

#### Interface Development
- **Ruby Interfaces**: Use `.rb` files for hardware interfaces
- **Python Interfaces**: Use `.py` files (e.g., `simulated_target_interface.py`)
- Map interfaces to targets with `MAP_TARGET`
- Use `DONT_CONNECT` for development/testing

## Ruby Development Guidelines

### Coding Standards
- **CONCISE CODE**: Write minimal, readable code - avoid unnecessary complexity and verbose patterns
- **NO CODE SPRAWL**: Keep functions small (< 20 lines), files focused (< 200 lines), minimize dependencies
- Follow Ruby community conventions
- Use descriptive variable names matching COSMOS patterns:
  - `target_name` for target identifiers
  - `interface_name` for interface identifiers
  - `microservice_name` for service identifiers
- Use ERB templating for configuration files
- Implement proper error handling for hardware interfaces

### Ruby Files in COSMOS
- **Interfaces**: `*_interface.rb` files for hardware communication
- **Targets**: `*_target.rb` files for simulated targets
- **Microservices**: Ruby microservice implementations
- **Scripts**: Automation and test scripts

### Testing Practices
- Test plugins in isolated COSMOS environments
- Use Docker containers for integration testing
- Test interface connectivity with `DONT_CONNECT` flag during development
- Validate configurations before deployment

## Python Development Guidelines

### Coding Standards
- **CONCISE CODE**: Write minimal, readable code - avoid unnecessary complexity and verbose patterns
- **NO CODE SPRAWL**: Keep functions small (< 20 lines), files focused (< 200 lines), minimize dependencies
- Follow PEP 8 for Python code style
- Use type hints where appropriate
- Implement proper exception handling
- Use descriptive function and variable names

### Python Files in COSMOS
- **Interfaces**: `*_interface.py` files (e.g., `simulated_target_interface.py`)
- **Targets**: `*_target.py` files for simulated hardware
- **Scripts**: Python automation scripts
- **Utilities**: Helper modules and libraries

### Python-Ruby Integration
- Python interfaces integrate with Ruby COSMOS core
- Use consistent naming conventions between languages
- Maintain compatibility with COSMOS API patterns

## Configuration Management

### Environment Variables
- Use `.env` file for version and configuration management
- Define plugin variables in `plugin_instance.json`
- Use ERB templating for dynamic values
- Set appropriate log retention times

### Security Best Practices
- Store sensitive data in environment variables
- Use Redis ACL files for user authentication
- Implement proper certificate management
- Avoid hardcoding credentials in configuration files

## Container Development

### Docker Best Practices
- Use official COSMOS base images from `docker.io/openc3inc`
- Implement proper health checks
- Use multi-stage builds for efficiency
- Set appropriate restart policies

### Service Architecture
- **openc3-cmd-tlm-api**: Command/Telemetry API server
- **openc3-script-runner-api**: Script execution service
- **openc3-operator**: Core operational service
- **openc3-minio**: Object storage service
- **openc3-redis**: Primary data streaming
- **openc3-traefik**: Reverse proxy and routing

## Testing Strategy

### Integration Testing
- Test full service stack with Docker Compose
- Validate plugin installation and configuration
- Test interface connectivity and data flow
- Verify microservice communication

### Development Testing
- Use `DONT_CONNECT` for interface testing
- Implement gradual connectivity testing
- Test with simulated targets before hardware
- Validate configuration templates

## Performance Guidelines

### Resource Management
- Set appropriate CPU limits for reducers (`REDUCER_MAX_CPU_UTILIZATION`)
- Configure log cycle times based on environment
- Use `REDUCER_DISABLE` for targets that don't need data reduction
- Set proper log retention policies

### Optimization
- Use conditional plugin loading based on environment
- Implement efficient data streaming patterns
- Optimize container resource allocation
- Monitor service health and performance

## Deployment Practices

### Version Management
- Use semantic versioning for plugins (e.g., `6.4.2`)
- Tag container images appropriately
- Maintain version compatibility across services
- Update `.env` file for version changes

### Configuration Deployment
- Use environment-specific configurations
- Implement blue-green deployment strategies
- Test configurations in staging environments
- Maintain backup configurations

## Common Commands

### Development Utilities
```bash
# Enter CLI mode
./openc3.sh cli

# Access utility functions
./openc3.sh util

# Sync COSMOS components
./scripts/linux/sync_openc3.sh
```

### Container Management
```bash
# View container status
docker compose ps

# View logs
docker compose logs [service-name]

# Restart specific service
docker compose restart [service-name]
```

## Troubleshooting

### Common Issues
- **Port conflicts**: Check that required ports (7779, 9999, 5025) are available
- **Permission issues**: Ensure proper Docker permissions
- **Plugin errors**: Validate JSON configuration syntax
- **Interface connectivity**: Check network configuration and firewall settings

### Debugging
- Use container logs for troubleshooting
- Validate ERB template syntax
- Check Redis connectivity for streaming issues
- Monitor Traefik routing configuration

## License Considerations
- **COSMOS Core**: Licensed under AGPLv3 (free, open source)
- **AGPLv3 Requirements**: Users must have access to COSMOS source code and any extensions
- **Commercial Use**: Consider license implications for proprietary extensions
- **Plugin Development**: Extensions built on COSMOS must comply with AGPLv3
- **Source Code Access**: Must provide source code access to all users

## Core Single Server Limitations
- **User Management**: Single user with shared admin password
- **Scalability**: Limited to single server deployment
- **Enterprise Features**: No calendar, autonomic features, or role-based access
- **Support**: No official OpenC3 support included
- **Production Use**: Not recommended for production environments requiring multi-user access