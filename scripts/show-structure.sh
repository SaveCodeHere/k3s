#!/bin/bash
# Project Structure Overview

echo "🏗️ Nicstack-K3 Project Structure"
echo "================================"
echo ""

cd /home/nic/projects/nicstack-k3

echo "📁 Root Directory:"
ls -la | grep -E '^d' | awk '{print "  " $9}' | grep -v '^\.$\|^\.\.$'
echo ""

echo "🏗️ Infrastructure Components:"
echo "  infrastructure/"
echo "    ├── docker-compose/     # Foundation services (Traefik, Vault, Pi-hole, Portainer)"
echo "    ├── kubernetes/         # Pure K8s manifests"
echo "    └── k3s/               # K3s-specific configs"
echo ""

echo "📦 Kubernetes Manifests (Optional):"
echo "  manifests/"
echo "    ├── core/              # K8s infrastructure ($(ls manifests/core/ 2>/dev/null | wc -l) files)"
echo "    ├── apps/              # K8s applications"
for app in manifests/apps/*/; do
    if [ -d "$app" ]; then
        echo "    │   ├── $(basename "$app")/ (K8s deployment)"
    fi
done
echo "    └── monitoring/        # K8s observability stack"
echo ""

echo "🔧 Active Services:"
cd infrastructure/docker-compose
if docker compose ps &>/dev/null; then
    docker compose ps --format "table {{.Service}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null | head -6
else
    echo "  Docker Compose not running"
fi
echo ""

echo "🌐 Quick Access:"
echo "  Main: https://um.tail16ca22.ts.net/"
echo "  Docs: ./docs/"
echo "  Configs: ./infrastructure/docker-compose/configs/"
