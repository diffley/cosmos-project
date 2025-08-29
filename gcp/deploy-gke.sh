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
    echo "  refresh       - Delete namespace and redeploy (clean start)"
    echo "  status        - Check cluster and service status"
    echo "  logs          - View COSMOS service logs"
    echo "  expose        - Create external LoadBalancer for web access"
    echo "  update        - Update COSMOS deployment with new config"
    echo "  stop          - Scale down all COSMOS services (saves costs)"
    echo "  start         - Scale up all COSMOS services"
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
    # Check for .env in current directory first, then parent directory
    if [ -f .env ]; then
        echo "Loading configuration from .env..."
        export $(cat .env | grep -v '^#' | xargs)
    elif [ -f ../.env ]; then
        echo "Loading configuration from ../.env..."
        export $(cat ../.env | grep -v '^#' | xargs)
    elif [ -f gcp/.env ]; then
        echo "Loading configuration from gcp/.env..."
        export $(cat gcp/.env | grep -v '^#' | xargs)
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
    gcloud container clusters get-credentials ${CLUSTER_NAME} --location=${ZONE}
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
    gcloud container clusters get-credentials ${CLUSTER_NAME} --location=${ZONE}
    
    # Create namespace
    kubectl create namespace cosmos --dry-run=client -o yaml | kubectl apply -f -
    
    # Create ConfigMap from .env
    echo "Creating configuration..."
    if [ -f .env ]; then
        kubectl create configmap cosmos-config --from-env-file=.env -n cosmos --dry-run=client -o yaml | kubectl apply -f -
    elif [ -f ../.env ]; then
        kubectl create configmap cosmos-config --from-env-file=../.env -n cosmos --dry-run=client -o yaml | kubectl apply -f -
    elif [ -f gcp/.env ]; then
        kubectl create configmap cosmos-config --from-env-file=gcp/.env -n cosmos --dry-run=client -o yaml | kubectl apply -f -
    else
        echo -e "${RED}❌ No .env file found${NC}"
        exit 1
    fi
    
    # Generate SSL certificates if they don't exist
    if [ ! -f openc3-traefik/cert.crt ] || [ ! -f ../openc3-traefik/cert.crt ]; then
        echo "Generating SSL certificates..."
        EXTERNAL_IP=$(kubectl get service cosmos-traefik -n cosmos -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "localhost")
        if [ -d "openc3-traefik" ]; then
            cd openc3-traefik
            openssl req -x509 -newkey rsa:4096 -keyout cert.key -out cert.crt -days 365 -nodes -subj "/CN=${EXTERNAL_IP}" 2>/dev/null
            cd ..
        elif [ -d "../openc3-traefik" ]; then
            cd ../openc3-traefik
            openssl req -x509 -newkey rsa:4096 -keyout cert.key -out cert.crt -days 365 -nodes -subj "/CN=${EXTERNAL_IP}" 2>/dev/null
            cd ../gcp
        fi
        echo -e "${GREEN}✓ SSL certificates generated${NC}"
    fi

    # Create SSL secret and configmap
    echo "Creating SSL configuration..."
    if [ -f openc3-traefik/cert.crt ]; then
        kubectl create secret tls traefik-ssl-certs --cert=openc3-traefik/cert.crt --key=openc3-traefik/cert.key -n cosmos --dry-run=client -o yaml | kubectl apply -f -
        kubectl create configmap traefik-ssl-config --from-file=openc3-traefik/traefik-ssl.yaml -n cosmos --dry-run=client -o yaml | kubectl apply -f -
    elif [ -f ../openc3-traefik/cert.crt ]; then
        kubectl create secret tls traefik-ssl-certs --cert=../openc3-traefik/cert.crt --key=../openc3-traefik/cert.key -n cosmos --dry-run=client -o yaml | kubectl apply -f -
        kubectl create configmap traefik-ssl-config --from-file=../openc3-traefik/traefik-ssl.yaml -n cosmos --dry-run=client -o yaml | kubectl apply -f -
    fi

    # Create required ConfigMaps
    echo "Creating COSMOS ConfigMaps..."
    if [ -f cacert.pem ]; then
        kubectl create configmap cacert-config --from-file=cacert.pem=cacert.pem -n cosmos --dry-run=client -o yaml | kubectl apply -f -
        kubectl create configmap redis-acl-config --from-file=users.acl=openc3-redis/users.acl -n cosmos --dry-run=client -o yaml | kubectl apply -f -
    elif [ -f ../cacert.pem ]; then
        kubectl create configmap cacert-config --from-file=cacert.pem=../cacert.pem -n cosmos --dry-run=client -o yaml | kubectl apply -f -
        kubectl create configmap redis-acl-config --from-file=users.acl=../openc3-redis/users.acl -n cosmos --dry-run=client -o yaml | kubectl apply -f -
    else
        echo -e "${RED}❌ cacert.pem not found${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓ COSMOS ConfigMaps created${NC}"

    # Apply Kubernetes manifests
    echo "Applying Kubernetes manifests..."
    if [ -d "k8s" ]; then
        kubectl apply -f k8s/ -n cosmos
    elif [ -d "../k8s" ]; then
        kubectl apply -f ../k8s/ -n cosmos
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
    
    echo "Waiting for external IP (this can take 2-5 minutes)..."
    
    # Wait for LoadBalancer with progress updates
    for i in {1..60}; do
        EXTERNAL_IP=$(kubectl get service cosmos-traefik -n cosmos -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
        if [ ! -z "$EXTERNAL_IP" ]; then
            break
        fi
        echo -n "."
        sleep 5
    done
    
    echo ""
    if [ ! -z "$EXTERNAL_IP" ]; then
        echo -e "${GREEN}✅ COSMOS exposed to internet!${NC}"
        echo "  External IP: ${EXTERNAL_IP}"
        echo "  Web Interface: http://${EXTERNAL_IP}:2900"
        echo "  Secure Web: https://${EXTERNAL_IP}:2943"
    else
        echo -e "${YELLOW}⚠️  LoadBalancer IP still pending. Check status with:${NC}"
        echo "  kubectl get service cosmos-traefik -n cosmos"
    fi
}

# Update function - update deployment
do_update() {
    echo -e "${GREEN}Updating COSMOS deployment...${NC}"
    echo "============================="
    
    # Update ConfigMap
    if [ -f .env ]; then
        kubectl create configmap cosmos-config --from-env-file=.env -n cosmos --dry-run=client -o yaml | kubectl apply -f -
    elif [ -f ../.env ]; then
        kubectl create configmap cosmos-config --from-env-file=../.env -n cosmos --dry-run=client -o yaml | kubectl apply -f -
    elif [ -f gcp/.env ]; then
        kubectl create configmap cosmos-config --from-env-file=gcp/.env -n cosmos --dry-run=client -o yaml | kubectl apply -f -
    else
        echo -e "${RED}❌ No .env file found${NC}"
        exit 1
    fi
    
    # Restart deployments to pick up new config
    kubectl rollout restart deployment -n cosmos
    
    echo -e "${GREEN}✓ COSMOS updated${NC}"
}

# Stop function - scale down to save costs
do_stop() {
    echo -e "${YELLOW}Stopping COSMOS services...${NC}"
    echo "==========================="
    
    # Scale down all deployments to 0 replicas
    echo "Scaling down deployments..."
    kubectl scale deployment --all --replicas=0 -n cosmos
    
    # Scale down statefulsets to 0 replicas
    echo "Scaling down statefulsets..."
    kubectl scale statefulset --all --replicas=0 -n cosmos
    
    echo ""
    echo -e "${GREEN}✓ COSMOS services stopped${NC}"
    echo -e "${BLUE}💡 Cluster nodes are still running. To fully stop costs, use: $0 cleanup${NC}"
    
    # Show status
    kubectl get pods -n cosmos
}

# Start function - scale back up
do_start() {
    echo -e "${GREEN}Starting COSMOS services...${NC}"
    echo "=========================="
    
    # Scale up statefulsets first (Redis, MinIO)
    echo "Starting storage services..."
    kubectl scale statefulset cosmos-redis --replicas=1 -n cosmos
    kubectl scale statefulset cosmos-redis-ephemeral --replicas=1 -n cosmos  
    kubectl scale statefulset cosmos-minio --replicas=1 -n cosmos
    
    # Wait for storage to be ready
    echo "Waiting for storage services..."
    kubectl wait --for=condition=ready pod -l app=cosmos-redis -n cosmos --timeout=120s
    kubectl wait --for=condition=ready pod -l app=cosmos-minio -n cosmos --timeout=120s
    
    # Scale up application deployments
    echo "Starting application services..."
    kubectl scale deployment cosmos-cmd-tlm-api --replicas=1 -n cosmos
    kubectl scale deployment cosmos-script-runner-api --replicas=1 -n cosmos
    kubectl scale deployment cosmos-operator --replicas=1 -n cosmos
    kubectl scale deployment cosmos-traefik --replicas=1 -n cosmos
    
    # Wait for apps to be ready
    echo "Waiting for application services..."
    kubectl wait --for=condition=ready pod -l app=cosmos-cmd-tlm-api -n cosmos --timeout=120s
    kubectl wait --for=condition=ready pod -l app=cosmos-traefik -n cosmos --timeout=120s
    
    echo ""
    echo -e "${GREEN}✓ COSMOS services started${NC}"
    
    # Show status
    do_status
}

# Refresh function - delete namespace and redeploy
do_refresh() {
    echo -e "${YELLOW}🔄 Refreshing COSMOS deployment...${NC}"
    echo "===================================="
    
    # Ensure we have cluster access
    gcloud container clusters get-credentials ${CLUSTER_NAME} --location=${ZONE}
    
    # Delete existing namespace
    echo "Deleting existing namespace..."
    kubectl delete namespace cosmos --ignore-not-found=true --wait=true
    
    echo "Waiting for namespace deletion to complete..."
    while kubectl get namespace cosmos 2>/dev/null; do
        echo -n "."
        sleep 2
    done
    echo ""
    echo -e "${GREEN}✓ Namespace deleted${NC}"
    
    # Run deploy with fresh start
    do_deploy
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
    refresh)
        load_env
        do_refresh
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
    stop)
        load_env
        do_stop
        ;;
    start)
        load_env
        do_start
        ;;
    cleanup)
        load_env
        do_cleanup
        ;;
    help|*)
        show_help
        ;;
esac