#!/bin/bash
# Deploy COSMOS to Google Kubernetes Engine (GKE)
# Complete workflow for setup, building, and deployment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script modes
MODE="${1:-help}"

show_help() {
    echo -e "${GREEN}🚀 COSMOS GKE Deployment Script${NC}"
    echo "================================="
    echo ""
    echo "Usage: $0 [command] [options]"
    echo ""
    echo "Commands:"
    echo "  setup         - Configure GCP project, enable APIs, create cluster"
    echo "  deploy        - Deploy COSMOS to GKE cluster"
    echo "  all           - Run setup and deploy"
    echo "  status        - Check cluster and service status"
    echo "  logs          - View COSMOS service logs"
    echo "  expose        - Create external LoadBalancer for web access"
    echo "  update        - Update COSMOS deployment with new config"
    echo "  cleanup       - Remove GKE resources (cluster, services)"
    echo "  help          - Show this help message"
    echo ""
    echo "Cluster Tiers:"
    echo "  ${BLUE}Standard:${NC}"
    echo "    dev       - e2-standard-2 nodes (2 vCPUs, 8GB RAM each)"
    echo "    standard  - e2-standard-4 nodes (4 vCPUs, 16GB RAM each)"
    echo "    high      - e2-standard-8 nodes (8 vCPUs, 32GB RAM each)"
    echo ""
    echo "Examples:"
    echo "  $0 setup                 # Setup with standard cluster"
    echo "  $0 setup dev             # Setup with development cluster" 
    echo "  $0 deploy                # Deploy COSMOS to existing cluster"
    echo "  $0 all standard          # Full deployment with standard cluster"
    echo ""
    exit 0
}

# Load environment variables
load_env() {
    if [ -f .env ]; then
        echo "Loading configuration from .env..."
        export $(cat .env | grep -v '^#' | xargs)
    else
        echo "Using .env.example as template..."
        cp .env.example .env
        export $(cat .env | grep -v '^#' | xargs)
    fi
    
    # Use environment variables or defaults
    PROJECT_ID="${GCP_PROJECT_ID:-cosmos-project-$(date +%s)}"
    REGION="${GCP_REGION:-us-central1}"
    ZONE="${GCP_ZONE:-us-central1-a}"
    CLUSTER_NAME="${GCP_CLUSTER_NAME:-cosmos-cluster}"
    
    echo -e "${BLUE}Configuration:${NC}"
    echo "  Project ID: ${PROJECT_ID}"
    echo "  Region: ${REGION}"
    echo "  Zone: ${ZONE}"
    echo "  Cluster: ${CLUSTER_NAME}"
    echo ""
}

# Setup function - configure GCP and create cluster
do_setup() {
    CLUSTER_TIER="${1:-standard}"
    
    echo -e "${GREEN}Setting up GKE environment...${NC}"
    echo "============================="
    
    # Configure gcloud
    echo "Configuring gcloud..."
    gcloud config set project ${PROJECT_ID}
    gcloud config set compute/region ${REGION}
    gcloud config set compute/zone ${ZONE}
    echo -e "${GREEN}✓ GCP configuration set${NC}"
    
    # Enable required APIs
    echo ""
    echo "Enabling required APIs..."
    gcloud services enable \
        container.googleapis.com \
        compute.googleapis.com \
        storage.googleapis.com \
        logging.googleapis.com \
        monitoring.googleapis.com
    echo -e "${GREEN}✓ APIs enabled${NC}"
    
    # Create GKE cluster based on tier
    echo ""
    echo "Creating GKE cluster (${CLUSTER_TIER})..."
    
    case "$CLUSTER_TIER" in
        dev)
            MACHINE_TYPE="e2-standard-2"
            NUM_NODES="2"
            DISK_SIZE="20"
            ;;
        high)
            MACHINE_TYPE="e2-standard-8"
            NUM_NODES="3"
            DISK_SIZE="50"
            ;;
        standard|*)
            MACHINE_TYPE="e2-standard-4"
            NUM_NODES="3"
            DISK_SIZE="30"
            ;;
    esac
    
    if ! gcloud container clusters describe ${CLUSTER_NAME} --zone=${ZONE} &>/dev/null; then
        gcloud container clusters create ${CLUSTER_NAME} \
            --zone=${ZONE} \
            --machine-type=${MACHINE_TYPE} \
            --num-nodes=${NUM_NODES} \
            --disk-size=${DISK_SIZE} \
            --enable-autorepair \
            --enable-autoupgrade \
            --enable-autoscaling \
            --min-nodes=1 \
            --max-nodes=5 \
            --enable-ip-alias \
            --release-channel=regular
        echo -e "${GREEN}✓ Created GKE cluster: ${CLUSTER_NAME}${NC}"
    else
        echo -e "${GREEN}✓ GKE cluster already exists: ${CLUSTER_NAME}${NC}"
    fi
    
    # Get cluster credentials
    gcloud container clusters get-credentials ${CLUSTER_NAME} --zone=${ZONE}
    echo -e "${GREEN}✓ Cluster credentials configured${NC}"
    
    echo ""
    echo -e "${GREEN}✅ Setup complete!${NC}"
    echo ""
    echo "Cluster details:"
    kubectl cluster-info
}

# Deploy function - deploy COSMOS to GKE
do_deploy() {
    echo -e "${GREEN}Deploying COSMOS to GKE...${NC}"
    echo "=========================="
    
    # Ensure we have cluster access
    gcloud container clusters get-credentials ${CLUSTER_NAME} --zone=${ZONE}
    
    # Create namespace
    kubectl create namespace cosmos --dry-run=client -o yaml | kubectl apply -f -
    
    # Create ConfigMap from .env
    echo "Creating configuration..."
    kubectl create configmap cosmos-config --from-env-file=.env -n cosmos --dry-run=client -o yaml | kubectl apply -f -
    
    # Apply Kubernetes manifests
    echo "Applying Kubernetes manifests..."
    if [ -d "k8s" ]; then
        kubectl apply -f k8s/ -n cosmos
    else
        echo -e "${YELLOW}⚠ k8s/ directory not found, creating manifests...${NC}"
        create_k8s_manifests
        kubectl apply -f k8s/ -n cosmos
    fi
    
    echo ""
    echo "Waiting for services to be ready..."
    kubectl wait --for=condition=ready pod -l app=cosmos-redis -n cosmos --timeout=300s
    kubectl wait --for=condition=ready pod -l app=cosmos-minio -n cosmos --timeout=300s
    
    echo ""
    echo -e "${GREEN}✅ COSMOS deployed successfully!${NC}"
    
    # Show service status
    do_status
}

# Status function - check cluster and service status  
do_status() {
    echo -e "${GREEN}Checking COSMOS status...${NC}"
    echo "========================"
    
    echo "Cluster info:"
    kubectl cluster-info --context=$(kubectl config current-context) 2>/dev/null || echo "No cluster access"
    
    echo ""
    echo "COSMOS pods:"
    kubectl get pods -n cosmos -o wide
    
    echo ""
    echo "COSMOS services:"
    kubectl get services -n cosmos
    
    echo ""
    echo "Persistent volumes:"
    kubectl get pv,pvc -n cosmos
    
    # Check for external LoadBalancer
    EXTERNAL_IP=$(kubectl get service cosmos-traefik -n cosmos -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
    if [ ! -z "$EXTERNAL_IP" ]; then
        echo ""
        echo -e "${GREEN}🌐 COSMOS Web Interface:${NC}"
        echo "  http://${EXTERNAL_IP}:2900"
        echo "  https://${EXTERNAL_IP}:2943"
    else
        echo ""
        echo -e "${YELLOW}💡 To access COSMOS externally, run: $0 expose${NC}"
    fi
}

# Logs function - view service logs
do_logs() {
    SERVICE="${1:-cosmos-traefik}"
    
    echo -e "${GREEN}Viewing logs for ${SERVICE}...${NC}"
    echo "=============================="
    
    kubectl logs -f -l app=${SERVICE} -n cosmos --tail=50
}

# Expose function - create external LoadBalancer
do_expose() {
    echo -e "${GREEN}Exposing COSMOS to internet...${NC}"
    echo "============================="
    
    # Patch traefik service to use LoadBalancer
    kubectl patch service cosmos-traefik -n cosmos -p '{"spec":{"type":"LoadBalancer"}}'
    
    echo "Waiting for external IP..."
    kubectl get service cosmos-traefik -n cosmos -w
}

# Update function - update deployment
do_update() {
    echo -e "${GREEN}Updating COSMOS deployment...${NC}"
    echo "============================="
    
    # Update ConfigMap
    kubectl create configmap cosmos-config --from-env-file=.env -n cosmos --dry-run=client -o yaml | kubectl apply -f -
    
    # Restart deployments to pick up new config
    kubectl rollout restart deployment -n cosmos
    
    echo -e "${GREEN}✓ COSMOS updated${NC}"
}

# Cleanup function - remove GKE resources
do_cleanup() {
    echo -e "${YELLOW}⚠️  Cleanup GKE Resources${NC}"
    echo "========================"
    
    echo "This will remove:"
    echo "  - GKE cluster: ${CLUSTER_NAME}"
    echo "  - All COSMOS services and data"
    echo ""
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Removing COSMOS namespace..."
        kubectl delete namespace cosmos --ignore-not-found=true
        
        echo "Removing GKE cluster..."
        gcloud container clusters delete ${CLUSTER_NAME} --zone=${ZONE} --quiet
        
        echo -e "${GREEN}✅ Cleanup complete${NC}"
    else
        echo "Cleanup cancelled"
    fi
}

# Helper function to create Kubernetes manifests
create_k8s_manifests() {
    echo "Kubernetes manifests already exist in k8s/ directory"
    echo -e "${GREEN}✓ Using existing manifests${NC}"
}

# Main script logic
case "$MODE" in
    setup)
        load_env
        do_setup "$2"
        ;;
    deploy)
        load_env
        do_deploy
        ;;
    all)
        load_env
        do_setup "$2"
        do_deploy
        ;;
    status)
        load_env
        do_status
        ;;
    logs)
        load_env
        do_logs "$2"
        ;;
    expose)
        load_env
        do_expose
        ;;
    update)
        load_env
        do_update
        ;;
    cleanup)
        load_env
        do_cleanup
        ;;
    help|*)
        show_help
        ;;
esac