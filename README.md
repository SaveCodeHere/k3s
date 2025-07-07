# 🏗️ Nicstack-K3: Cloud-Native Infrastructure

A production-ready hybrid infrastructure: **Docker Compose foundation** with **Kubernetes applications**.

## 📁 Project Structure

```
nicstack-k3/
├── infrastructure/           # Infrastructure components
│   ├── docker-compose/      # Foundation services (Traefik, Vault, Pi-hole, Portainer)
│   │   ├── configs/         # Service configurations
│   │   ├── docker-compose.yml
│   │   └── utils/
│   ├── kubernetes/          # Pure Kubernetes manifests
│   └── k3s/                 # K3s-specific configurations
│
├── manifests/               # Kubernetes resource definitions
│   ├── core/               # Core K8s infrastructure (Ingress, cert-manager, etc.)
│   ├── apps/               # K8s application deployments
│   │   └── rancher/        # K3s management (runs in K8s)
│   └── monitoring/         # K8s observability stack (Prometheus, Grafana, etc.)
│
├── environments/           # Environment-specific configs
│   ├── development/        # Dev environment overrides
│   ├── staging/           # Staging environment
│   └── production/        # Production configuration
│
├── helm-charts/           # Custom Helm charts
├── scripts/              # Automation and utility scripts
└── docs/                 # Documentation
    ├── CONFIGURATION-SAVED.md
    └── QUICK-REFERENCE.md
```

## 🚀 Quick Start

### Docker Compose Foundation (Required First)
```bash
# Start foundation services (Traefik, Vault, Pi-hole, Portainer)
cd infrastructure/docker-compose
docker compose up -d

# Apply Tailscale configuration
cd configs/tailscale
./apply-tailscale-serve.sh
```

### Kubernetes Applications (Optional)
```bash
# Deploy core K8s infrastructure
kubectl apply -f manifests/core/

# Deploy K8s applications  
kubectl apply -f manifests/apps/

# Deploy K8s monitoring stack
kubectl apply -f manifests/monitoring/
```

## 🏭 Architecture

### Foundation Layer (Docker Compose) - **ALWAYS RUNNING**
- **Traefik**: Reverse proxy and SSL termination for everything
- **Vault**: Secrets management for both Docker and K8s
- **Pi-hole**: DNS filtering and ad blocking
- **Portainer**: Docker and Kubernetes management UI
- **Landing Page**: Service directory
- **Tailscale**: Secure remote access

### Kubernetes Layer (K3s) - **OPTIONAL APPLICATIONS**
- **Rancher**: Advanced K3s management (runs as K8s deployment)
- **Applications**: Additional apps deployed via manifests or Helm
- **Monitoring**: K8s-native observability stack

### Access Methods
- **Local**: Direct container ports
- **Tailscale HTTPS**: Secure remote access via `um.tail16ca22.ts.net`
- **Traefik Routing**: Handles both Docker and K8s ingress
- **K3s NodePorts**: Direct Kubernetes service access

## 📖 Documentation

### 🚀 Getting Started
- [**Complete Configuration Guide**](docs/CONFIGURATION-SAVED.md) - Initial setup and configuration
- [**Daily Operations**](docs/QUICK-REFERENCE.md) - Common tasks and maintenance

### 🛠️ Development & Deployment
- [**K3s App Deployment Guide**](docs/K3S-APP-DEPLOYMENT-GUIDE.md) - Step-by-step K3s application deployment
- [**Traefik Architecture Guide**](docs/TRAEFIK-ARCHITECTURE-GUIDE.md) - Complete Traefik setup explanation
- [**Quick Service Reference**](docs/QUICK-SERVICE-REFERENCE.md) - Templates for adding new services
- [**Service Addition Guide**](infrastructure/docker-compose/configs/tailscale/service-addition-guide.md) - Docker Compose services

### 🏗️ Architecture
- [**Architecture Clarified**](docs/ARCHITECTURE-CLARIFIED.md) - System overview and design decisions

## 🔧 Key Features

✅ **Hybrid Architecture**: Docker Compose + Kubernetes  
✅ **Secure Remote Access**: Tailscale with HTTPS termination  
✅ **Multiple Routing**: Subdomain, path-based, and direct access  
✅ **Production Ready**: SSL certificates, monitoring, backups  
✅ **Easy Maintenance**: Automated scripts and comprehensive docs  
✅ **Best Practices**: Following cloud-native patterns  

## 🌐 Service URLs

| Service | Primary Access | Alternative |
|---------|----------------|-------------|
| **Main Dashboard** | `https://um.tail16ca22.ts.net/` | `http://localhost:8081/` |
| **Portainer** | `https://um.tail16ca22.ts.net:9443/` | `http://localhost:9000/` |
| **Vault** | `https://um.tail16ca22.ts.net:8243/` | `http://localhost:8200/` |
| **Pi-hole** | `https://um.tail16ca22.ts.net:8543/` | `http://localhost:8053/` |
| **Rancher** | `https://um.tail16ca22.ts.net:30443/dashboard/auth/login` | `https://localhost:30443/` |
| **Hello World** | `https://um.tail16ca22.ts.net:8888/hello` | `https://localhost:8888/hello` |
| **Traefik** | `https://um.tail16ca22.ts.net:8443/` | `http://localhost:8080/` |

---

*For detailed setup and operation instructions, see the [docs](docs/) directory.*