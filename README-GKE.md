# COSMOS GKE Deployment Guide

Deploy COSMOS to Google Kubernetes Engine (GKE) with a single script.

## Prerequisites

1. **Google Cloud CLI installed**
   ```bash
   # Verify gcloud is installed
   gcloud version
   ```

2. **Authenticate with Google Cloud**
   ```bash
   gcloud auth login
   gcloud auth application-default login
   ```

3. **Set your GCP project ID**
   ```bash
   # Edit gcp/.env.gcp and set your project ID
   cp gcp/.env.gcp .env
   # Edit GCP_PROJECT_ID in .env
   ```

## Quick Start

```bash
# 1. Setup GKE cluster and deploy COSMOS (all in one)
./gcp/deploy-gke.sh all

# OR step by step:

# 2. Setup GCP project and create cluster
./gcp/deploy-gke.sh setup

# 3. Deploy COSMOS services
./gcp/deploy-gke.sh deploy

# 4. Expose to internet (creates LoadBalancer)
./gcp/deploy-gke.sh expose
```

## Cluster Tiers

- **dev**: `e2-standard-2` (2 vCPUs, 8GB) - 2 nodes
- **standard**: `e2-standard-4` (4 vCPUs, 16GB) - 3 nodes  
- **high**: `e2-standard-8` (8 vCPUs, 32GB) - 3 nodes

```bash
# Create development cluster
./gcp/deploy-gke.sh setup dev

# Create high-performance cluster  
./gcp/deploy-gke.sh setup high
```

## Management Commands

```bash
# Check status
./gcp/deploy-gke.sh status

# View logs
./gcp/deploy-gke.sh logs cosmos-traefik

# Update configuration
./gcp/deploy-gke.sh update

# Clean up everything
./gcp/deploy-gke.sh cleanup
```

## Services Deployed

- **Redis**: Persistent data storage
- **Redis Ephemeral**: Temporary data storage  
- **MinIO**: Object storage (S3-compatible)
- **Command & Telemetry API**: Core COSMOS API
- **Script Runner API**: Script execution engine
- **Operator**: Core COSMOS operations
- **Traefik**: Reverse proxy and load balancer
- **Init Job**: Initializes COSMOS environment

## Storage

- **Redis**: 10GB persistent volume
- **Redis Ephemeral**: 5GB persistent volume
- **MinIO**: 50GB persistent volume  
- **Gems**: 20GB shared volume for Ruby gems

## Costs (Approximate)

**Development cluster** (`e2-standard-2` × 2):
- ~$50-70/month

**Standard cluster** (`e2-standard-4` × 3):
- ~$150-200/month

**High-performance cluster** (`e2-standard-8` × 3):
- ~$300-400/month

*Costs include compute, storage, and LoadBalancer. Use `gcloud billing` for exact pricing.*

## Accessing COSMOS

After deployment with external access:

```bash
# Get external IP
kubectl get service cosmos-traefik -n cosmos

# Access web interface
# http://EXTERNAL_IP:2900
# https://EXTERNAL_IP:2943
```

## Troubleshooting

```bash
# Check pod status
kubectl get pods -n cosmos

# View specific service logs
kubectl logs -f deployment/cosmos-traefik -n cosmos

# Debug failing pods
kubectl describe pod POD_NAME -n cosmos

# Check persistent volumes
kubectl get pv,pvc -n cosmos
```

## Configuration

Edit `.env` file and run:
```bash
./gcp/deploy-gke.sh update
```

## Security Notes

- Change default passwords in `.env` for production
- Use GCP Secret Manager for sensitive data in production
- Configure proper firewall rules for production deployments
- Enable GKE private clusters for enhanced security