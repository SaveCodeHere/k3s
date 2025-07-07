# Complete Guide: Adding New Services to Tailscale Network

## Current Working Configuration (Saved State)

### Services Currently Running
- **Traefik**: Main reverse proxy and SSL termination
- **Portainer**: Container management (port 9443)
- **Vault**: Secrets management (port 8243)  
- **Pi-hole**: DNS filtering (port 8543)
- **Rancher**: K3s management (direct K3s NodePort 30443)
- **Landing Page**: Service directory (via Traefik)

### Access Methods Available
1. **Main Domain (Traefik)**: `https://um.tail16ca22.ts.net/` - All services with routing
2. **Direct HTTPS Ports**: Each service on unique port with TLS termination
3. **HTTP Fallback**: Direct IP access for debugging

### Tailscale Serve Configuration
```bash
# Main access
tailscale serve --bg --https=443 https://localhost:8443  # Traefik HTTPS
tailscale serve --bg --http=80 http://localhost:8081     # Traefik HTTP

# Direct service access  
tailscale serve --bg --https=9443 http://localhost:9000  # Portainer
tailscale serve --bg --https=8243 http://localhost:8200  # Vault
tailscale serve --bg --https=8543 http://localhost:8053  # Pi-hole
```

## Step-by-Step: Adding a New Service

### Example: Adding Grafana Monitoring

#### 1. Add to Docker Compose
Edit `/home/nic/projects/nicstack-k3/bootstrap/docker-compose.yml`:

```yaml
services:
  # ... existing services ...

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    restart: unless-stopped
    ports:
      - "9001:3000"  # Choose available port from guide below
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin123
    volumes:
      - grafana-data:/var/lib/grafana
    networks:
      - traefik-network
    labels:
      - "traefik.enable=true"
      
      # Subdomain access (recommended)
      - "traefik.http.routers.grafana-private.rule=Host(`grafana.um.tail16ca22.ts.net`)"
      - "traefik.http.routers.grafana-private.entrypoints=websecure"
      - "traefik.http.routers.grafana-private.service=grafana-svc"
      - "traefik.http.routers.grafana-private.middlewares=default-chain@file"
      
      # Path-based access (optional, may have asset issues)
      - "traefik.http.routers.grafana-path.rule=Host(`um.tail16ca22.ts.net`) && PathPrefix(`/grafana`)"
      - "traefik.http.routers.grafana-path.entrypoints=websecure"
      - "traefik.http.routers.grafana-path.service=grafana-svc"
      - "traefik.http.routers.grafana-path.middlewares=default-chain@file,grafana-stripprefix,grafana-headers"
      
      # Service definition
      - "traefik.http.services.grafana-svc.loadbalancer.server.port=3000"
      
      # Middleware for path routing
      - "traefik.http.middlewares.grafana-stripprefix.stripprefix.prefixes=/grafana"
      - "traefik.http.middlewares.grafana-headers.headers.customrequestheaders.X-Forwarded-Prefix=/grafana"

volumes:
  # ... existing volumes ...
  grafana-data:
```

#### 2. Start the Service
```bash
cd /home/nic/projects/nicstack-k3/bootstrap
docker compose up -d grafana
```

#### 3. Add Tailscale Direct Access
```bash
# Add HTTPS termination for the service
tailscale serve --bg --https=9001 http://localhost:9001
```

#### 4. Update the Apply Script
Edit `/home/nic/projects/nicstack-k3/bootstrap/configs/tailscale/apply-tailscale-serve.sh`:

```bash
# Add after existing services
# Grafana - HTTPS termination for HTTP backend
tailscale serve --bg --https=9001 http://localhost:9001
```

Also update the echo statements at the end:
```bash
echo "🔗 Access URLs:"
echo "  Main (Traefik): https://um.tail16ca22.ts.net/"
echo "  Portainer:      https://um.tail16ca22.ts.net:9443/"
echo "  Vault:          https://um.tail16ca22.ts.net:8243/"
echo "  Pi-hole:        https://um.tail16ca22.ts.net:8543/"
echo "  Grafana:        https://um.tail16ca22.ts.net:9001/"  # NEW
echo "  Rancher:        https://um.tail16ca22.ts.net:30443/dashboard/auth/login"
```

#### 5. Test Access
```bash
# Test local access first
curl -I http://localhost:9001/

# Test Tailscale access
curl -k -I https://um.tail16ca22.ts.net:9001/

# Test Traefik subdomain (if configured)
curl -k -I https://grafana.um.tail16ca22.ts.net/
```

#### 6. Update Landing Page (Optional)
Edit `/home/nic/projects/nicstack-k3/bootstrap/configs/landing-page/services.json`:

```json
{
  "services": [
    // ... existing services ...
    {
      "name": "Grafana",
      "description": "Monitoring and observability platform",
      "url": "https://um.tail16ca22.ts.net:9001/",
      "alternativeUrl": "https://grafana.um.tail16ca22.ts.net/",
      "icon": "📊",
      "category": "monitoring"
    }
  ]
}
```

## Port Number Management

### Currently Used Ports
```
80, 443   - Main Tailscale domain (Traefik)
8081      - Traefik HTTP
8443      - Traefik HTTPS  
9000      - Portainer (local)
9443      - Portainer (Tailscale HTTPS)
8200      - Vault (local)
8243      - Vault (Tailscale HTTPS)
8053      - Pi-hole (local)
8543      - Pi-hole (Tailscale HTTPS)
30080     - Rancher HTTP (K3s NodePort)
30443     - Rancher HTTPS (K3s NodePort)
8082      - Landing page (local)
```

### Recommended Port Ranges

#### Management & Infrastructure (9001-9099)
- `9001` - Grafana
- `9002` - Prometheus  
- `9003` - AlertManager
- `9004` - Loki
- `9005` - Jaeger
- `9010` - GitLab
- `9020` - Jenkins

#### Web Applications (8501-8599)
- `8501` - Nextcloud
- `8502` - Jupyter Lab
- `8503` - VS Code Server
- `8504` - Bookstack
- `8505` - WikiJS
- `8510` - Plex
- `8520` - Jellyfin

#### Databases & Backends (7001-7099)
- `7001` - PostgreSQL Admin (pgAdmin)
- `7002` - MySQL Admin (phpMyAdmin)
- `7003` - Redis Admin
- `7004` - InfluxDB
- `7005` - MongoDB Admin

#### Development & Testing (6001-6099)
- `6001` - Development app 1
- `6002` - Development app 2
- `6003` - Staging environment

## Quick Templates

### Simple Web Application
```yaml
myapp:
  image: myapp:latest
  container_name: myapp
  restart: unless-stopped
  ports:
    - "8501:80"  # Pick from recommended ranges
  networks:
    - traefik-network
  labels:
    - "traefik.enable=true"
    - "traefik.http.routers.myapp.rule=Host(`myapp.um.tail16ca22.ts.net`)"
    - "traefik.http.routers.myapp.entrypoints=websecure"
    - "traefik.http.routers.myapp.middlewares=default-chain@file"
    - "traefik.http.services.myapp.loadbalancer.server.port=80"
```

### Database with Admin UI
```yaml
postgres:
  image: postgres:15
  container_name: postgres
  restart: unless-stopped
  environment:
    POSTGRES_DB: mydb
    POSTGRES_USER: user
    POSTGRES_PASSWORD: password
  volumes:
    - postgres-data:/var/lib/postgresql/data
  networks:
    - traefik-network

pgadmin:
  image: dpage/pgadmin4
  container_name: pgadmin
  restart: unless-stopped
  ports:
    - "7001:80"
  environment:
    PGADMIN_DEFAULT_EMAIL: admin@example.com
    PGADMIN_DEFAULT_PASSWORD: admin
  networks:
    - traefik-network
  labels:
    - "traefik.enable=true"
    - "traefik.http.routers.pgadmin.rule=Host(`pgadmin.um.tail16ca22.ts.net`)"
    - "traefik.http.routers.pgadmin.entrypoints=websecure"
    - "traefik.http.routers.pgadmin.middlewares=default-chain@file"
```

## Maintenance Commands

### Re-apply All Tailscale Configuration
```bash
cd /home/nic/projects/nicstack-k3/bootstrap/configs/tailscale
./apply-tailscale-serve.sh
```

### Check Current Tailscale Serve Status  
```bash
tailscale serve status
```

### Remove a Service from Tailscale
```bash
tailscale serve --https=9001 off
```

### Restart All Services
```bash
cd /home/nic/projects/nicstack-k3/bootstrap
docker compose down
docker compose up -d
```

### View Service Logs
```bash
docker compose logs -f servicename
```

## Troubleshooting New Services

### 1. Service Won't Start
- Check logs: `docker compose logs servicename`
- Verify port conflicts: `netstat -tlnp | grep :9001`
- Check docker-compose syntax: `docker compose config`

### 2. Can't Access via Tailscale
- Test local first: `curl -I http://localhost:9001/`
- Check Tailscale serve: `tailscale serve status`
- Verify domain resolution: `nslookup um.tail16ca22.ts.net`

### 3. Traefik Subdomain Not Working
- Check Traefik dashboard: `https://um.tail16ca22.ts.net:8443/`
- Verify labels are correct in docker-compose.yml
- Restart Traefik: `docker compose restart traefik`

### 4. Asset Loading Issues with Path Routing
- Use subdomain access instead: `https://servicename.um.tail16ca22.ts.net/`
- Or use direct port access: `https://um.tail16ca22.ts.net:9001/`
- Path routing works better with services that support base-path configuration

## Security Notes

### HTTPS Everywhere
- All Tailscale access uses HTTPS with automatic TLS termination
- HTTP access is only for local debugging
- Traefik handles SSL certificates for the main domain

### Network Isolation
- All services run in the `traefik-network` Docker network
- Services can communicate internally using container names
- Only exposed ports are accessible from outside

### Access Control
- Tailscale provides network-level access control
- Additional authentication should be configured per service
- Consider using Traefik's ForwardAuth for unified authentication

This guide provides everything needed to add new services to your Tailscale-enabled infrastructure while maintaining the current robust configuration.
