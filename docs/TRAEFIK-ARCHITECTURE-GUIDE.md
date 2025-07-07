# Traefik in Docker and K3s: Complete Architecture Guide

This document explains how Traefik works in our hybrid Docker Compose + K3s infrastructure and provides practical examples for both contexts.

## Overview: Two Traefik Instances

Our setup runs **two separate Traefik instances** to handle different workloads:

### 1. Docker Compose Traefik
- **Purpose**: Routes traffic to Docker containers
- **Ports**: 80/443 (main), 8080/8443 (alt), 8080 (dashboard)
- **Services**: Portainer, Vault, Pi-hole, Landing Page
- **Config**: `/infrastructure/docker-compose/configs/traefik/`
- **SSL**: Let's Encrypt ACME for automatic certificates
- **Network**: `foundation_network` Docker network

### 2. K3s Traefik (Built-in)
- **Purpose**: Routes traffic to Kubernetes services/pods
- **Ports**: 8880/8888 (to avoid conflicts), 9000 (dashboard)
- **Services**: Rancher, Kubernetes applications
- **Config**: `/manifests/core/traefik-config.yaml` (HelmChartConfig)
- **SSL**: Kubernetes native TLS/cert-manager integration
- **Network**: K3s cluster networking

## Why Two Instances?

1. **Isolation**: Docker and K3s workloads remain separate
2. **Port Conflicts**: Avoids conflicts between Docker and K3s Traefik
3. **Configuration**: Different config patterns (Docker labels vs K8s annotations)
4. **SSL Management**: Different certificate management strategies
5. **Flexibility**: Can manage each independently

## Docker Compose Traefik Configuration

### File Structure
```
infrastructure/docker-compose/configs/traefik/
├── traefik.yml          # Main configuration
├── dynamic.yml          # Dynamic configuration
└── routes.yml          # Custom route definitions
```

### Key Configuration (`traefik.yml`)

```yaml
# Entry points for Docker Traefik
entryPoints:
  web:
    address: ":80"
  websecure:
    address: ":443"
    http:
      tls: {}
  traefik:
    address: ":8080"

# Docker provider for container discovery
providers:
  docker:
    endpoint: "unix:///var/run/docker.sock"
    exposedByDefault: false
    network: "foundation_network"
  file:
    directory: /etc/traefik/dynamic
    watch: true

# Let's Encrypt for SSL certificates
certificatesResolvers:
  letsencrypt:
    acme:
      email: admin@nicstack.dev
      storage: /etc/traefik/acme/acme.json
      httpChallenge:
        entryPoint: web
```

### Service Configuration (Docker Labels)

Example from `docker-compose.yml`:

```yaml
services:
  portainer:
    image: portainer/portainer-ce:latest
    labels:
      - "traefik.enable=true"
      
      # HTTP to HTTPS redirect
      - "traefik.http.routers.portainer-web.rule=Host(`portainer.nicstack.dev`) || PathPrefix(`/portainer`)"
      - "traefik.http.routers.portainer-web.entrypoints=web"
      - "traefik.http.routers.portainer-web.middlewares=redirect-to-https"
      
      # Main HTTPS router
      - "traefik.http.routers.portainer.rule=Host(`portainer.nicstack.dev`) || PathPrefix(`/portainer`)"
      - "traefik.http.routers.portainer.entrypoints=websecure"
      - "traefik.http.routers.portainer.tls=true"
      - "traefik.http.routers.portainer.tls.certresolver=letsencrypt"
      - "traefik.http.routers.portainer.service=portainer"
      
      # Service definition
      - "traefik.http.services.portainer.loadbalancer.server.port=9000"
      
      # Path-based routing middleware
      - "traefik.http.middlewares.portainer-stripprefix.stripprefix.prefixes=/portainer"
      - "traefik.http.routers.portainer.middlewares=portainer-stripprefix"
```

**Access Methods:**
- Host-based: `https://portainer.nicstack.dev`
- Path-based: `https://nicstack.dev/portainer`
- Via Tailscale: `https://your-domain.ts.net/portainer`

## K3s Traefik Configuration

### HelmChartConfig (`traefik-config.yaml`)

```yaml
apiVersion: helm.cattle.io/v1
kind: HelmChartConfig
metadata:
  name: traefik
  namespace: kube-system
spec:
  valuesContent: |-
    # Custom ports to avoid conflicts with Docker Traefik
    entryPoints:
      web:
        address: ":8880"
      websecure:
        address: ":8888"
      traefik:
        address: ":9000"
    
    # External IPs for LoadBalancer service
    service:
      type: LoadBalancer
      spec:
        externalIPs:
        - "192.168.1.49"
        - "192.168.1.50"
```

### Service Configuration (K8s Annotations)

Example Ingress for a K3s application:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: hello-world-ingress
  namespace: default
  annotations:
    # K3s Traefik annotations
    traefik.ingress.kubernetes.io/router.entrypoints: websecure
    traefik.ingress.kubernetes.io/router.tls: "true"
    # Optional middleware
    traefik.ingress.kubernetes.io/router.middlewares: default-rate-limit@kubernetescrd
spec:
  tls:
  - hosts:
    - hello.nicstack.dev
    secretName: hello-world-tls
  rules:
  # Host-based routing
  - host: hello.nicstack.dev
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: hello-world-service
            port:
              number: 80
  # Path-based routing for local access
  - http:
      paths:
      - path: /hello
        pathType: Prefix
        backend:
          service:
            name: hello-world-service
            port:
              number: 80
```

**Access Methods:**
- Local path-based: `https://192.168.1.49:8888/hello`
- Local host-based: `https://hello.nicstack.dev:8888/`
- Public domain: `https://hello.nicstack.dev` (port 8888, needs DNS)
- Via Tailscale: `https://your-domain.ts.net/hello`

## Practical Examples

### 1. Adding a Docker Service

To add a new Docker service with Traefik routing:

```yaml
# In docker-compose.yml
services:
  my-app:
    image: my-app:latest
    networks:
      - foundation_network
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.my-app.rule=Host(`my-app.nicstack.dev`)"
      - "traefik.http.routers.my-app.entrypoints=websecure"
      - "traefik.http.routers.my-app.tls=true"
      - "traefik.http.routers.my-app.tls.certresolver=letsencrypt"
      - "traefik.http.services.my-app.loadbalancer.server.port=3000"

networks:
  foundation_network:
    external: true
```

### 2. Adding a K3s Application

To add a new K3s application with Traefik routing:

```bash
# 1. Create manifests
mkdir -p manifests/apps/my-k8s-app

# 2. Create deployment.yaml
cat > manifests/apps/my-k8s-app/deployment.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-k8s-app
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: my-k8s-app
  template:
    metadata:
      labels:
        app: my-k8s-app
    spec:
      containers:
      - name: my-k8s-app
        image: nginx:alpine
        ports:
        - containerPort: 80
EOF

# 3. Create service.yaml
cat > manifests/apps/my-k8s-app/service.yaml << EOF
apiVersion: v1
kind: Service
metadata:
  name: my-k8s-app-service
  namespace: default
spec:
  selector:
    app: my-k8s-app
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
EOF

# 4. Create ingress.yaml
cat > manifests/apps/my-k8s-app/ingress.yaml << EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-k8s-app-ingress
  namespace: default
  annotations:
    traefik.ingress.kubernetes.io/router.entrypoints: websecure
    traefik.ingress.kubernetes.io/router.tls: "true"
spec:
  tls:
  - hosts:
    - my-k8s-app.nicstack.dev
    secretName: my-k8s-app-tls
  rules:
  - host: my-k8s-app.nicstack.dev
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: my-k8s-app-service
            port:
              number: 80
  - http:
      paths:
      - path: /my-k8s-app
        pathType: Prefix
        backend:
          service:
            name: my-k8s-app-service
            port:
              number: 80
EOF

# 5. Deploy
kubectl apply -f manifests/apps/my-k8s-app/
```

## SSL/TLS Certificate Management

### Docker Compose Traefik
- **Automatic**: Let's Encrypt ACME HTTP challenge
- **Storage**: `/etc/traefik/acme/acme.json`
- **Configuration**: Via `certificatesResolvers` in `traefik.yml`

```yaml
certificatesResolvers:
  letsencrypt:
    acme:
      email: admin@nicstack.dev
      storage: /etc/traefik/acme/acme.json
      httpChallenge:
        entryPoint: web
```

### K3s Traefik
- **Manual TLS Secrets**: Create Kubernetes secrets
- **Cert-Manager Integration**: Automatic certificate management
- **Ingress TLS**: Configure in ingress spec

```bash
# Manual certificate
kubectl create secret tls my-app-tls \
  --cert=cert.crt \
  --key=cert.key \
  --namespace=default

# Or use cert-manager with annotations
metadata:
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
```

## Monitoring and Debugging

### Docker Traefik Dashboard
- **URL**: `http://localhost:8080` or `https://traefik.nicstack.dev`
- **Features**: View routes, services, middlewares, health

### K3s Traefik Dashboard
- **URL**: `http://localhost:9000` (via port-forward)
- **Port Forward**: `kubectl port-forward -n kube-system service/traefik 9000:9000`
- **Features**: View Kubernetes ingresses, services, endpoints

### Useful Commands

```bash
# Docker Traefik logs
docker logs foundation_traefik_1

# K3s Traefik logs
kubectl logs -n kube-system deployment/traefik

# Check Docker Traefik config
docker exec foundation_traefik_1 cat /etc/traefik/traefik.yml

# Check K3s ingresses
kubectl get ingress --all-namespaces

# Test routing
curl -H "Host: my-app.nicstack.dev" http://localhost:80
curl -k https://192.168.1.49:8888/my-k8s-app
```

## Advanced Configuration

### Custom Middleware

#### Docker Compose
```yaml
# In dynamic.yml
http:
  middlewares:
    auth:
      basicAuth:
        users:
          - "admin:$2y$10$..."
    rate-limit:
      rateLimit:
        burst: 100
        average: 50
```

#### K3s
```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: Middleware
metadata:
  name: auth
  namespace: default
spec:
  basicAuth:
    secret: auth-secret
---
apiVersion: traefik.containo.us/v1alpha1
kind: Middleware
metadata:
  name: rate-limit
  namespace: default
spec:
  rateLimit:
    burst: 100
    average: 50
```

### Traffic Splitting

#### Docker Compose
```yaml
labels:
  - "traefik.http.services.app.loadbalancer.server.port=3000"
  - "traefik.http.services.app-v2.loadbalancer.server.port=3001"
  - "traefik.http.routers.app.service=app@docker"
  - "traefik.http.routers.app-canary.service=app-v2@docker"
  - "traefik.http.routers.app-canary.rule=Host(`app.nicstack.dev`) && Header(`X-Canary`, `true`)"
```

#### K3s
```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: TraefikService
metadata:
  name: app-split
  namespace: default
spec:
  weighted:
    services:
    - name: app-v1
      port: 80
      weight: 90
    - name: app-v2
      port: 80
      weight: 10
```

## Best Practices

### 1. Security
- Use HTTPS redirects for all public services
- Implement rate limiting for public endpoints
- Use basic auth or OAuth for admin interfaces
- Keep Traefik dashboards behind authentication

### 2. Performance
- Enable compression middleware
- Use appropriate load balancing algorithms
- Configure health checks for services
- Monitor resource usage

### 3. Reliability
- Set up proper health checks
- Use multiple replicas for K3s applications
- Configure circuit breakers for external dependencies
- Implement graceful shutdowns

### 4. Monitoring
- Enable Prometheus metrics
- Set up logging aggregation
- Use distributed tracing for complex applications
- Monitor certificate expiration

## Troubleshooting Guide

### Common Issues

1. **Service Not Found (404)**
   - Check service labels/annotations
   - Verify network connectivity
   - Check Traefik provider configuration

2. **SSL Certificate Issues**
   - Verify DNS configuration
   - Check Let's Encrypt rate limits
   - Ensure HTTP challenge accessibility

3. **Port Conflicts**
   - Docker Traefik: 80, 443, 8080, 8443
   - K3s Traefik: 8880, 8888, 9000
   - Ensure no conflicts with other services

4. **Ingress Not Working in K3s**
   - Verify ingress class (should be `traefik`)
   - Check service endpoints: `kubectl get endpoints`
   - Verify pod status: `kubectl get pods`

### Debug Commands

```bash
# Check Docker Traefik routes
curl http://localhost:8080/api/http/routers

# Check K3s Traefik configuration
kubectl get ingressroute --all-namespaces
kubectl describe ingress my-ingress

# Test service connectivity
kubectl run test-pod --image=curlimages/curl -it --rm -- /bin/sh
# Inside pod: curl http://my-service.default.svc.cluster.local
```

This guide provides a comprehensive understanding of how Traefik works in both Docker and K3s contexts within your infrastructure. Use it as a reference when configuring new services or troubleshooting routing issues.
