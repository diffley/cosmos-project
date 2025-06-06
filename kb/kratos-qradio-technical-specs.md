# Kratos qRadio/QuantumRadio Technical Specifications

## System Overview

**quantumRadio** provides signal processing functions for space-ground communication through a virtualized software modem. Key characteristics:

- **Architecture**: Software-only implementation (no FPGA or GPU required)
- **Platform**: Standard x86 servers (on-premise or cloud)
- **Functions**: Modulation, demodulation, error correction, frequency conversion
- **Purpose**: TT&C (Telemetry, Tracking, and Command) for satellite operations

## Supported API Interfaces

### Standard Interfaces
- **TCP/IP**: Standard networking protocol
- **GEMS**: Ground Equipment Management System
- **REST**: RESTful HTTP API
- **VITA-49**: Digital radio transport standard

### VITA-49 Protocol Details
- **Purpose**: Message interoperability between multi-vendor equipment
- **Transport Agnostic**: Works over TCP, UDP, Serial RapidIO, Aurora, etc.
- **Data Format**: Digital IF (Intermediate Frequency) over Ethernet/IP
- **Standards**: Industry standard for software radio systems

## Technical Capabilities

### Bandwidth and Performance
- **Narrowband**: Up to 10 MHz bandwidth (quantumRadio)
- **Wideband**: Up to 600 Mbps throughput (quantumRX receiver)
- **Instantaneous BW**: Several hundred MHz for wideband operations

### Modulation and Error Correction
- Wide range of modulation schemes
- Multiple forward error correction (FEC) options
- Designed for narrowband commanding and telemetry
- Supports narrowband payload operations

### Standards Compliance
- **VITA-49**: Digital radio transport
- **CCSDS**: Consultative Committee for Space Data Systems
- **XTCE**: XML Telemetry and Command Exchange
- Industry-standard data ingest and export formats

## Command and Control Integration

### quantumCMD Integration
- **Purpose**: Central data management for command, telemetry, and M&C
- **Scope**: Core functions for small satellite missions
- **Consolidation**: TT&C functions in single product
- **Compatibility**: Supports most smallsat community equipment

### Interface Standards
- **Data Ingest**: Standards-based equipment control
- **Command Interface**: XTCE-compliant command definitions
- **Telemetry Processing**: Standards-based telemetry handling
- **Equipment Control**: Industry-standard M&C interfaces

## Deployment Characteristics

### Lead Times
- **Hardware Systems**: 3-6 months typical delivery
- **quantumRadio**: Less than 30 days advertised lead time

### Scalability
- Software-only receiver scales based on demand
- Cloud-native deployment options
- Standards-based architecture for multi-mission support

## OpenC3 Integration Considerations

### Interface Implementation Options

1. **TCP/IP Interface**
   - Use OpenC3's `tcpip_client_interface.rb`
   - Connect to quantumRadio TCP/IP service
   - Implement custom protocol handlers

2. **REST API Interface**
   - Create custom HTTP/REST interface class
   - Use Ruby HTTP libraries (Net::HTTP, HTTParty)
   - Parse JSON responses for telemetry data

3. **VITA-49 Interface**
   - Implement custom VITA-49 protocol handler
   - Parse VITA-49 packet structure
   - Extract telemetry data from digital IF streams

### Command and Telemetry Mapping

#### Commands (to quantumRadio)
- Frequency tuning commands
- Modulation parameter settings
- Filter configuration
- Power control
- Data routing configuration

#### Telemetry (from quantumRadio)
- Signal strength indicators
- Frequency status
- Modulation parameters
- Error rates and statistics
- System health and status

### Required Research Items
- [ ] Specific TCP/IP protocol format and ports
- [ ] REST API endpoint documentation
- [ ] VITA-49 packet structure for quantumRadio
- [ ] Authentication and security requirements
- [ ] Command syntax and parameter ranges
- [ ] Telemetry data formats and update rates
- [ ] Error handling and status codes
- [ ] Configuration management interfaces

## Next Steps for Plugin Development

1. **Contact Kratos**: Request detailed API documentation
2. **Protocol Selection**: Choose primary interface (TCP/IP vs REST vs VITA-49)
3. **Interface Development**: Create OpenC3 interface class
4. **Command Definitions**: Define command packets and parameters
5. **Telemetry Definitions**: Define telemetry packets and data items
6. **Testing Strategy**: Plan interface validation and integration testing