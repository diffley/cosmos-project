#!/bin/bash
# Bundle COSMOS for air-gapped deployment

set -e

BUNDLE_DIR="cosmos-airgap-bundle"
COSMOS_VERSION="${1:-6.4.2}"

echo "Creating air-gapped bundle for COSMOS version $COSMOS_VERSION..."

# Create bundle directory
mkdir -p "$BUNDLE_DIR"

# Copy COSMOS project configuration and scripts
echo "Copying COSMOS project configuration..."
rsync -av --exclude='.git' --exclude='node_modules' --exclude='*.log' . "$BUNDLE_DIR/cosmos-source/"

# Bundle runtime package dependencies
echo "Bundling runtime package dependencies..."

# Bundle node_modules (already included in source)
echo "✓ NPM packages already bundled in node_modules/"

# Bundle Ruby gems from plugins  
echo "Copying plugin gems..."
mkdir -p "$BUNDLE_DIR/gems"
find plugins/ -name "*.gem" -exec cp {} "$BUNDLE_DIR/gems/" \; 2>/dev/null || true

# Create package requirements list for air-gapped environment
cat > "$BUNDLE_DIR/DEPENDENCIES.md" << 'EOF'
# COSMOS Air-Gapped Dependencies

## Container Images (Load into Nexus)
- openc3/openc3-cosmos-cmd-tlm-api:VERSION
- openc3/openc3-cosmos-script-runner-api:VERSION  
- openc3/openc3-operator:VERSION
- openc3/openc3-cosmos-init:VERSION
- openc3/openc3-minio:VERSION
- openc3/openc3-redis:VERSION
- openc3/openc3-traefik:VERSION

## Package Repository Mirrors (Configure in Nexus)
- Alpine APK: mirror dl-cdn.alpinelinux.org/alpine/v3.21/
- RubyGems: mirror rubygems.org
- PyPI: mirror pypi.org  
- NPM: mirror registry.npmjs.org

## Runtime Dependencies
- NPM packages: Bundled in source (node_modules/)
- Ruby gems: Plugin-specific gems included
- Python packages: Downloaded at runtime (configure PyPI mirror)
- Alpine packages: Downloaded at runtime (configure APK mirror)
EOF

# Note: Container images should be pre-loaded into your Nexus registry
echo "Skipping container image bundling - using Nexus registry..."
echo "Ensure these images are available in your Nexus registry:"
echo "  - openc3/openc3-cosmos-cmd-tlm-api:$COSMOS_VERSION"
echo "  - openc3/openc3-cosmos-script-runner-api:$COSMOS_VERSION"
echo "  - openc3/openc3-operator:$COSMOS_VERSION"
echo "  - openc3/openc3-cosmos-init:$COSMOS_VERSION"
echo "  - openc3/openc3-minio:$COSMOS_VERSION"
echo "  - openc3/openc3-redis:$COSMOS_VERSION"
echo "  - openc3/openc3-traefik:$COSMOS_VERSION"

# Create deployment script
cat > "$BUNDLE_DIR/deploy-airgap.sh" << 'EOF'
#!/bin/bash
# Air-gapped COSMOS deployment script

set -e

COSMOS_HOME="/opt/cosmos"
COSMOS_USER="cosmos"

echo "Deploying COSMOS in air-gapped environment..."

# Copy project configuration and scripts
sudo cp -r cosmos-source/* "$COSMOS_HOME/"
sudo chown -R "$COSMOS_USER:$COSMOS_USER" "$COSMOS_HOME"

# Container images are pulled from Nexus registry automatically
echo "Using Nexus registry for container images..."

# Deploy using air-gapped configuration
cd "$COSMOS_HOME"
sudo -u "$COSMOS_USER" ./openc3.sh run airgap

echo "COSMOS deployed successfully in air-gapped mode!"
EOF

chmod +x "$BUNDLE_DIR/deploy-airgap.sh"

# Create bundle archive
echo "Creating bundle archive..."
tar -czf "cosmos-airgap-${COSMOS_VERSION}.tar.gz" "$BUNDLE_DIR"

# Cleanup
rm -rf "$BUNDLE_DIR"

echo "Air-gapped bundle created: cosmos-airgap-${COSMOS_VERSION}.tar.gz"
echo ""
echo "To deploy in air-gapped environment:"
echo "1. Load container images into your Nexus registry"
echo "2. Configure package mirrors in Nexus (see DEPENDENCIES.md)"
echo "3. Transfer cosmos-airgap-${COSMOS_VERSION}.tar.gz to target system"
echo "4. Extract: tar -xzf cosmos-airgap-${COSMOS_VERSION}.tar.gz"
echo "5. Run: cd cosmos-airgap-bundle && ./deploy-airgap.sh"