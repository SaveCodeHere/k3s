# K3s App Deployment Guide

This guide provides a complete step-by-step example of deploying a new application on K3s that is accessible via both Tailscale and public domain.

## Architecture Overview

### Traefik in Hybrid Setup

Our infrastructure uses **two separate Traefik instances**:

1. **Docker Compose Traefik** (ports 80/443, 8080/8443):
   - Handles Docker services: Portainer, Vault, Pi-hole
   - Manages SSL certificates via Let's Encrypt
   - Accessible via main domain routing

2. **K3s Traefik** (ports 8880/8888, 9000):
   - Handles Kubernetes services and ingresses
   - Uses different ports to avoid conflicts
   - Configured via HelmChartConfig in `/manifests/core/traefik-config.yaml`

### Access Patterns

- **Local Access**: Direct IP + port (e.g., `https://192.168.1.49:8888`)
- **Tailscale Access**: Via Tailscale domain (e.g., `https://my-app.tail-scale-domain.ts.net`)
- **Public Domain Access**: Via public domain with DNS (e.g., `https://my-app.nicstack.dev`)

## Step-by-Step Example: Deploying a Simple Web App

### Step 1: Create Application Manifests

Let's deploy a simple nginx-based web application called "hello-world":

```bash
mkdir -p /home/nic/projects/nicstack-k3/manifests/apps/hello-world
```

Create the deployment, service, and ingress:

**Deployment:**
```yaml
# manifests/apps/hello-world/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hello-world
  namespace: default
spec:
  replicas: 2
  selector:
    matchLabels:
      app: hello-world
  template:
    metadata:
      labels:
        app: hello-world
    spec:
      containers:
      - name: hello-world
        image: nginx:alpine
        ports:
        - containerPort: 80
        volumeMounts:
        - name: html-content
          mountPath: /usr/share/nginx/html
      volumes:
      - name: html-content
        configMap:
          name: hello-world-content
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: hello-world-content
  namespace: default
data:
  index.html: |
    <!DOCTYPE html>
    <html>
    <head>
        <title>Hello World - K3s App</title>
        <style>
            body { font-family: Arial, sans-serif; text-align: center; margin-top: 50px; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .badge { background: #007acc; color: white; padding: 10px; border-radius: 5px; }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>🚀 Hello World from K3s!</h1>
            <p class="badge">This app is running on Kubernetes</p>
            <p>Accessible via:</p>
            <ul>
                <li>Local: https://192.168.1.49:8888/hello</li>
                <li>Tailscale: https://hello.your-tailscale-domain.ts.net</li>
                <li>Public: https://hello.nicstack.dev</li>
            </ul>
        </div>
    </body>
    </html>
```

**Service:**
```yaml
# manifests/apps/hello-world/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: hello-world-service
  namespace: default
spec:
  selector:
    app: hello-world
  ports:
  - name: http
    port: 80
    targetPort: 80
  type: ClusterIP
```

**Ingress:**
```yaml
# manifests/apps/hello-world/ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: hello-world-ingress
  namespace: default
  annotations:
    traefik.ingress.kubernetes.io/router.entrypoints: websecure
    traefik.ingress.kubernetes.io/router.tls: "true"
    # Optional: Enable middleware for additional features
    # traefik.ingress.kubernetes.io/router.middlewares: default-auth@kubernetescrd
spec:
  tls:
  - hosts:
    - hello.nicstack.dev
    secretName: hello-world-tls
  rules:
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
  # Also support path-based routing for local access
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

### Step 2: Deploy to K3s

```bash
cd /home/nic/projects/nicstack-k3

# Apply all manifests
kubectl apply -f manifests/apps/hello-world/

# Verify deployment
kubectl get pods -l app=hello-world
kubectl get service hello-world-service
kubectl get ingress hello-world-ingress
```

### Step 3: Configure Local Access

The app should now be accessible locally via the K3s Traefik:

```bash
# Test local access (path-based)
curl -k https://192.168.1.49:8888/hello

# Or if you have local DNS/hosts file configured
curl -k https://hello.nicstack.dev:8888/
```

### Step 4: Configure Tailscale Access

Add the new service to your Tailscale serve configuration:

```bash
# Edit the Tailscale serve script
nano infrastructure/docker-compose/configs/tailscale/apply-tailscale-serve.sh
```

Add these lines to the script:

```bash
# Add to apply-tailscale-serve.sh
echo "Configuring hello-world service..."
tailscale serve --bg --https=443 --set-path=/hello https://192.168.1.49:8888/hello

# Or for subdomain access (if you want hello.your-domain.ts.net)
# You'll need to configure this via Tailscale admin console for custom subdomains
```

Apply the updated configuration:

```bash
cd infrastructure/docker-compose/configs/tailscale
./apply-tailscale-serve.sh
```

### Step 5: Configure Public Domain Access

For public domain access, you need:

1. **DNS Configuration**: Point `hello.nicstack.dev` to your server's public IP
2. **SSL Certificate**: The K3s Traefik should automatically request one via Let's Encrypt
3. **Firewall Rules**: Ensure port 8888 is accessible from the internet

```bash
# Check if certificate was issued
kubectl get secrets hello-world-tls -o yaml

# Check Traefik logs for certificate requests
kubectl logs -n kube-system deployment/traefik
```

### Step 6: Test All Access Methods

```bash
# Local access
curl -k https://192.168.1.49:8888/hello

# Tailscale access
curl https://your-tailscale-domain.ts.net/hello

# Public domain access (once DNS and certs are configured)
curl https://hello.nicstack.dev
```

## Adding SSL/TLS Certificates

### Automatic Certificates (Let's Encrypt)

K3s Traefik can automatically request certificates. Add to your ingress:

```yaml
metadata:
  annotations:
    traefik.ingress.kubernetes.io/router.tls.certresolver: letsencrypt
    cert-manager.io/cluster-issuer: letsencrypt-prod
```

### Manual Certificates

If you have existing certificates:

```bash
kubectl create secret tls hello-world-tls \
  --cert=path/to/cert.crt \
  --key=path/to/cert.key \
  --namespace=default
```

## Advanced Configuration

### Custom Middleware

Create custom Traefik middleware for authentication, rate limiting, etc:

```yaml
# manifests/core/middleware.yaml
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

### Health Checks and Monitoring

Add health checks to your deployment:

```yaml
spec:
  containers:
  - name: hello-world
    image: nginx:alpine
    livenessProbe:
      httpGet:
        path: /
        port: 80
      initialDelaySeconds: 30
      periodSeconds: 10
    readinessProbe:
      httpGet:
        path: /
        port: 80
      initialDelaySeconds: 5
      periodSeconds: 5
```

## Troubleshooting

### Common Issues

1. **Port Conflicts**: Remember K3s Traefik uses ports 8880/8888, not 80/443
2. **Certificate Issues**: Check Traefik logs and DNS configuration
3. **Ingress Not Working**: Verify service endpoints and pod status

### Useful Commands

```bash
# Check K3s Traefik status
kubectl get pods -n kube-system -l app.kubernetes.io/name=traefik

# View Traefik dashboard (K3s)
kubectl port-forward -n kube-system service/traefik 9000:9000
# Then visit http://localhost:9000

# Check ingress status
kubectl describe ingress hello-world-ingress

# View service endpoints
kubectl get endpoints hello-world-service
```

## Template for New Services

Use this template structure for new K3s applications:

```
manifests/apps/[app-name]/
├── deployment.yaml      # Application deployment
├── service.yaml        # Kubernetes service
├── ingress.yaml        # Traefik ingress
├── configmap.yaml      # Configuration (optional)
├── secret.yaml         # Secrets (optional)
└── namespace.yaml      # Dedicated namespace (optional)
```

## Integration with Existing Infrastructure

### Docker Compose Services

To expose Docker Compose services via K3s Traefik, use ExternalService:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: portainer-external
  namespace: default
spec:
  type: ExternalName
  externalName: 192.168.1.49
  ports:
  - port: 9000
    targetPort: 9000
```

This allows you to create ingresses for Docker services through K3s Traefik if needed.

## Security Considerations

1. **Network Policies**: Implement Kubernetes network policies for service isolation
2. **RBAC**: Use proper role-based access control
3. **Secret Management**: Use Kubernetes secrets or external secret management
4. **Image Security**: Use specific image tags and scan for vulnerabilities

## Next Steps

1. Deploy your first test application following this guide
2. Configure DNS and SSL certificates for public access
3. Set up monitoring and logging for your applications
4. Implement CI/CD pipelines for automated deployments
