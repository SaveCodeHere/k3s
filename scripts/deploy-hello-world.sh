#!/bin/bash
# Deploy Hello World K3s Example Application
# This script deploys the hello-world example app to demonstrate K3s + Traefik + Tailscale integration

set -e

echo "🚀 Deploying Hello World K3s Example Application..."

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not available. Please install kubectl and configure K3s access."
    exit 1
fi

# Check if K3s is running
if ! kubectl get nodes &> /dev/null; then
    echo "❌ Unable to connect to K3s cluster. Please ensure K3s is running and configured."
    exit 1
fi

echo "✅ K3s cluster is accessible"

# Deploy the application
echo "📦 Deploying hello-world application..."
kubectl apply -f /home/nic/projects/nicstack-k3/manifests/apps/hello-world/

# Wait for deployment to be ready
echo "⏳ Waiting for deployment to be ready..."
kubectl wait --for=condition=available --timeout=60s deployment/hello-world

# Check the status
echo "📊 Deployment Status:"
kubectl get pods -l app=hello-world
kubectl get service hello-world-service
kubectl get ingress hello-world-ingress

echo ""
echo "🌐 Access Methods:"
echo "  Local (Path):   https://192.168.1.49:8888/hello"
echo "  Local (Host):   https://hello.nicstack.dev:8888/"
echo "  Tailscale:      https://um.tail16ca22.ts.net:8888/hello"
echo "  Public Domain:  https://hello.nicstack.dev (requires DNS + cert setup)"

echo ""
echo "🔧 Testing local access..."
if curl -k -s https://192.168.1.49:8888/hello | grep -q "Hello World"; then
    echo "✅ Local access working!"
else
    echo "⚠️  Local access test failed. Check K3s Traefik configuration."
fi

echo ""
echo "📝 Next Steps:"
echo "  1. Configure DNS: hello.nicstack.dev -> your-public-ip:8888"
echo "  2. Update Tailscale serve config: ./apply-tailscale-serve.sh"
echo "  3. Test all access methods"
echo "  4. Set up SSL certificates for public domain access"

echo ""
echo "🎉 Hello World application deployed successfully!"
