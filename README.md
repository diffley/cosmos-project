# OpenC3 COSMOS Project

Cloud-native command and control system with enhanced environment management and organizational deployment capabilities.

## Quick Start

```bash
# Clone and setup
git clone https://github.com/openc3/cosmos-project.git cosmos-myprojectname
cd cosmos-myprojectname

# Create local & secrets files
cp .env.local.example .env.local
cp .env.secrets.example .env.secrets
# Edit both with your information as needed

# Start COSMOS
./openc3.sh run          # Development environment
./openc3.sh run prod     # Production environment

# Access at http://localhost:2900 (after ~2 minutes)
```

## Environment Configuration

**Hierarchical Loading:** `.env.defaults` → `.env.{env}` → `.env.local` → `.env.secrets`

- **`.env.defaults`**: Base configuration (committed)
- **`.env.dev`**: Development overrides (committed)  
- **`.env.prod`**: Production overrides (committed) - you can add and utilize other environments as needed with additional `.env.{env}` files
- **`.env.local`**: Personal overrides (gitignored)
- **`.env.secrets`**: Sensitive data (gitignored)

## Deployment Options

### Local Development
Direct usage for development and testing:
```bash
./openc3.sh run dev     # Start with development config
./openc3.sh stop        # Stop services  
./openc3.sh cleanup     # Remove data
```

### Organizational Deployment
Ansible-based infrastructure management for dev/staging/production environments:

**Environment Setup (prepare hosts):**
```bash
cd ansible
ansible-playbook -i inventories/dev/hosts playbooks/cosmos-prep.yml     # Development
ansible-playbook -i inventories/prod/hosts playbooks/cosmos-prep.yml    # Production
```

**Application Deployment:**
```bash
ansible-playbook -i inventories/dev/hosts playbooks/cosmos-deploy.yml   # Development
ansible-playbook -i inventories/prod/hosts playbooks/cosmos-deploy.yml  # Production
```

**Deployment Control Options:**
```bash
# Pull images only (no start)
ansible-playbook -i inventories/dev/hosts playbooks/cosmos-deploy.yml --extra-vars="cosmos_start_services=false"

# Start services only (no pull)
ansible-playbook -i inventories/dev/hosts playbooks/cosmos-deploy.yml --extra-vars="cosmos_pull_images=false"

# Full deployment (default)
ansible-playbook -i inventories/dev/hosts playbooks/cosmos-deploy.yml
```

**Available Environments:**
- `dev`: Local development with Docker already installed (codespaces)
- `prod`: Production servers with full Docker installation
- `airgap`: Air-gapped/secure environments with internal registries

**Post-deployment:**
- Access COSMOS at http://target-host:2900 (after ~2 minutes)
- SSH to target and run: `cd /opt/cosmos && sudo -u cosmos ./openc3.sh stop` to stop

### Air-Gapped Deployment
For secure/offline environments using internal Nexus registry:
```bash
# Create bundle (excludes container images - use Nexus registry)
./scripts/bundle-for-airgap.sh 6.4.2

# Prepare air-gapped hosts
ansible-playbook -i inventories/airgap/hosts playbooks/cosmos-prep.yml

# Deploy application
ansible-playbook -i inventories/airgap/hosts playbooks/cosmos-deploy.yml
```

### Manual Cleanup After Unsuccessful Ansible Application
```bash
rm -rf /opt/cosmos
docker stop $(docker ps -aq)
docker system prune -af
```

## Documentation
- [Environment Management & Ansible Integration](docs/README.md)
- [Detailed Configuration Guide](docs/ansible-integration.md)

## Run without the Demo project

1. Edit .env and remove the OPENC3_DEMO line
2. If you have already ran with the demo also uninstall the demo plugin from the Admin tool.

## Upgrade to a Specific Version

1. Stop OpenC3
   1. On Linux/Mac: ./openc3.sh stop
   2. On Windows: openc3.bat stop
2. Edit .env and change OPENC3_TAG to the specific version you would like to run (ie. OPENC3_TAG=5.0.8)
3. Start OpenC3
   1. On Linux/Mac: ./openc3.sh run
   2. On Windows: openc3.bat run

NOTE: Downgrades are not necessarily supported. When upgrading COSMOS we need to upgrade databases and sometimes migrate internal data structures. While we perform a full regression test on every release, we recommend upgrading an individual machine with your specific plugins and do local testing before rolling out the upgrade to your production system.

## Change all default credentials and secrets

1. Edit .env and change:
   1. SECRET_KEY_BASE
   2. OPENC3_SERVICE_PASSWORD
   3. OPENC3_REDIS_PASSWORD
   4. OPENC3_BUCKET_PASSWORD
   5. OPENC3_SR_REDIS_PASSWORD
   6. OPENC3_SR_BUCKET_PASSWORD
2. Edit ./openc3-redis/users.acl and change the password for each account. Note passwords for openc3/scriptrunner must match the REDIS passwords in the .env file:
   1. openc3
   2. admin
   3. scriptrunner

Passwords stored in `./openc3-redis/users.acl` use a sha256 hash.
To generate a new hash use the following method, and then copy / paste into users.acl

```bash
echo -n 'adminpassword' | openssl dgst -sha256
SHA2-256(stdin)= 749f09bade8aca755660eeb17792da880218d4fbdc4e25fbec279d7fe9f65d70
```

## Opening to the Network

Important: Before exposing OpenC3 COSMOS to any network, even a local network, make sure you have changed all default credentials and secrets!!!

### Open to the network using https/SSL and your own certificates

1. Copy your public SSL certicate to ./openc3-traefik/cert.crt
2. Copy your private SSL certicate to ./openc3-traefik/cert.key
3. Edit compose.yaml
   1. Comment out this openc3-traefik line: `- "./openc3-traefik/traefik.yaml:/etc/traefik/traefik.yaml:z"`
   2. Uncomment this openc3-traefik line: `- "./openc3-traefik/traefik-ssl.yaml:/etc/traefik/traefik.yaml"`
   3. Uncomment this openc3-traefik line: `- "./openc3-traefik/cert.key:/etc/traefik/cert.key"`
   4. Uncomment this openc3-traefik line: `- "./openc3-traefik/cert.crt:/etc/traefik/cert.crt"`
4. If you are able to run as the standard browser ports 80/443, edit compose.yaml:
   1. Comment out this openc3-traefik line: `- "127.0.0.1:2900:2900"`
   2. Comment out this openc3-traefik line: `- "127.0.0.1:2943:2943"`
   3. Uncomment out this openc3-traefik line: `- "80:2900"`
   4. Uncomment out this openc3-traefik line: `- "443:2943"`
5. If not, edit compose.yaml:
   1. Remove 127.0.0.1 from this line: `- "127.0.0.1:2900:2900"`
   2. Remove 127.0.0.1 from this line: `- "127.0.0.1:2943:2943"`
6. Edit ./openc3-traefik/traefik-ssl.yaml
   1. Update line 14 to the first port number in step 4 or 5: to: ":2943" # This should match port forwarding in your compose.yaml
   2. Update line 22 to your domain: - main: "mydomain.com" # Update with your domain
7. Start OpenC3
   1. On Linux/Mac: ./openc3.sh run
   2. On Windows: openc3.bat run
8. After approximately 2 minutes, open a web browser to `https://<Your IP Address>` (or `https://<Your IP Address>:2943` if you can't use standard ports)
   1. If you run "docker ps", you can watch until the openc3-init container completes, at which point the system should be fully configured and ready to use.

### Open to the network using a global certificate from Let's Encrypt

Warning: These directions only work when exposing OpenC3 to the internet. Make sure you understand the risks and have properly configured your server settings and firewall.

1. Make sure that your DNS settings are mapping your domain name to your server
2. Edit compose.yaml
   1. Comment out this openc3-traefik line: `- "./openc3-traefik/traefik.yaml:/etc/traefik/traefik.yaml:z"`
   2. Uncomment this openc3-traefik line: `- "./openc3-traefik/traefik-letsencrypt.yaml:/etc/traefik/traefik.yaml"`
3. Edit compose.yaml:
   1. Comment out this openc3-traefik line: `- "127.0.0.1:2900:2900"`
   2. Comment out this openc3-traefik line: `- "127.0.0.1:2943:2943"`
   3. Uncomment out this openc3-traefik line: `- "80:2900"`
   4. Uncomment out this openc3-traefik line: `- "443:2943"`
4. Start OpenC3
   1. On Linux/Mac: ./openc3.sh run
   2. On Windows: openc3.bat run
5. After approximately a few minutes, open a web browser to `https://<Your Domain Name>`
   1. If you run "docker ps", you can watch until the openc3-init container completes, at which point the system should be fully configured and ready to use.

### Open to the network insecurely using http

Warning: This is not recommended except for temporary testing on a local network. This will send plain text passwords over the network!

1. Edit compose.yaml
   1. Comment out this openc3-traefik line: `- "./openc3-traefik/traefik.yaml:/etc/traefik/traefik.yaml:z"`
   2. Uncomment this openc3-traefik line: `- "./openc3-traefik/traefik-allow-http.yaml:/etc/traefik/traefik.yaml"`
   3. Remove 127.0.0.1 from this line: `- "127.0.0.1:2900:2900"`
2. Start OpenC3
   1. On Linux/Mac: ./openc3.sh run
   2. On Windows: openc3.bat run
3. After approximately 2 minutes, open a web browser to `https://<Your IP Address>:2900`
   1. If you run "docker ps", you can watch until the openc3-cosmos-init container completes, at which point the system should be fully configured and ready to use.
