# Kubernetes Manifests

This directory contains Kubernetes manifests for different environments.

## Files

- `local-deployment.yaml` - For Minikube/local testing
- `production-deployment.yaml` - For AWS EKS (create this when ready)

## Usage

### Local Development (Minikube)

```bash
# Start Minikube
./scripts/start-local.sh

# Build local image
eval $(minikube docker-env)
docker build -t my-app:local .

# Deploy
kubectl apply -f k8s/local-deployment.yaml

# Access
minikube service my-app-service --url
# Or add to /etc/hosts: $(minikube ip) my-app.local
```

### Production (AWS EKS)

```bash
# Build and push to ECR
docker build -t <account-id>.dkr.ecr.us-east-1.amazonaws.com/my-app:latest .
docker push <account-id>.dkr.ecr.us-east-1.amazonaws.com/my-app:latest

# Deploy
kubectl apply -f k8s/production-deployment.yaml
```

## Differences: Local vs Production

| Feature | Local (Minikube) | Production (EKS) |
|---------|------------------|------------------|
| Image Registry | Docker Hub or Local | ECR |
| Image Pull Policy | Never (local) or Always | Always |
| Ingress Class | nginx | alb |
| Ingress Annotations | NGINX-specific | ALB-specific |
| Service Type | ClusterIP or NodePort | ClusterIP |

