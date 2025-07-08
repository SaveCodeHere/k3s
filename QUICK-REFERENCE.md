# 🚀 Nicstack-K3 Quick Reference

## Daily Operations

### Start All Services
```bash
cd /home/nic/projects/nicstack-k3/bootstrap
docker compose up -d
```

### Apply Tailscale Configuration
```bash
cd /home/nic/projects/nicstack-k3/bootstrap/configs/tailscale
./apply-tailscale-serve.sh
```

### Check Service Status
```bash
# Docker services
docker compose ps

# Tailscale serve status
tailscale serve status

# Check if all services are accessible
curl -I https://um.tail16ca22.ts.net:9443/  # Portainer
curl -I https://um.tail16ca22.ts.net:8243/  # Vault
curl -I https://um.tail16ca22.ts.net:8543/  # Pi-hole
```

## Quick Access URLs

| Service | HTTPS URL | Fallback HTTP |
|---------|-----------|---------------|
| **Main Dashboard** | `https://um.tail16ca22.ts.net/` | `http://100.84.168.38:8081/` |
| **Portainer** | `https://um.tail16ca22.ts.net:9443/` | `http://100.84.168.38:9000/` |
| **Vault** | `https://um.tail16ca22.ts.net:8243/` | `http://100.84.168.38:8200/` |
| **Pi-hole** | `https://um.tail16ca22.ts.net:8543/` | `http://100.84.168.38:8053/` |
| **Rancher** | `https://100.84.168.38:30443/dashboard/auth/login` | - |
| **Traefik** | `https://um.tail16ca22.ts.net:8443/` | - |

## Troubleshooting

### Service Won't Start
```bash
# Check logs
docker compose logs -f servicename

# Restart specific service
docker compose restart servicename

# Restart everything
docker compose down && docker compose up -d
```

### Tailscale Access Issues
```bash
# Reset and reapply
tailscale serve reset
./apply-tailscale-serve.sh

# Check DNS resolution
nslookup um.tail16ca22.ts.net

# Test local access first
curl -I http://localhost:9000/  # Portainer local
```

### Port Conflicts
```bash
# Check what's using a port
netstat -tlnp | grep :9000

# Kill process on port (if needed)
sudo lsof -ti:9000 | xargs sudo kill -9
```

## Adding New Services (Quick)

1. **Add to docker-compose.yml** with unique port
2. **Start service**: `docker compose up -d newservice`
3. **Add Tailscale access**: `tailscale serve --bg --https=XXXX http://localhost:XXXX`
4. **Update apply script** to make it permanent

### Available Ports for New Services
- **9001-9099**: Management (Grafana, Prometheus, etc.)
- **8501-8599**: Web apps (Nextcloud, Jupyter, etc.)
- **7001-7099**: Databases (pgAdmin, phpMyAdmin, etc.)
- **6001-6099**: Development/testing

## Backup & Restore

### Create Backup
```bash
cd /home/nic/projects/nicstack-k3/bootstrap/configs/tailscale
./backup-config.sh
```

### Restore Latest Backup
```bash
cd /home/nic/projects/nicstack-k3/bootstrap/configs/latest-backup
./restore.sh
```

## Key Files

- **Main Config**: `/home/nic/projects/nicstack-k3/bootstrap/docker-compose.yml`
- **Tailscale Apply**: `/home/nic/projects/nicstack-k3/bootstrap/configs/tailscale/apply-tailscale-serve.sh`
- **Traefik Routes**: `/home/nic/projects/nicstack-k3/bootstrap/configs/traefik/routes.yml`
- **Landing Page**: `/home/nic/projects/nicstack-k3/bootstrap/configs/landing-page/services.json`

## Emergency Contacts & Info

- **Tailscale Domain**: `um.tail16ca22.ts.net`
- **Host IP**: `100.84.168.38`
- **K3s Rancher**: Port `30443` (direct NodePort)
- **All docs**: `/home/nic/projects/nicstack-k3/bootstrap/configs/tailscale/`

---
*Generated: $(date)*
*Config saved in: /home/nic/projects/nicstack-k3/bootstrap/configs/*
