#!/bin/sh
set -e

# Copy serve.json to the correct location
if [ -f /config/serve.json ]; then
  echo "Copying serve.json to /var/lib/tailscale/"
  mkdir -p /var/lib/tailscale
  cp /config/serve.json /var/lib/tailscale/serve.json
  chmod 600 /var/lib/tailscale/serve.json
  echo "serve.json copied successfully"
fi

# Log some diagnostic information
echo "Tailscale container networking:"
ip addr show
echo "Container DNS configuration:"
cat /etc/resolv.conf
echo "Testing connectivity to services:"
ping -c 1 traefik || echo "Cannot ping traefik"
ping -c 1 vault || echo "Cannot ping vault"
ping -c 1 portainer || echo "Cannot ping portainer"
ping -c 1 pihole || echo "Cannot ping pihole"

# Add DNS entries to /etc/hosts for the services
echo "Adding service DNS entries to /etc/hosts"
echo "172.18.0.7 traefik traefik.um.tail16ca22.ts.net" >> /etc/hosts
echo "172.18.0.5 vault vault.um.tail16ca22.ts.net" >> /etc/hosts
echo "172.18.0.7 portainer portainer.um.tail16ca22.ts.net" >> /etc/hosts
echo "172.18.0.6 pihole pihole.um.tail16ca22.ts.net" >> /etc/hosts
echo "127.0.0.1 um.tail16ca22.ts.net" >> /etc/hosts
cat /etc/hosts

# Start Tailscale service
echo "Starting Tailscale..."
/usr/local/bin/containerboot --state=/var/lib/tailscale/tailscaled.state "$@"

# Apply serve.json configuration
if [ -f /var/lib/tailscale/serve.json ]; then
  echo "Applying serve.json configuration..."
  tailscale serve reset
  tailscale serve apply --config=/var/lib/tailscale/serve.json
  echo "Tailscale serve configuration applied"
fi

# Keep the container running
exec tail -f /dev/null
