# ALB Ingress Readiness Checklist

## Current Status: ⚠️ **NOT READY YET** - Setup Required

To make the ALB work with Ingress, you need to complete these steps:

### ✅ Step 1: Apply Terraform Configuration
**Status:** ⚠️ **NEEDS TO BE APPLIED**

```bash
terraform plan   # Review changes
terraform apply  # Apply the ALB infrastructure
```

**What this creates:**
- ALB Security Group
- IAM Role for AWS Load Balancer Controller
- OIDC Provider for IRSA
- Security Group Rules

### ✅ Step 2: Update Kubernetes Manifest
**Status:** ⚠️ **NEEDS TO BE UPDATED**

The `aws-load-balancer-controller.yaml` file has placeholders that need to be replaced:

```bash
# Get values from Terraform outputs
CLUSTER_NAME=$(terraform output -raw eks_cluster_name)
VPC_ID=$(terraform output -raw vpc_id)
ROLE_ARN=$(terraform output -raw aws_load_balancer_controller_role_arn)

# Update the manifest
sed -i "s|REPLACE_WITH_IAM_ROLE_ARN|${ROLE_ARN}|g" aws-load-balancer-controller.yaml
sed -i "s|REPLACE_WITH_CLUSTER_NAME|${CLUSTER_NAME}|g" aws-load-balancer-controller.yaml
sed -i "s|REPLACE_WITH_VPC_ID|${VPC_ID}|g" aws-load-balancer-controller.yaml
```

### ✅ Step 3: Deploy AWS Load Balancer Controller
**Status:** ⚠️ **NOT DEPLOYED**

```bash
kubectl apply -f aws-load-balancer-controller.yaml
```

### ✅ Step 4: Verify Controller is Running
**Status:** ⚠️ **NOT VERIFIED**

```bash
# Check if pod is running
kubectl get pods -n kube-system | grep aws-load-balancer-controller

# Check logs
kubectl logs -n kube-system deployment/aws-load-balancer-controller

# Verify service account has IAM role
kubectl describe sa aws-load-balancer-controller -n kube-system
```

### ✅ Step 5: Create IngressClass Resource
**Status:** ⚠️ **NEEDS TO BE CREATED**

Create an IngressClass for ALB:

```bash
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: IngressClass
metadata:
  name: alb
spec:
  controller: ingress.k8s.aws/alb
EOF
```

## Quick Setup Script

Run this complete setup script:

```bash
#!/bin/bash
set -e

echo "Step 1: Applying Terraform..."
terraform apply -auto-approve

echo "Step 2: Getting Terraform outputs..."
CLUSTER_NAME=$(terraform output -raw eks_cluster_name)
VPC_ID=$(terraform output -raw vpc_id)
ROLE_ARN=$(terraform output -raw aws_load_balancer_controller_role_arn)

echo "Step 3: Updating Kubernetes manifest..."
sed -i "s|REPLACE_WITH_IAM_ROLE_ARN|${ROLE_ARN}|g" aws-load-balancer-controller.yaml
sed -i "s|REPLACE_WITH_CLUSTER_NAME|${CLUSTER_NAME}|g" aws-load-balancer-controller.yaml
sed -i "s|REPLACE_WITH_VPC_ID|${VPC_ID}|g" aws-load-balancer-controller.yaml

echo "Step 4: Creating IngressClass..."
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: IngressClass
metadata:
  name: alb
spec:
  controller: ingress.k8s.aws/alb
EOF

echo "Step 5: Deploying AWS Load Balancer Controller..."
kubectl apply -f aws-load-balancer-controller.yaml

echo "Step 6: Waiting for controller to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/aws-load-balancer-controller -n kube-system

echo "Step 7: Verifying deployment..."
kubectl get pods -n kube-system | grep aws-load-balancer-controller
kubectl get ingressclass alb

echo "✅ Setup complete! You can now create Ingress resources."
```

## Testing with Example Ingress

Once everything is set up, test with this example:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-test
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx-test
  template:
    metadata:
      labels:
        app: nginx-test
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: nginx-test-service
spec:
  selector:
    app: nginx-test
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nginx-test-ingress
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}]'
spec:
  ingressClassName: alb
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: nginx-test-service
            port:
              number: 80
```

## What's Already Configured ✅

- ✅ Subnets tagged correctly (`kubernetes.io/role/elb = "1"`)
- ✅ Security group for ALB (HTTP/HTTPS ports)
- ✅ IAM policy with all required permissions
- ✅ Terraform configuration ready

## What Needs to Be Done ⚠️

1. **Apply Terraform** - Create the infrastructure
2. **Update YAML** - Replace placeholders with actual values
3. **Deploy Controller** - Install the AWS Load Balancer Controller
4. **Create IngressClass** - Define the ALB ingress class
5. **Verify** - Check controller is running and healthy

## After Setup

Once complete, you can create Ingress resources and the controller will automatically:
- Create ALB when you create an Ingress
- Configure target groups
- Set up listeners
- Manage security groups
- Handle SSL/TLS termination (with ACM certificates)

