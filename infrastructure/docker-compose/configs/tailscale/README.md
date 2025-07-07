# Tailscale Service Configuration Guide

## Quick Apply Current Configuration

To apply the current working configuration:

```bash
cd /home/nic/projects/nicstack-k3/bootstrap/configs/tailscale
./apply-tailscale-serve.sh
```

## Current Service URLs

### Main Access (via Traefik)
- **HTTPS**: `https://um.tail16ca22.ts.net/` → Traefik dashboard + all routing
- **HTTP**: `http://um.tail16ca22.ts.net/` → Redirects to HTTPS

### Direct Service Access (HTTPS with TLS termination)
- **Portainer**: `https://um.tail16ca22.ts.net:9443/`
- **Vault**: `https://um.tail16ca22.ts.net:8243/`
- **Pi-hole**: `https://um.tail16ca22.ts.net:8543/`
- **Rancher**: `https://um.tail16ca22.ts.net:30443/dashboard/auth/login` (direct K3s)

### Fallback HTTP Access (direct IP)
- **Portainer**: `http://100.84.168.38:9000/`
- **Vault**: `http://100.84.168.38:8200/`
- **Pi-hole**: `http://100.84.168.38:8053/`

## Adding New Services to Tailscale

### Method 1: Direct Port Access (Recommended)

When you add a new service to docker-compose.yml, follow these steps:

1. **Expose the service port in docker-compose.yml**:
   ```yaml
   new-service:
     image: some/image
     ports:
       - "8999:80"  # Expose on host port 8999
   ```

2. **Add Tailscale serve configuration**:
   ```bash
   # For HTTPS access (most common)
   tailscale serve --bg --https=8999 http://localhost:8999
   
   # For direct TCP forwarding (if needed)
   tailscale serve --bg --tcp=8999 localhost:8999
   ```

3. **Update the apply script** by adding your service to `/configs/tailscale/apply-tailscale-serve.sh`:
   ```bash
   # New Service - HTTPS termination for HTTP backend
   tailscale serve --bg --https=8999 http://localhost:8999
   ```

### Method 2: Via Traefik (Subdomain + Path routing)

If you want full Traefik integration with subdomains and path routing:

1. **Add Traefik labels to your service**:
   ```yaml
   new-service:
     # ... service config ...
     labels:
       - "traefik.enable=true"
       
       # Subdomain access
       - "traefik.http.routers.newservice-private.rule=Host(`newservice.um.tail16ca22.ts.net`)"
       - "traefik.http.routers.newservice-private.entrypoints=websecure"
       - "traefik.http.routers.newservice-private.service=newservice-svc"
       - "traefik.http.routers.newservice-private.middlewares=default-chain@file"
       
       # Path-based access (optional)
       - "traefik.http.routers.newservice-path.rule=Host(`um.tail16ca22.ts.net`) && PathPrefix(`/newservice`)"
       - "traefik.http.routers.newservice-path.entrypoints=websecure"
       - "traefik.http.routers.newservice-path.service=newservice-svc"
       - "traefik.http.routers.newservice-path.middlewares=default-chain@file,newservice-stripprefix,newservice-headers"
       
       # Service definition
       - "traefik.http.services.newservice-svc.loadbalancer.server.port=80"
       
       # Middleware for path-based routing
       - "traefik.http.middlewares.newservice-stripprefix.stripprefix.prefixes=/newservice"
       - "traefik.http.middlewares.newservice-headers.headers.customrequestheaders.X-Forwarded-Prefix=/newservice"
   ```

2. **The service will be automatically available via**:
   - Subdomain: `https://newservice.um.tail16ca22.ts.net/`
   - Path: `https://um.tail16ca22.ts.net/newservice` (may have asset issues)

### Method 3: Custom Port with Nice Number

For important services, pick memorable port numbers:

```bash
# Examples of good port choices
tailscale serve --bg --https=9001 http://localhost:9001  # Grafana
tailscale serve --bg --https=9002 http://localhost:9002  # Prometheus  
tailscale serve --bg --https=9003 http://localhost:9003  # Nextcloud
```

## Port Number Guidelines

### Reserved Ports (Don't Use)
- `443`, `80` - Main domain
- `9443` - Portainer
- `8243` - Vault
- `8543` - Pi-hole
- `30080`, `30443` - Rancher (K3s NodePort)

### Available Port Ranges
- `9001-9099` - Management services
- `8501-8599` - Web applications
- `7001-7099` - Databases/backends
- `6001-6099` - Monitoring/logging

## Common Service Examples

### Grafana
```bash
# In docker-compose.yml
grafana:
  image: grafana/grafana
  ports:
    - "9001:3000"

# Add to Tailscale
tailscale serve --bg --https=9001 http://localhost:9001
```

### Nextcloud
```bash
# In docker-compose.yml  
nextcloud:
  image: nextcloud
  ports:
    - "8501:80"

# Add to Tailscale
tailscale serve --bg --https=8501 http://localhost:8501
```

### Jupyter Lab
```bash
# In docker-compose.yml
jupyter:
  image: jupyter/lab
  ports:
    - "8502:8888"

# Add to Tailscale  
tailscale serve --bg --https=8502 http://localhost:8502
```

## Troubleshooting

### Check current configuration
```bash
tailscale serve status
```

### Remove a specific service
```bash
tailscale serve --https=9001 off
```

### Reset everything
```bash
tailscale serve reset
```

### Test local access first
```bash
curl -I http://localhost:9001/
```

### Test Tailscale access
```bash
curl -k -I https://um.tail16ca22.ts.net:9001/
```

## Benefits of Each Method

### Direct Port Access (Method 1)
✅ No redirect loops or asset issues  
✅ Simple configuration  
✅ Works with any web application  
✅ Easy troubleshooting  

### Traefik Integration (Method 2)  
✅ Nice subdomain URLs  
✅ Centralized SSL management  
✅ Path-based routing option  
❌ Can have asset loading issues with path routing  

### Recommendation
Use **Method 1 (Direct Port Access)** for most services - it's reliable and simple!
