#!/bin/bash
# Bundle COSMOS for air-gapped deployment

set -e

BUNDLE_DIR="cosmos-airgap-bundle"
COSMOS_VERSION="${1:-6.4.2}"

echo "Creating air-gapped bundle for COSMOS version $COSMOS_VERSION..."

# Create bundle directory
mkdir -p "$BUNDLE_DIR"

# Copy COSMOS source code
echo "Copying COSMOS source..."
rsync -av --exclude='.git' --exclude='node_modules' --exclude='*.log' . "$BUNDLE_DIR/cosmos-source/"

# Save container images
echo "Saving container images..."
./openc3.sh util save docker.io openc3inc "$COSMOS_VERSION"

# Move saved images to bundle
if [ -f "openc3-${COSMOS_VERSION}.tar" ]; then
    mv "openc3-${COSMOS_VERSION}.tar" "$BUNDLE_DIR/cosmos-images.tar"
fi

# Create deployment script
cat > "$BUNDLE_DIR/deploy-airgap.sh" << 'EOF'
#!/bin/bash
# Air-gapped COSMOS deployment script

set -e

COSMOS_HOME="/opt/cosmos"
COSMOS_USER="cosmos"

echo "Deploying COSMOS in air-gapped environment..."

# Copy source code
sudo cp -r cosmos-source/* "$COSMOS_HOME/"
sudo chown -R "$COSMOS_USER:$COSMOS_USER" "$COSMOS_HOME"

# Load container images
if [ -f cosmos-images.tar ]; then
    echo "Loading container images..."
    sudo docker load < cosmos-images.tar
fi

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
echo "1. Transfer cosmos-airgap-${COSMOS_VERSION}.tar.gz to target system"
echo "2. Extract: tar -xzf cosmos-airgap-${COSMOS_VERSION}.tar.gz"
echo "3. Run: cd cosmos-airgap-bundle && ./deploy-airgap.sh"