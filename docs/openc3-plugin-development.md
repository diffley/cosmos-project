# OpenC3 Plugin Development Knowledge Base

## Plugin Generators

### Available Generator Types
1. **Plugin Generator**: Creates scaffolding for new plugins
2. **Target Generator**: Creates target-specific configurations
3. **Microservice Generator**: Creates background processing services
4. **Conversion Generator**: Creates data conversion modules
5. **Processor Generator**: Creates data processing modules
6. **Limits Response Generator**: Creates limit monitoring responses
7. **Widget Generator**: Creates custom telemetry viewer widgets
8. **Tool Generator**: Creates web-based tools

### Generator Usage
```bash
# Must be run inside existing COSMOS plugin directory
openc3.sh cli generate <type> <name>

# Example: Create a new plugin
openc3.sh cli generate plugin GSEPlugin
```

### Generated Files Structure
- `.gitignore`
- `LICENSE.txt`
- `plugin.txt` (main configuration)
- `README.md`
- `Rakefile`
- Target-specific directories and files

## Target Configuration

### Target Definition
- Targets represent "external embedded systems that COSMOS connects to"
- Configured in `target.txt` file within target directory
- Located in `targets/<TARGET_NAME>/target.txt`

### Key Configuration Keywords
1. **LANGUAGE**: Specifies programming language (Ruby or Python)
2. **REQUIRE**: Lists Ruby file dependencies
3. **IGNORE_PARAMETER**: Hides specific command parameters
4. **IGNORE_ITEM**: Hides specific telemetry items
5. **COMMANDS**: Specifies command definition files
6. **TELEMETRY**: Specifies telemetry definition files

### Target Configuration Example
```
LANGUAGE python
REQUIRE limits_response.rb
IGNORE_PARAMETER CCSDS_VERSION
COMMANDS inst_cmds_v2.txt
TELEMETRY inst_tlm_v2.txt
```

### Target Directory Structure
```
targets/
├── QRADIO/
│   ├── target.txt
│   ├── cmd_tlm/
│   │   ├── qradio_cmds.txt
│   │   └── qradio_tlm.txt
│   ├── lib/
│   │   └── qradio_interface.rb
│   └── procedures/
│       └── qradio_procedures.rb
```

## Plugin Configuration (plugin.txt)

### Plugin Components
1. **Targets**: External hardware/software systems
2. **Interfaces**: Physical connections to targets
3. **Routers**: Stream telemetry packets in/out of COSMOS
4. **Tools**: Web-based applications
5. **Microservices**: Background processing services

### Key Configuration Keywords
1. **VARIABLE**: Defines configurable plugin variables
2. **INTERFACE**: Defines connection to physical targets
3. **ROUTER**: Creates intermediary for command/telemetry transmission
4. **TARGET**: Defines new targets with logging and processing options
5. **MICROSERVICE**: Defines background processing services
6. **TOOL**: Adds web-based tools to OpenC3
7. **WIDGET**: Defines custom telemetry viewer widgets

### Configuration Best Practices
- Use `VARIABLE` for user-configurable parameters (IP addresses, ports, etc.)
- Leverage ERB syntax for dynamic configuration
- Configure logging, buffer depths, and retention times
- Use meaningful naming conventions
- Implement proper secrets management

### Example Plugin Configuration
```
VARIABLE qradio_host
VARIABLE qradio_port

INTERFACE QRADIO_INT tcpip_client_interface.rb <%= qradio_host %> <%= qradio_port %>
MAP_TARGET QRADIO

TARGET QRADIO <%= target_name %>
```

## Interface Development

### Interface Types
- **tcpip_client_interface.rb**: TCP/IP client connections
- **tcpip_server_interface.rb**: TCP/IP server connections
- **serial_interface.rb**: Serial port connections
- **udp_interface.rb**: UDP connections
- Custom interfaces for specific protocols

### Interface Configuration
```
INTERFACE <name> <interface_class> <parameters>
MAP_TARGET <target_name>
```

### Custom Interface Development
- Inherit from appropriate base interface class
- Implement required methods for connection, reading, writing
- Handle protocol-specific message formatting
- Implement error handling and reconnection logic

## Development Workflow for qRadio Plugin

### Phase 1: Research and Planning
1. Identify qRadio communication protocol (gRPC/REST/TCP)
2. Define command and telemetry message formats
3. Determine connection parameters and authentication
4. Map qRadio capabilities to COSMOS concepts

### Phase 2: Plugin Structure
1. Generate base plugin using OpenC3 generators
2. Create target definition for qRadio
3. Define interface for qRadio communication protocol
4. Create command and telemetry definitions

### Phase 3: Implementation
1. Implement custom interface for qRadio API
2. Define command definitions in `qradio_cmds.txt`
3. Define telemetry definitions in `qradio_tlm.txt`
4. Create Ruby/Python procedures for common operations

### Phase 4: Testing and Integration
1. Test interface connectivity
2. Validate command execution
3. Verify telemetry reception
4. Create test scripts and procedures