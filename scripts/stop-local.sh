#!/bin/bash
set -e

echo "=========================================="
echo "Stopping Local Development Environment"
echo "=========================================="

# Check if Minikube is running
if ! minikube status &> /dev/null; then
    echo "⚠️  Minikube is not running"
    exit 0
fi

# Delete deployments (optional)
read -p "Do you want to delete all deployments? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "Deleting deployments..."
    kubectl delete --all deployments --all-namespaces 2>/dev/null || true
    kubectl delete --all services --all-namespaces 2>/dev/null || true
    kubectl delete --all ingress --all-namespaces 2>/dev/null || true
fi

# Stop Minikube
echo ""
echo "Stopping Minikube..."
minikube stop

echo ""
echo "=========================================="
echo "✅ Local environment stopped"
echo "=========================================="
echo ""
echo "To start again, run: ./scripts/start-local.sh"
echo ""

