#!/bin/bash
set -e

echo "=========================================="
echo "Starting Local Development Environment"
echo "=========================================="

# Check if Minikube is installed
if ! command -v minikube &> /dev/null; then
    echo "❌ Minikube is not installed!"
    echo "Install it with: brew install minikube (macOS) or visit https://minikube.sigs.k8s.io/docs/start/"
    exit 1
fi

# Check if Minikube is running
if minikube status &> /dev/null; then
    echo "⚠️  Minikube is already running"
    read -p "Do you want to restart it? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Stopping Minikube..."
        minikube stop
    else
        echo "Using existing Minikube instance"
    fi
fi

# Start Minikube
echo ""
echo "Step 1: Starting Minikube..."
minikube start --cpus=4 --memory=4096 --disk-size=20g

# Enable ingress addon
echo ""
echo "Step 2: Enabling Ingress addon..."
minikube addons enable ingress

# Configure Docker to use Minikube's Docker daemon
echo ""
echo "Step 3: Configuring Docker environment..."
eval $(minikube docker-env)

# Verify Docker is working
echo ""
echo "Step 4: Verifying Docker..."
docker ps > /dev/null && echo "✅ Docker is ready"

# Get Minikube IP
MINIKUBE_IP=$(minikube ip)
echo ""
echo "Minikube IP: $MINIKUBE_IP"
echo ""
echo "=========================================="
echo "✅ Local environment is ready!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Build your image: docker build -t my-app:local ."
echo "2. Deploy to Minikube: kubectl apply -f k8s/local-deployment.yaml"
echo "3. Access your app: http://$MINIKUBE_IP"
echo ""
echo "Useful commands:"
echo "  minikube dashboard    # Open Kubernetes dashboard"
echo "  minikube service list # List all services"
echo "  kubectl get pods      # View pods"
echo ""

