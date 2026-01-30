#!/bin/bash
set -e

echo "=========================================="
echo "Setting up ALB Ingress for EKS"
echo "=========================================="

# Step 1: Apply Terraform
echo ""
echo "Step 1: Applying Terraform configuration..."
terraform apply -auto-approve

# Step 2: Get outputs
echo ""
echo "Step 2: Getting Terraform outputs..."
CLUSTER_NAME=$(terraform output -raw eks_cluster_name)
VPC_ID=$(terraform output -raw vpc_id)
ROLE_ARN=$(terraform output -raw aws_load_balancer_controller_role_arn)

echo "  Cluster Name: $CLUSTER_NAME"
echo "  VPC ID: $VPC_ID"
echo "  IAM Role ARN: $ROLE_ARN"

# Step 3: Update YAML manifest
echo ""
echo "Step 3: Updating Kubernetes manifest..."
cp aws-load-balancer-controller.yaml aws-load-balancer-controller.yaml.backup
sed -i "s|REPLACE_WITH_IAM_ROLE_ARN|${ROLE_ARN}|g" aws-load-balancer-controller.yaml
sed -i "s|REPLACE_WITH_CLUSTER_NAME|${CLUSTER_NAME}|g" aws-load-balancer-controller.yaml
sed -i "s|REPLACE_WITH_VPC_ID|${VPC_ID}|g" aws-load-balancer-controller.yaml

echo "  Manifest updated successfully"

# Step 4: Create IngressClass
echo ""
echo "Step 4: Creating IngressClass..."
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: IngressClass
metadata:
  name: alb
spec:
  controller: ingress.k8s.aws/alb
EOF

# Step 5: Deploy Controller
echo ""
echo "Step 5: Deploying AWS Load Balancer Controller..."
kubectl apply -f aws-load-balancer-controller.yaml

# Step 6: Wait for deployment
echo ""
echo "Step 6: Waiting for controller to be ready (this may take 1-2 minutes)..."
kubectl wait --for=condition=available --timeout=300s deployment/aws-load-balancer-controller -n kube-system || {
    echo "Warning: Controller deployment timed out. Checking status..."
    kubectl get pods -n kube-system | grep aws-load-balancer-controller
    exit 1
}

# Step 7: Verify
echo ""
echo "Step 7: Verifying deployment..."
echo ""
echo "Controller Pods:"
kubectl get pods -n kube-system | grep aws-load-balancer-controller
echo ""
echo "IngressClass:"
kubectl get ingressclass alb
echo ""
echo "Service Account:"
kubectl describe sa aws-load-balancer-controller -n kube-system | grep "Annotations:" -A 1

echo ""
echo "=========================================="
echo "✅ Setup Complete!"
echo "=========================================="
echo ""
echo "You can now create Ingress resources. Example:"
echo ""
echo "kubectl apply -f - <<EOF"
echo "apiVersion: networking.k8s.io/v1"
echo "kind: Ingress"
echo "metadata:"
echo "  name: test-ingress"
echo "  annotations:"
echo "    alb.ingress.kubernetes.io/scheme: internet-facing"
echo "    alb.ingress.kubernetes.io/target-type: ip"
echo "spec:"
echo "  ingressClassName: alb"
echo "  rules:"
echo "  - http:"
echo "      paths:"
echo "      - path: /"
echo "        pathType: Prefix"
echo "        backend:"
echo "          service:"
echo "            name: your-service"
echo "            port:"
echo "              number: 80"
echo "EOF"
echo ""

