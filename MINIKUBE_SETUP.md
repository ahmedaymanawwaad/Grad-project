# Local Testing with Minikube

This guide helps you test your application locally using Minikube instead of AWS EKS, and Docker Hub instead of ECR to minimize costs during development.

## Prerequisites

- Docker installed
- Minikube installed
- kubectl installed
- Docker Hub account (free)

## Quick Setup

### Step 1: Install Minikube (if not installed)

**macOS:**
```bash
brew install minikube
```

**Linux:**
```bash
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
```

**Windows:**
```bash
# Download from https://minikube.sigs.k8s.io/docs/start/
```

### Step 2: Start Minikube

```bash
# Start Minikube with sufficient resources
minikube start --cpus=4 --memory=4096 --disk-size=20g

# Enable ingress addon (for Ingress testing)
minikube addons enable ingress

# Verify
kubectl get nodes
minikube status
```

### Step 3: Configure Docker to Use Minikube's Docker

```bash
# Point Docker to Minikube's Docker daemon
eval $(minikube docker-env)

# Verify
docker ps
```

---

## Local Development Workflow

### Option A: Use Docker Hub (Recommended for Testing)

#### 1. Build and Push to Docker Hub

```bash
# Login to Docker Hub
docker login

# Build your image
docker build -t your-dockerhub-username/my-app:latest .

# Push to Docker Hub
docker push your-dockerhub-username/my-app:latest
```

#### 2. Update Kubernetes Manifests

Create `k8s/local-deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
  labels:
    app: my-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      - name: my-app
        image: your-dockerhub-username/my-app:latest  # Use Docker Hub image
        ports:
        - containerPort: 80
        env:
        - name: ENV
          value: "local"
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
---
apiVersion: v1
kind: Service
metadata:
  name: my-app-service
spec:
  selector:
    app: my-app
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-app-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - host: my-app.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: my-app-service
            port:
              number: 80
```

#### 3. Deploy to Minikube

```bash
# Deploy application
kubectl apply -f k8s/local-deployment.yaml

# Check status
kubectl get pods
kubectl get services
kubectl get ingress

# Get Minikube IP and add to /etc/hosts
minikube ip  # Note the IP address
echo "$(minikube ip) my-app.local" | sudo tee -a /etc/hosts

# Access your app
curl http://my-app.local
# Or open in browser: http://my-app.local
```

### Option B: Use Local Docker Images (Fastest for Development)

#### 1. Build Image Locally

```bash
# Make sure you're using Minikube's Docker
eval $(minikube docker-env)

# Build image locally (no push needed!)
docker build -t my-app:local .

# Verify image exists
docker images | grep my-app
```

#### 2. Update Deployment to Use Local Image

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      - name: my-app
        image: my-app:local  # Local image, no registry needed
        imagePullPolicy: Never  # Important: use local image
        ports:
        - containerPort: 80
```

#### 3. Deploy

```bash
kubectl apply -f k8s/local-deployment.yaml
```

---

## Minikube-Specific Configuration

### Ingress Differences

**EKS (AWS ALB):**
```yaml
annotations:
  alb.ingress.kubernetes.io/scheme: internet-facing
  alb.ingress.kubernetes.io/target-type: ip
spec:
  ingressClassName: alb
```

**Minikube (NGINX Ingress):**
```yaml
annotations:
  nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
```

### Service Types

**Minikube supports:**
- ClusterIP (default)
- NodePort (for direct access)
- LoadBalancer (uses minikube tunnel)

**Example NodePort:**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-app-service
spec:
  type: NodePort
  selector:
    app: my-app
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30080  # Access via <minikube-ip>:30080
```

---

## Cost Comparison

| Resource | AWS EKS | Minikube |
|----------|---------|----------|
| Cluster | ~$0.10/hour | Free |
| Nodes (t2.micro) | ~$0.01/hour | Free |
| NAT Gateway | ~$0.045/hour | N/A |
| ALB | ~$0.0225/hour | Free |
| Data Transfer | Variable | Free |
| **Total/Hour** | **~$0.18/hour** | **$0** |
| **Monthly** | **~$130** | **$0** |

**Docker Hub:**
- Free tier: 1 private repo, unlimited public repos
- Perfect for testing!

---

## Development Scripts

### Start Local Environment

Create `scripts/start-local.sh`:

```bash
#!/bin/bash
set -e

echo "Starting Minikube..."
minikube start --cpus=4 --memory=4096

echo "Enabling ingress..."
minikube addons enable ingress

echo "Configuring Docker..."
eval $(minikube docker-env)

echo "Building local image..."
docker build -t my-app:local .

echo "Deploying application..."
kubectl apply -f k8s/local-deployment.yaml

echo "Waiting for pods..."
kubectl wait --for=condition=ready pod -l app=my-app --timeout=120s

echo "Getting service URL..."
minikube service my-app-service --url

echo "✅ Local environment ready!"
echo "Access your app at: http://$(minikube ip)"
```

### Stop Local Environment

Create `scripts/stop-local.sh`:

```bash
#!/bin/bash
echo "Stopping local environment..."

kubectl delete -f k8s/local-deployment.yaml || true

echo "Stopping Minikube..."
minikube stop

echo "✅ Local environment stopped"
```

---

## Testing Workflow

### 1. Develop Locally with Minikube

```bash
# Start Minikube
./scripts/start-local.sh

# Make changes to your code
# Rebuild image
eval $(minikube docker-env)
docker build -t my-app:local .

# Restart deployment
kubectl rollout restart deployment/my-app

# Test changes
curl http://$(minikube ip)
```

### 2. Test with Docker Hub

```bash
# Build and push to Docker Hub
docker build -t your-username/my-app:test .
docker push your-username/my-app:test

# Update deployment to use Docker Hub image
kubectl set image deployment/my-app my-app=your-username/my-app:test

# Verify
kubectl get pods
kubectl logs -f deployment/my-app
```

### 3. Deploy to AWS EKS (After Testing)

```bash
# Build and push to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com
docker build -t <account-id>.dkr.ecr.us-east-1.amazonaws.com/my-app:latest .
docker push <account-id>.dkr.ecr.us-east-1.amazonaws.com/my-app:latest

# Deploy to EKS
kubectl apply -f k8s/production-deployment.yaml
```

---

## Port Forwarding (Alternative to Ingress)

For quick testing without Ingress:

```bash
# Port forward to local machine
kubectl port-forward service/my-app-service 8080:80

# Access at http://localhost:8080
```

---

## Debugging Tips

### View Logs

```bash
# Pod logs
kubectl logs -f deployment/my-app

# All pods in namespace
kubectl logs -f -l app=my-app

# Previous container (if crashed)
kubectl logs -f deployment/my-app --previous
```

### Access Pod Shell

```bash
# Get pod name
kubectl get pods

# Execute shell
kubectl exec -it <pod-name> -- /bin/bash
```

### Minikube Dashboard

```bash
# Open dashboard
minikube dashboard

# Or get URL
minikube dashboard --url
```

### Check Ingress

```bash
# View ingress controller logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller

# Test ingress
curl -H "Host: my-app.local" http://$(minikube ip)
```

---

## Converting Manifests: EKS → Minikube

### Key Changes Needed

1. **Image Registry:**
   - EKS: `123456789.dkr.ecr.us-east-1.amazonaws.com/my-app:latest`
   - Minikube: `your-username/my-app:latest` or `my-app:local`

2. **Ingress Class:**
   - EKS: `ingressClassName: alb`
   - Minikube: `ingressClassName: nginx`

3. **Annotations:**
   - EKS: ALB-specific annotations
   - Minikube: NGINX-specific annotations

4. **Service Type:**
   - EKS: Usually ClusterIP (ALB handles external access)
   - Minikube: Can use NodePort or LoadBalancer for testing

5. **Resource Limits:**
   - EKS: Based on node capacity
   - Minikube: Based on allocated resources (default: 2GB RAM, 2 CPUs)

---

## Example: Complete Local Setup

### Directory Structure

```
project/
├── k8s/
│   ├── local-deployment.yaml      # Minikube-specific
│   ├── production-deployment.yaml # EKS-specific
│   └── base-deployment.yaml       # Shared config
├── scripts/
│   ├── start-local.sh
│   └── stop-local.sh
├── Dockerfile
└── src/
```

### Multi-Environment Strategy

Use Kustomize or separate manifests:

**k8s/local/kustomization.yaml:**
```yaml
resources:
  - ../base-deployment.yaml
patches:
  - patch: |-
      - op: replace
        path: /spec/template/spec/containers/0/image
        value: my-app:local
      - op: replace
        path: /spec/template/spec/containers/0/imagePullPolicy
        value: Never
```

**k8s/production/kustomization.yaml:**
```yaml
resources:
  - ../base-deployment.yaml
patches:
  - patch: |-
      - op: replace
        path: /spec/template/spec/containers/0/image
        value: 123456789.dkr.ecr.us-east-1.amazonaws.com/my-app:latest
```

---

## Summary

✅ **Use Minikube for:**
- Local development
- Testing before AWS deployment
- Learning Kubernetes
- Cost-free testing

✅ **Use Docker Hub for:**
- Free public repositories
- Sharing images
- CI/CD pipelines
- Testing

✅ **Use AWS EKS for:**
- Production deployments
- Scalability requirements
- AWS service integration
- Production workloads

**Recommended Workflow:**
1. Develop → Minikube + Local Docker images
2. Test → Minikube + Docker Hub
3. Deploy → AWS EKS + ECR

This approach saves ~$130/month during development! 🎉

