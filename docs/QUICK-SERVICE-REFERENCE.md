# Quick Reference: Adding New Services

This guide provides quick reference templates for adding new services to your hybrid Docker/K3s infrastructure.

## 🐳 Docker Compose Service Template

### 1. Basic Service
```yaml
# Add to infrastructure/docker-compose/docker-compose.yml
services:
  my-service:
    image: my-app:latest
    container_name: my-service
    restart: unless-stopped
    networks:
      - foundation_network
    # volumes:
    #   - ./configs/my-service:/config
    environment:
      - ENV_VAR=value
    labels:
      - "traefik.enable=true"
      
      # HTTP to HTTPS redirect
      - "traefik.http.routers.my-service-web.rule=Host(`my-service.nicstack.dev`) || PathPrefix(`/my-service`)"
      - "traefik.http.routers.my-service-web.entrypoints=web"
      - "traefik.http.routers.my-service-web.middlewares=redirect-to-https"
      
      # Main HTTPS router
      - "traefik.http.routers.my-service.rule=Host(`my-service.nicstack.dev`) || PathPrefix(`/my-service`)"
      - "traefik.http.routers.my-service.entrypoints=websecure"
      - "traefik.http.routers.my-service.tls=true"
      - "traefik.http.routers.my-service.tls.certresolver=letsencrypt"
      - "traefik.http.routers.my-service.service=my-service"
      
      # Service definition
      - "traefik.http.services.my-service.loadbalancer.server.port=3000"
      
      # Path-based routing middleware (if using path-based access)
      - "traefik.http.middlewares.my-service-stripprefix.stripprefix.prefixes=/my-service"
      - "traefik.http.routers.my-service.middlewares=my-service-stripprefix"

networks:
  foundation_network:
    external: true
```

### 2. Access URLs
- Host-based: `https://my-service.nicstack.dev`
- Path-based: `https://nicstack.dev/my-service`
- Tailscale: `https://your-domain.ts.net/my-service`

### 3. Add to Tailscale Serve
```bash
# Add to infrastructure/docker-compose/configs/tailscale/apply-tailscale-serve.sh
tailscale serve --bg --https=3000 http://localhost:3000
```

## ☸️ K3s Service Template

### 1. Directory Structure
```bash
mkdir -p manifests/apps/my-k8s-service
cd manifests/apps/my-k8s-service
```

### 2. Deployment
```yaml
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-k8s-service
  namespace: default
  labels:
    app: my-k8s-service
spec:
  replicas: 2
  selector:
    matchLabels:
      app: my-k8s-service
  template:
    metadata:
      labels:
        app: my-k8s-service
    spec:
      containers:
      - name: my-k8s-service
        image: my-app:latest
        ports:
        - containerPort: 3000
        env:
        - name: ENV_VAR
          value: "value"
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 3000
          initialDelaySeconds: 5
          periodSeconds: 5
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 500m
            memory: 512Mi
```

### 3. Service
```yaml
# service.yaml
apiVersion: v1
kind: Service
metadata:
  name: my-k8s-service
  namespace: default
  labels:
    app: my-k8s-service
spec:
  selector:
    app: my-k8s-service
  ports:
  - name: http
    port: 80
    targetPort: 3000
    protocol: TCP
  type: ClusterIP
```

### 4. Ingress
```yaml
# ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-k8s-service-ingress
  namespace: default
  labels:
    app: my-k8s-service
  annotations:
    # K3s Traefik configuration
    traefik.ingress.kubernetes.io/router.entrypoints: websecure
    traefik.ingress.kubernetes.io/router.tls: "true"
    # Optional: cert-manager for automatic SSL
    # cert-manager.io/cluster-issuer: letsencrypt-prod
    # Optional: middleware
    # traefik.ingress.kubernetes.io/router.middlewares: default-rate-limit@kubernetescrd
spec:
  tls:
  - hosts:
    - my-k8s-service.nicstack.dev
    secretName: my-k8s-service-tls
  rules:
  # Host-based routing for public domain
  - host: my-k8s-service.nicstack.dev
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: my-k8s-service
            port:
              number: 80
  # Path-based routing for local access
  - http:
      paths:
      - path: /my-k8s-service
        pathType: Prefix
        backend:
          service:
            name: my-k8s-service
            port:
              number: 80
```

### 5. Deploy
```bash
kubectl apply -f manifests/apps/my-k8s-service/
kubectl wait --for=condition=available --timeout=60s deployment/my-k8s-service
```

### 6. Access URLs
- Local path: `https://192.168.1.49:8888/my-k8s-service`
- Local host: `https://my-k8s-service.nicstack.dev:8888/`
- Public: `https://my-k8s-service.nicstack.dev` (port 8888, needs DNS)
- Tailscale: `https://your-domain.ts.net:8888/my-k8s-service`

### 7. Add to Tailscale Serve
```bash
# Add to infrastructure/docker-compose/configs/tailscale/apply-tailscale-serve.sh
tailscale serve --bg --https=8888 --set-path=/my-k8s-service https://localhost:8888/my-k8s-service
```

## 🔧 Common Configurations

### Environment Variables
```yaml
# Docker Compose
environment:
  - DATABASE_URL=postgresql://user:pass@db:5432/myapp
  - REDIS_URL=redis://redis:6379

# K3s (via ConfigMap/Secret)
apiVersion: v1
kind: ConfigMap
metadata:
  name: my-app-config
data:
  DATABASE_URL: postgresql://user:pass@db:5432/myapp
---
# Reference in deployment
env:
- name: DATABASE_URL
  valueFrom:
    configMapKeyRef:
      name: my-app-config
      key: DATABASE_URL
```

### Volumes/Persistence
```yaml
# Docker Compose
volumes:
  - ./data:/app/data
  - my-app-config:/config

# K3s
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-app-data
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
---
# Reference in deployment
volumeMounts:
- name: data
  mountPath: /app/data
volumes:
- name: data
  persistentVolumeClaim:
    claimName: my-app-data
```

### Database Service
```yaml
# Docker Compose
services:
  my-db:
    image: postgres:15
    environment:
      - POSTGRES_DB=myapp
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD=password
    volumes:
      - my-db-data:/var/lib/postgresql/data
    networks:
      - foundation_network
    # No Traefik labels (internal service)

volumes:
  my-db-data:
```

### Secrets Management
```yaml
# K3s Secret
apiVersion: v1
kind: Secret
metadata:
  name: my-app-secrets
type: Opaque
data:
  api-key: <base64-encoded-value>
  db-password: <base64-encoded-value>
---
# Reference in deployment
env:
- name: API_KEY
  valueFrom:
    secretKeyRef:
      name: my-app-secrets
      key: api-key
```

## 🚀 Deployment Scripts

### Docker Service Deployment
```bash
#!/bin/bash
# deploy-docker-service.sh
set -e

SERVICE_NAME="$1"
if [ -z "$SERVICE_NAME" ]; then
    echo "Usage: $0 <service-name>"
    exit 1
fi

cd /home/nic/projects/nicstack-k3/infrastructure/docker-compose

echo "Deploying Docker service: $SERVICE_NAME"
docker compose up -d "$SERVICE_NAME"
docker compose logs -f "$SERVICE_NAME"
```

### K3s Service Deployment
```bash
#!/bin/bash
# deploy-k8s-service.sh
set -e

SERVICE_NAME="$1"
if [ -z "$SERVICE_NAME" ]; then
    echo "Usage: $0 <service-name>"
    exit 1
fi

MANIFEST_DIR="/home/nic/projects/nicstack-k3/manifests/apps/$SERVICE_NAME"
if [ ! -d "$MANIFEST_DIR" ]; then
    echo "Manifest directory not found: $MANIFEST_DIR"
    exit 1
fi

echo "Deploying K3s service: $SERVICE_NAME"
kubectl apply -f "$MANIFEST_DIR/"
kubectl wait --for=condition=available --timeout=120s "deployment/$SERVICE_NAME"
kubectl get pods,services,ingress -l "app=$SERVICE_NAME"
```

## 🔍 Testing Commands

### Docker Service Testing
```bash
# Check container status
docker ps | grep my-service

# View logs
docker logs my-service

# Test internal connectivity
docker exec my-service curl http://localhost:3000/health

# Test Traefik routing
curl -H "Host: my-service.nicstack.dev" http://localhost:80
curl -k https://localhost:443/my-service
```

### K3s Service Testing
```bash
# Check pod status
kubectl get pods -l app=my-k8s-service

# View logs
kubectl logs -l app=my-k8s-service

# Test service connectivity
kubectl run test-pod --image=curlimages/curl -it --rm -- /bin/sh
# Inside pod: curl http://my-k8s-service.default.svc.cluster.local

# Test ingress
curl -k https://192.168.1.49:8888/my-k8s-service
curl -H "Host: my-k8s-service.nicstack.dev" -k https://192.168.1.49:8888/
```

## 📚 Useful References

### Port Usage
- **Docker Traefik**: 80, 443, 8080, 8443
- **K3s Traefik**: 8880, 8888, 9000
- **Rancher**: 30443 (NodePort)
- **Docker Services**: 9000 (Portainer), 8200 (Vault), 8053 (Pi-hole)

### Network Overview
- **Docker Network**: `foundation_network`
- **K3s Network**: Cluster networking (CNI)
- **Tailscale**: Overlay network for secure access

### File Locations
- **Docker Configs**: `/home/nic/projects/nicstack-k3/infrastructure/docker-compose/`
- **K3s Manifests**: `/home/nic/projects/nicstack-k3/manifests/`
- **Scripts**: `/home/nic/projects/nicstack-k3/scripts/`
- **Documentation**: `/home/nic/projects/nicstack-k3/docs/`

This quick reference should help you rapidly deploy new services following the established patterns!
