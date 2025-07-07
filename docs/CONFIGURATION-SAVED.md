# 🎯 NICSTACK-K3: CONFIGURATION SAVED & OPERATIONAL GUIDE

**Status**: ✅ **WORKING CONFIGURATION SAVED**  
**Date**: $(date)  
**Backup Location**: `/home/nic/projects/nicstack-k3/infrastructure/docker-compose/configs/latest-backup`

---

## 🚀 QUICK START: Re-apply Current Configuration

```bash
# 1. Start all services
cd /home/nic/projects/nicstack-k3/infrastructure/docker-compose
docker compose up -d

# 2. Apply Tailscale configuration
cd configs/tailscale
./apply-tailscale-serve.sh

# 3. Verify everything is working
curl -I https://um.tail16ca22.ts.net:9443/  # Portainer
curl -I https://um.tail16ca22.ts.net:8243/  # Vault
curl -I https://um.tail16ca22.ts.net:8543/  # Pi-hole
```

## 🌐 CURRENT ACCESS URLS

| Service | Primary HTTPS URL | Fallback HTTP | Purpose |
|---------|-------------------|---------------|---------|
| **Landing Page** | `https://um.tail16ca22.ts.net/` | `http://100.84.168.38:8082/` | Service directory |
| **Portainer** | `https://um.tail16ca22.ts.net:9443/` | `http://100.84.168.38:9000/` | Docker management |
| **Vault** | `https://um.tail16ca22.ts.net:8243/` | `http://100.84.168.38:8200/` | Secrets management |
| **Pi-hole** | `https://um.tail16ca22.ts.net:8543/` | `http://100.84.168.38:8053/` | DNS filtering |
| **Rancher** | `https://um.tail16ca22.ts.net:30443/dashboard/auth/login` | - | K3s management |
| **Traefik** | `https://um.tail16ca22.ts.net:8443/` | - | Reverse proxy dashboard |

---

## 📝 ADDING NEW SERVICES TO TAILNET

### 🎯 RECOMMENDED METHOD: Direct Port Access

**Why?** No asset loading issues, simple configuration, works with any web app.

#### Step-by-Step Example: Adding Grafana

1. **Add to docker-compose.yml**:
```yaml
grafana:
  image: grafana/grafana:latest
  container_name: grafana
  restart: unless-stopped
  ports:
    - "9001:3000"  # Pick from available ranges below
  networks:
    - foundation_network
  # Optional: Add Traefik labels for subdomain access
```

2. **Start the service**:
```bash
docker compose up -d grafana
```

3. **Add Tailscale HTTPS access**:
```bash
tailscale serve --bg --https=9001 http://localhost:9001
```

4. **Make it permanent** - Add to `/configs/tailscale/apply-tailscale-serve.sh`:
```bash
# Grafana - HTTPS termination for HTTP backend
tailscale serve --bg --https=9001 http://localhost:9001
```

5. **Test access**:
```bash
# Local test first
curl -I http://localhost:9001/

# Tailscale access
curl -k -I https://um.tail16ca22.ts.net:9001/
```

### 🔢 PORT NUMBER ALLOCATION

#### **Currently Used Ports**
```
80, 443   - Main Tailscale domain (Traefik)
8081      - Traefik HTTP internal
8443      - Traefik HTTPS internal
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

#### **Available Port Ranges** (Choose from these)
- **9001-9099**: Management services (Grafana, Prometheus, etc.)
- **8501-8599**: Web applications (Nextcloud, Jupyter, etc.)
- **7001-7099**: Database admins (pgAdmin, phpMyAdmin, etc.)
- **6001-6099**: Development/testing environments

### 🎨 OPTIONAL: Traefik Subdomain Integration

If you want `https://servicename.um.tail16ca22.ts.net/` URLs:

```yaml
# Add these labels to your service in docker-compose.yml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.myservice.rule=Host(`myservice.um.tail16ca22.ts.net`)"
  - "traefik.http.routers.myservice.entrypoints=websecure"
  - "traefik.http.routers.myservice.middlewares=default-chain@file"
  - "traefik.http.services.myservice.loadbalancer.server.port=3000"
```

---

## 🔧 MAINTENANCE & OPERATIONS

### Daily Commands
```bash
# Check all services
docker compose ps

# Check Tailscale status
tailscale serve status

# View service logs
docker compose logs -f servicename

# Restart a service
docker compose restart servicename

# Restart everything
docker compose down && docker compose up -d
```

### Backup Current Configuration
```bash
cd /home/nic/projects/nicstack-k3/infrastructure/docker-compose/configs/tailscale
./backup-config.sh
```

### Restore from Backup
```bash
# Use latest backup
cd /home/nic/projects/nicstack-k3/infrastructure/docker-compose/configs/latest-backup
./restore.sh

# Or restore from specific backup
cd /home/nic/projects/nicstack-k3/infrastructure/docker-compose/configs/backup-YYYYMMDD-HHMMSS
./restore.sh
```

### Emergency: Reset Tailscale
```bash
tailscale serve reset
cd /home/nic/projects/nicstack-k3/infrastructure/docker-compose/configs/tailscale
./apply-tailscale-serve.sh
```

---

## 📚 DOCUMENTATION LOCATIONS

- **📖 Complete service addition guide**: `/configs/tailscale/service-addition-guide.md`
- **🎯 Quick reference**: `/QUICK-REFERENCE.md`  
- **💾 Configuration backup**: `/configs/tailscale/simple-backup.sh`
- **🔧 Tailscale apply script**: `/configs/tailscale/apply-tailscale-serve.sh`
- **⚙️ Main compose file**: `/docker-compose.yml`

---

## 🎉 SUCCESS CRITERIA

✅ **All services accessible via HTTPS with Tailscale**  
✅ **Automatic HTTP → HTTPS redirects**  
✅ **No asset loading issues with direct port access**  
✅ **Easy re-application of entire config**  
✅ **Clear process for adding new services**  
✅ **Configuration backup system**  
✅ **Comprehensive documentation**  

**🎯 Your infrastructure is now production-ready and easily maintainable!**

---

## 🆘 SUPPORT

**Key Files to Check**:
- Traefik dashboard: `https://um.tail16ca22.ts.net:8443/`
- Docker logs: `docker compose logs -f servicename`
- Tailscale status: `tailscale serve status`

**Common Issues**:
- Service won't start → Check `docker compose logs servicename`
- Can't access via Tailscale → Test local access first, then check DNS
- Port conflicts → Use `netstat -tlnp | grep :PORT` to check usage

**Documentation Priority**:
1. Start with `/QUICK-REFERENCE.md` for daily operations
2. Use `/configs/tailscale/service-addition-guide.md` for adding services
3. All other docs are in `/configs/tailscale/` directory
