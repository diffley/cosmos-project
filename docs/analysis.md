**1. COSMOS Architecture Overview**

* **Microservice Components**

  * **Command and Telemetry Server**: Core service that accepts incoming command packets, validates them against defined packet definitions, and routes them to the appropriate interface. It also ingests telemetry from interfaces and republishes it for downstream consumers.
  * **Limits Monitor**: Tracks real-time telemetry against configurable limit checks (high/low, watchdogs) and generates limit-violation events (e.g., “high voltage warning”).
  * **Command Sender**: Handles command scheduling and queuing logic—managing immediate, delayed, and queued command transmissions. Ensures ordered delivery and retry behaviors.
  * **Script Runner**: Interactive Ruby/Python REPL environment where operators can type cmd(...) and tlm(...) calls. Provides code-completion, command validation, and telemetry subscriptions for rapid prototyping.
  * **Packet Viewer**: GUI that displays raw command and telemetry packet contents in hex/ascii. Useful for low-level debugging.
  * **Telemetry Viewer**: Presents tabular telemetry streams, including current values, historic logs, and status flags. Often paired with filters and simple dashboards.
  * **Telemetry Grapher**: Time-series visualization tool that plots one or more telemetry points on live or logged data. Supports annotations for events and limit lines.
  * **Data Extractor**: Exports archived telemetry to CSV or database backends (e.g., SQLite, InfluxDB) for offline analysis.
  * **Data Viewer**: Allows browsing and querying stored telemetry tables, with sorting, filtering, and pagination.
  * **Bucket Explorer**: Interfaces with “bucketed” telemetry archives (e.g., 1-second, 1-minute resolutions). Enables drill-down from coarse to fine resolution in historical data.
  * **Table Manager**: CRUD GUI for adding/editing telemetry definitions, limit definitions, and custom tables (e.g., command definitions, script catalogs).
  * **Handbooks**: Centralized repository of procedural documentation, checklists, and operating instructions, accessible from within the COSMOS web UI.
  * **Calendar**: Scheduling widget that lets users reserve resources (ground stations, antennas), create recurring jobs, and visualize availability windows.
  * **Admin**: Role-based access control (RBAC) management, system health dashboards, microservice status monitoring, and configuration overrides.         &#x20;

* **Cloud-Native, Containerized Architecture (v5+)**

  * Starting in COSMOS v5, all microservices were refactored into independent Docker containers orchestrated via Kubernetes or Docker Compose. This shift allowed:

    * **Loose Coupling**: Each service runs in its own container with minimal dependencies, enabling independent scaling (e.g., more Telemetry Grapher instances when load is high).
    * **Simplified Deployment**: Teams can deploy on any Kubernetes-compatible environment—on-premise or cloud (AWS, GCP)—and utilize helm charts or compose files rather than monolithic installers.
    * **Fault Isolation**: Crashes in the Packet Viewer or Data Extractor do not bring down the Command & Telemetry Server. Services auto-restart based on health checks.
    * **Versioning & Rollbacks**: Container tags allow pinning to specific COSMOS versions, facilitating seamless upgrades or instant rollback in case of regressions. &#x20;

---

**2. Core Functional Capabilities**

* **Commanding**

  * **Packet Definitions**: COSMOS uses a centralized YAML/JSON schema (in the “Tables” database) to define command packet structures (e.g., fields, bit-masks, enumerations). Every packet is validated against its definition prior to send.
  * **Routing & Queuing**: The Command Sender service applies priority rules and timing (immediate vs. delayed vs. scheduled). Packets are queued in Redis lists before dispatch, ensuring retry on failure.
  * **Multi-Interface Support**: Interfaces (TCP, UDP, Serial, or custom plugin-based transports) register themselves with the Command & Telemetry Server. Commands are dispatched to the correct interface instance based on target name.

* **Telemetry Streaming**

  * **StreamingApi Architecture**:

    * **StreamingThread**: Base class that continuously reads from a data source (e.g., interface socket or log file) and publishes packets to Redis streams.
    * **RealtimeStreamingThread**: Reads live bytes from hardware interfaces, parses them into telemetry frames, and pushes them to the “current\_value” namespace in Redis for immediate consumption by the Telemetry Viewer or Grapher.
    * **LoggedStreamingThread**: Reads historical telemetry (log files or archived buckets) and re-publishes them to the same Redis streams, enabling “playback” functionality in the Grapher.  &#x20;

  * **Historical vs. Live Modes**: Operators can toggle between live streaming (subscribing to RealtimeRedis channels) and historical playback (subscribing to LoggedRedis channels). Any GUI widget (e.g., Telemetry Grapher) simply points to the desired Redis stream.

* **Scripting**

  * **Languages Supported**: Ruby (primary) and Python (optional). Script Runner launches a REPL session with built-in bindings:

    * `cmd(<packet_name>, <fields>)` submits a command.
    * `tlm(<telemetry_name>)` subscribes to telemetry channels.
    * `wait_tlm(<telemetry_name>, <value>, <timeout>)` blocks until a condition is met.
  * **Environment Features**:

    * **Code Completion**: Based on current Tables definitions, operators get auto-completion of packet names, field names, and telemetry names.
    * **Procedure Execution**: Supports def-in-REPL procedures for gating logic, e.g., “send power\_on; wait 5; verify voltage\_above 28V”.
    * **Logging & Error Handling**: Console logs command responses, telemetry updates, exceptions, and stack traces, all timestamped.

* **Data Visualization**

  * **Telemetry Viewer**: Tabular grid showing telemetry names, values, units, and timestamps. Columns can be filtered, sorted, and color-coded based on limit definitions.
  * **Telemetry Grapher**:

    * Plot multiple telemetry channels over time.
    * Supports annotations: limit crosses, command sent flags, and manual annotations.
    * Zoom/pan on the time axis for drill-down analysis.
  * **Packet Viewer**: Displays raw packet bytes in hex alongside ASCII equivalents, with color-coded bytes for headers, payload, and checksums.
  * **Data Viewer**:

    * Query historical data tables (time-series DB or SQLite).
    * Export to CSV or external BI tools.
  * **Bucket Explorer**: Automatically groups telemetry into buckets (1-sec, 1-min, 1-hour), enabling rapid retrieval of coarse-resolution or fine-resolution data depending on user request.

* **Scheduling (Calendar Tool)**

  * **Resource Reservation**: Define resources (e.g., Antenna-A, RF-Amplifier-B).
  * **Recurring Events**: Set up cron-like schedules for tasks (daily health check commands, weekly calibration sequences).
  * **Conflict Detection**: Calendar UI highlights overlapping reservations, preventing double-booking of limited hardware.
  * **Job Metadata**: Attach scripts or command block references to calendar entries, enabling COSMOS to auto-run command sequences at scheduled times.

* **Plugin System**

  * **`plugin.gemspec` + `plugin.txt`**:

    * `plugin.gemspec` defines gem metadata (name, version, dependencies).
    * `plugin.txt` registers plugin contents:

      * **Targets**: Logical names for HydraBeam or other hardware.
      * **Interfaces**: Defines transport (e.g., TCP, gRPC) and points to the interface class.
      * **Routers**: Optional message bus bridges (e.g., JMS, Kafka).
      * **Additional Microservices**: Plugins can bundle custom COSMOS microservices (e.g., “HydraBeam Health Monitor”).
  * **Discovery & Installation**: Plugins reside in a plugins folder or a centralized “Plugin App Store” (planned). Once installed, COSMOS auto-discovers new targets, interfaces, and services at startup.&#x20;

* **Code Generators (CLI Tools)**

  * **`openc3-cosmos generator plugin`**: Scaffold a new plugin with boilerplate files.
  * **`generator target`**: Produces a target definition file (YAML) with placeholder packet definitions.
  * **`generator microservice`**: Creates a stub microservice repo (Dockerfile, Docker Compose template, basic API endpoints).
  * **`generator widget`**: Bootstraps a frontend widget (Vue/Angular/React/Svelte) for custom visualizations.
  * **`generator conversion`**: Sets up code to convert external data formats (e.g., CCSDS to COSMOS JSON).
  * **`generator limits_response`**: Creates example code for handling a limit check and sending corrective commands.
  * **`generator tool`** (and variants `tool_vue`, `tool_angular`, `tool_react`, `tool_svelte`): Sets up a CLI or GUI tool skeleton that can be plugged into the Admin or Handbooks module. &#x20;

---

**2. Core Functional Capabilities**

* **Commanding**

  * **Packet Lifecycle**:

    1. **Definition**: Packets defined in Tables (name, ID, field format).
    2. **Validation**: Command Sender checks fields for valid ranges/enumerations.
    3. **Queuing & Dispatch**: Valid commands enter Redis order queues; retries on NAK or timeouts.
    4. **Acknowledgment Handling**: Interfaces return ACK/NAK which Script Runner and Admin monitor.
  * **Routing**: Based on target name, the Command & Telemetry Server selects the appropriate interface (Serial, TCP/IP, or plugin) and sends the binary packet to the hardware.

* **Telemetry (Realtime vs. Historical)**

  * **Realtime Streaming**: RealtimeStreamingThread parses incoming telemetry frames over live interfaces and publishes to Redis Pub/Sub channels (`COSMOS:TLMS:<telemetry_name>`). Telemetry Viewer/ Grapher subscribe directly and update in milliseconds. &#x20;
  * **Logged Streaming**: LoggedStreamingThread replays archived telemetry logs stored in bucketed files or time-series DB. By republishing to the same Redis channels, COSMOS enables “time-travel” visualization—operators can scrub backward/forward in the Grapher.

* **Scripting (Ruby/Python)**

  * **Interactive Environment**: Operators use Script Runner to execute ad-hoc sequences (e.g., orbit maneuver commands or RF sweeps).
  * **Prebuilt Libraries**: COSMOS exposes helper methods (e.g., `connect_target`, `get_limit_status`) so operators can write multi-step procedures without boilerplate.

* **Data Visualization Tools**

  * **Telemetry Viewer & Grapher**: Easily drop telemetry channels into graphs; supports overlaid limit lines, custom annotations, and auto-scaling axes.
  * **Packet Viewer**: Crucial for diagnosing mismatched packet IDs or checksum errors during link testing.
  * **Data Viewer & Bucket Explorer**: Both tools help automate offline analysis, trending, and anomaly detection. Operators can specify date/time ranges, then download CSVs for further analysis in MATLAB or Python.

* **Scheduling (Calendar)**

  * **Resource Objects**: Calendar uses a JSON schema to define resources (hardware racks, antennas).
  * **Job Triggers**: Operators can assign a script (prewritten in Script Runner) to a calendar event, which the Command Sender automatically launches at the scheduled time.
  * **Conflict Alerts**: If two events contend for the same resource (e.g., Antenna-A), COSMOS flags the overlap and sends an email notification (if configured).

* **Plugin System & Code Generators**

  * **Modular Extensions**: Plugin system enables adding new hardware support (e.g., custom RF switch controllers) without modifying core COSMOS code.
  * **Scaffolded Development**: CLI generators dramatically shorten the effort to stand up a new plugin, microservice, or GUI component, enforcing COSMOS’s coding conventions from day one.        &#x20;

---

**3. Strengths & Weaknesses**

* **Architectural Strengths**

  * **Modularity & Extensibility**: Microservice separation and plugin architecture allow teams to develop independent features (e.g., HydraBeam Bridge) without touching core services.
  * **Cloud-Native Deployment**: Containerization ensures consistent behavior across environments (on-prem vs. cloud) and simplified lifecycle management (scaling, rollbacks).
  * **Rich Visualization Suite**: Built-in Grapher, Viewer, and Data tools accelerate operator situational awareness, reducing the need for custom dashboards.
  * **Standardized Interfaces**: Well-defined Redis streams, clear Ruby/Python APIs, and generator templates ensure any new service or plugin adheres to the same patterns.
  * **Active Roadmap**: Upcoming features—Plugin App Store, System Health Tool, COSMOS Notebooks—promise to fill gaps in onboarding and diagnostics. &#x20;

* **Potential Limitations**

  * **Learning Curve (Ruby-Centric)**: While Python bindings exist, many core examples/tutorials assume Ruby. A team unfamiliar with Ruby may face initial slowdowns.
  * **AGPLv3 License Constraints**: Any HydraBeam integration must comply with AGPLv3 reciprocity. If HydraBeam remains closed-source, a clear separation layer or proxy may be required to avoid license “infection.”
  * **Real-Time Performance**: Although containerized, COSMOS relies on Redis Pub/Sub for telemetry. High-rate telemetry (>100 Hz per channel) may saturate Redis or introduce small but notable latencies.
  * **Customization Overhead**: Adding deeply custom visualizations still requires writing a widget in Vue/React/Angular/Svelte and integrating it via the code generators—adding development overhead.
  * **Incomplete Ground Network Integration**: While mission-planning and flight-dynamics modules are on the roadmap, currently manual steps are needed to ingest ground network availability or ephemeris data. &#x20;

---

**4. Integration Considerations with HydraBeam**

* **Leveraging COSMOS Core Services**

  * **Command & Telemetry Server ↔ HydraBeam**:

    * Have HydraBeam expose a gRPC/REST endpoint (`/sendCommand`, `/getTelemetry`) for command execution and telemetry polling.
    * Build a COSMOS plugin interface (e.g., class `HydraBeamInterface < Cosmos::Interface`) that calls HydraBeam’s REST API whenever COSMOS issues a cmd(...) to the HydraBeam target. Conversely, the interface polls HydraBeam’s telemetry endpoint at a configurable interval (e.g., 10 Hz) and pushes telemetry into Redis streams.
  * **Calendar ↔ HydraBeam Scheduler**:

    * If HydraBeam already schedules antenna acquisitions (e.g., window opens at T0+2h), wrap HydraBeam’s scheduler as a microservice.
    * COSMOS’s Calendar could call HydraBeam’s scheduling API directly, or HydraBeam could subscribe to Redis notifications from COSMOS’s Calendar (via a ScheduledEvent microservice) and then enact those requests locally.

* **Plugin-Based Integration Strategy** &#x20;

  1. **Plugin Scaffold**:

     * Run `openc3-cosmos generator plugin hydrabeam_bridge` → generates

       ```
       hydrabeam_bridge/
       ├── plugin.txt
       ├── openc3-cosmos-hydrabeam_bridge.gemspec
       └── lib/openc3/cosmos/hydrabeam_bridge/
           ├── interface.rb
           ├── target_definition.yaml
           └── telemetry_parser.rb
       ```
     * **`plugin.txt`** example:

       ```
       plugin_name   : hydraBeamBridge
       plugin_version: 0.1.0

       targets:
         - name: HydraBeam_Antenna
           definition: lib/openc3/cosmos/hydrabeam_bridge/target_definition.yaml
           interface: HydraBeamInterface

       interfaces:
         - class_name: HydraBeamInterface
           type: REST
           config:
             endpoint: "http://hydrabeam.local:8080/api"

       routers: []

       microservices: []
       ```

  2. **Interface Implementation (Ruby)**:

     ```ruby
     # lib/openc3/cosmos/hydrabeam_bridge/interface.rb
     require 'cosmos/interfaces/base_interface'
     require 'rest-client'
     require 'json'

     module Openc3
       module Cosmos
         module HydraBeamBridge
           class HydraBeamInterface < Cosmos::Interface
             def initialize(name, config = {})
               super(name, config)
               @endpoint = config['endpoint']
               @poll_interval = config['poll_interval'] || 0.1
               
               # Start background thread for polling HydraBeam telemetry
               @telemetry_thread = Thread.new { poll_hydrabeam_telemetry }
             end

             def send_cmd(packet_id, data_fields)
               # Translate COSMOS packet into HydraBeam JSON command
               payload = { command_id: packet_id, params: data_fields }.to_json
               RestClient.post "#{@endpoint}/sendCommand", payload, {content_type: :json}
             rescue => e
               Cosmos::Logger.error("Failed to send command to HydraBeam: #{e}")
             end

             private

             def poll_hydrabeam_telemetry
               loop do
                 response = RestClient.get "#{@endpoint}/getTelemetry"
                 tlm_data = JSON.parse(response.body)
                 # Convert tlm_data to COSMOS packet
                 cosmos_packet = build_cosmos_packet(tlm_data)
                 publish_tlm(cosmos_packet)
                 sleep @poll_interval
               end
             rescue => e
               Cosmos::Logger.error("HydraBeam telemetry polling error: #{e}")
               sleep 1
               retry
             end

             def build_cosmos_packet(tlm_data)
               # Example: map JSON fields to COSMOS packet structure
               packet = Cosmos::Packet.new(
                 name:    'HYDRABEAM_TLM',
                 id:      0x30,                # arbitrary ID
                 source:  'HydraBeam'
               )
               tlm_data.each do |field_name, value|
                 packet.set_field(field_name, value)
               end
               packet
             end
           end
         end
       end
     end
     ```

     * **Registration**: In `plugin.txt`, ensuring `class_name: HydraBeamInterface` points to this Ruby class.
     * **Redis Publication**: Calling `publish_tlm(cosmos_packet)` sends packet into Redis; COSMOS’s Telemetry Viewer/Grapher subscribe automatically.

  3. **Target Definition Stub**:

     ```yaml
     # lib/openc3/cosmos/hydrabeam_bridge/target_definition.yaml
     target_name: HydraBeam_Antenna
     commands:
       - name: POINT_TO_AZ_EL
         id: 0x10
         fields:
           - name: azimuth
             type: float
             units: degrees
             application_type: Full
           - name: elevation
             type: float
             units: degrees
             application_type: Full
       - name: SET_RF_POWER
         id: 0x11
         fields:
           - name: power_level
             type: integer
             min: 0
             max: 100
     telemetry:
       - name: CURRENT_AZ_EL
         id: 0x20
         fields:
           - name: azimuth
             type: float
             units: degrees
           - name: elevation
             type: float
             units: degrees
       - name: RF_POWER_STATUS
         id: 0x21
         fields:
           - name: power_level
             type: integer
             units: percent
     ```

  4. **Script Runner Example**:

     ```ruby
     # Launch Script Runner and run:
     connect_target('HydraBeam_Antenna')
     cmd('POINT_TO_AZ_EL', { 'azimuth' => 135.0, 'elevation' => 45.0 })
     wait_tlm('CURRENT_AZ_EL', {'azimuth' => 135.0, 'elevation' => 45.0}, 10)
     puts "Antenna pointed to desired coordinates."
     ```

     * This uses COSMOS’s built-in `cmd` and `wait_tlm` calls—HydraBeamInterface intercepts and forwards to HydraBeam.

  5. **Streaming Integration**:

     * If HydraBeam broadcasts high-rate RF health metrics over WebSockets, implement a `LoggedStreamingThread` subclass:

       ```ruby
       class HydraBeamTelemetryStreamer < Cosmos::StreamingThread
         def initialize(...)
           super(...)
           @ws_url = config['ws_url']
         end

         def process_stream
           ws = create_websocket_client(@ws_url)
           ws.onmessage do |msg|
             data = JSON.parse(msg)
             packet = build_cosmos_packet(data)
             redis_publish('COSMOS:TLM:HYDRABEAM', packet.to_bytes)
           end
           ws.connect
           ws.run_forever
         end
       end
       ```
     * Register this thread in plugin’s microservice section so that on plugin startup, it automatically pushes HydraBeam telemetry into COSMOS’s Redis.

* **Integration Challenges & Considerations**

  * **Protocol Mismatch**:

    * HydraBeam may use a proprietary binary protocol; translation layers must be written for every command/telemetry field.
    * Ensure encoding/endianness align: COSMOS expects big-endian by default.
  * **Data Format Conversion**:

    * HydraBeam JSON ↔ COSMOS packet fields require strict 1:1 mapping. A missing field may cause DIM (Data Integrity Monitor) faults in COSMOS.
  * **Authorization & Security**:

    * If HydraBeam’s API requires API keys or OAuth tokens, the interface must securely store and refresh credentials.
    * COSMOS’s microservices must run in a network with firewall rules allowing connections only between trusted endpoints.
  * **Latency & Throughput**:

    * Real-time telemetry at >50 Hz may clog Redis if not properly chunked. Consider throttling or sampling HydraBeam’s stream before pushing to COSMOS.
    * Large command bursts (e.g., rapid RF power sweeps) might saturate the Command Sender’s queue—tune Redis memory limits and worker threads accordingly.
  * **Version Compatibility**:

    * If HydraBeam’s API changes (e.g., new telemetry fields), corresponding updates to `target_definition.yaml` and `build_cosmos_packet` are required.
    * Plan for backward compatibility or semantic versioning in both HydraBeam and the plugin. &#x20;

---

**5. Summary & Next Steps**

1. **Develop HydraBeam Bridge Proof-of-Concept** (High Priority)

   * Scaffold a barebones COSMOS plugin (`hydrabeam_bridge`) using `generator plugin`.
   * Implement a minimal `HydraBeamInterface` class that sends a known “NOOP” command and receives “OK” telemetry back.
   * Verify that COSMOS’s Packet Viewer shows the NOOP command and Telemetry Viewer shows the OK response.

2. **Define & Finalize Command/Telemetry Mappings**

   * Work with HydraBeam’s engineering team to create a definitive field mapping document (JSON ➔ COSMOS packet fields).
   * Populate `target_definition.yaml` fully—ensure that every HydraBeam command and telemetry item has a unique ID and valid data type.

3. **Test Real-Time Streaming Performance**

   * Build the `HydraBeamTelemetryStreamer` to push simulated high-rate RF health metrics into COSMOS.
   * Measure Redis CPU/RAM usage and Grapher update latency at various data rates (10 Hz, 50 Hz, 100 Hz). Adjust sampling or buffering strategies as needed.

4. **Address Licensing & Distribution**

   * Review AGPLv3 implications:

     * If any portion of the HydraBeam plugin uses COSMOS core code (beyond linking via REST), HydraBeam’s code may need to be published under AGPLv3.
     * Consider deploying the HydraBeam API as a standalone service (closed source), with the plugin acting as a thin wrapper that only issues network calls, thereby avoiding license contamination. &#x20;

5. **Roadmap Alignment & Contribution**

   * **COSMOS v6 Roadmap**:

     * Plan to submit HydraBeam integration to the Plugin App Store once available.
     * Explore contributing a “HydraBeam Antenna Health Monitor” microservice to the System Health Tool project.
   * **HydraBeam Roadmap**:

     * Prioritize developing an AI-driven pointing optimization module that feeds real-time data into COSMOS Notebooks for visualization and post-analysis.
     * Evaluate providing a libCSP interface (CSP = CubeSat Space Protocol) within HydraBeam so COSMOS’s future libCSP microservice can directly receive packets. &#x20;

6. **Training & Documentation**

   * Create an internal “COSMOS + HydraBeam” operator handbook (leveraging COSMOS’s Handbooks module) that outlines common workflows—for example, “Scheduling an Antenna Pass via COSMOS with HydraBeam Calibration.”
   * Provide walkthrough videos showing:

     1. Plugin installation steps.
     2. Live telemetry visualization using COSMOS Grapher.
     3. End-to-end command sequence (e.g., point, set RF, verify lock).

---

**References**

1. COSMOS Microservice List & Architecture Overview   &#x20;
2. COSMOS Cloud-Native Shift (v5)             &#x20;
3. StreamingApi & StreamingThread Details         &#x20;
4. Plugin Configuration (`plugin.gemspec`, `plugin.txt`) &#x20;
5. CLI Code Generators Overview              &#x20;
6. COSMOS Roadmap (Plugin App Store, Notebooks, etc.)     &#x20;
7. Plugin Integration Guidance & Examples         &#x20;
8. AGPLv3 Licensing Considerations             &#x20;




