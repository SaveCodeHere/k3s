#!/bin/bash
# Tailscale Serve Configuration Script
# This script applies the complete Tailscale serve configuration for nicstack services

set -e

echo "🚀 Applying Tailscale Serve Configuration..."

# Reset any existing configuration
echo "📝 Resetting existing serve configuration..."
tailscale serve reset

# Main domain access (via Traefik with all routing)
echo "🌐 Setting up main domain access..."
tailscale serve --bg --https=443 https://localhost:8443
tailscale serve --bg --http=80 http://localhost:8081

# Direct service access (bypassing path routing issues)
echo "🔧 Setting up direct service access..."

# Portainer - HTTPS termination for HTTP backend
tailscale serve --bg --https=9443 http://localhost:9000

# Vault - HTTPS termination for HTTP backend  
tailscale serve --bg --https=8243 http://localhost:8200

# Pi-hole - HTTPS termination for HTTP backend
tailscale serve --bg --https=8543 http://localhost:8053

# Rancher - HTTPS passthrough for HTTPS backend (K3s NodePort)
tailscale serve --bg --https=30443 https://localhost:30443

# K3s Hello World Example App - HTTPS termination for HTTP backend (K3s Traefik)
tailscale serve --bg --https=8888 --set-path=/hello https://localhost:8888/hello

# Landing Page - HTTPS termination for HTTP backend (optional)
# tailscale serve --bg --https=8843 http://localhost:8082

echo "✅ Tailscale Serve Configuration Applied!"
echo ""
echo "📊 Current Configuration:"
tailscale serve status
echo ""
echo "🔗 Access URLs:"
echo "  Main (Traefik): https://um.tail16ca22.ts.net/"
echo "  Portainer:      https://um.tail16ca22.ts.net:9443/"
echo "  Vault:          https://um.tail16ca22.ts.net:8243/"
echo "  Pi-hole:        https://um.tail16ca22.ts.net:8543/"
echo "  Rancher:        https://um.tail16ca22.ts.net:30443/dashboard/auth/login"
echo "  Hello World:    https://um.tail16ca22.ts.net:8888/hello"
echo ""
echo "📝 Fallback HTTP URLs (direct IP):"
echo "  Portainer:      http://100.84.168.38:9000/"
echo "  Vault:          http://100.84.168.38:8200/"
echo "  Pi-hole:        http://100.84.168.38:8053/"
echo "  Hello World:    http://100.84.168.38:8888/hello"
echo ""
