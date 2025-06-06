# CLAUDE.md - COSMOS/OpenC3 Development Guidelines

## Project Overview
This is a COSMOS (OpenC3) cloud-native command and control system project. COSMOS uses a containerized microservices architecture with Ruby as the primary language and Python support for scripting and interfaces.

## Architecture & Tech Stack
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
- `.env`: Environment variables and version configuration
- `openc3.sh`/`openc3.bat`: Main CLI entry points
- `plugins/`: Plugin directory structure

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
- COSMOS is licensed under AGPLv3
- Consider license implications for commercial use
- Review plugin licensing requirements
- Ensure compliance with open source obligations