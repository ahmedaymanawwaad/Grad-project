# Application Load Balancer (ALB) Setup for EKS Ingress

This guide explains how to set up an Application Load Balancer (ALB) for use with EKS Ingress using the AWS Load Balancer Controller.

## What Was Created

1. **Security Group for ALB** - Allows HTTP/HTTPS traffic from internet
2. **IAM Role for AWS Load Balancer Controller** - Grants permissions to create/manage ALBs
3. **OIDC Provider** - Enables IAM Roles for Service Accounts (IRSA)
4. **Security Group Rules** - Allows ALB to communicate with EKS nodes

## Deployment Steps

### Step 1: Apply Terraform Changes

```bash
terraform plan
terraform apply
```

After applying, note the outputs:
- `aws_load_balancer_controller_role_arn` - IAM role ARN for the controller
- `alb_security_group_id` - Security group ID for ALB

### Step 2: Update Kubernetes Manifest

Update the `aws-load-balancer-controller.yaml` file with your cluster details:

```bash
# Get the IAM role ARN from Terraform output
terraform output aws_load_balancer_controller_role_arn

# Get the VPC ID
terraform output vpc_id

# Get the cluster name
terraform output eks_cluster_name
```

Then update the manifest file:
```bash
# Replace REPLACE_WITH_IAM_ROLE_ARN with the actual ARN
# Replace REPLACE_WITH_CLUSTER_NAME with your cluster name
# Replace REPLACE_WITH_VPC_ID with your VPC ID
```

Or use sed to automate:
```bash
CLUSTER_NAME=$(terraform output -raw eks_cluster_name)
VPC_ID=$(terraform output -raw vpc_id)
ROLE_ARN=$(terraform output -raw aws_load_balancer_controller_role_arn)

sed -i "s|REPLACE_WITH_IAM_ROLE_ARN|${ROLE_ARN}|g" aws-load-balancer-controller.yaml
sed -i "s|REPLACE_WITH_CLUSTER_NAME|${CLUSTER_NAME}|g" aws-load-balancer-controller.yaml
sed -i "s|REPLACE_WITH_VPC_ID|${VPC_ID}|g" aws-load-balancer-controller.yaml
```

### Step 3: Deploy AWS Load Balancer Controller

```bash
kubectl apply -f aws-load-balancer-controller.yaml
```

### Step 4: Verify Installation

```bash
# Check if the controller pod is running
kubectl get pods -n kube-system | grep aws-load-balancer-controller

# Check controller logs
kubectl logs -n kube-system deployment/aws-load-balancer-controller
```

## Using ALB Ingress

### Example: Deploy a Sample Application with Ingress

Create a file `example-ingress.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
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
  name: nginx-service
spec:
  selector:
    app: nginx
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nginx-ingress
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
            name: nginx-service
            port:
              number: 80
```

Deploy it:
```bash
kubectl apply -f example-ingress.yaml
```

### Get ALB DNS Name

After deploying the Ingress, get the ALB DNS name:

```bash
kubectl get ingress nginx-ingress
```

The `ADDRESS` column will show the ALB DNS name. You can access your application using this URL.

## Ingress Annotations

Common annotations for ALB Ingress:

- `alb.ingress.kubernetes.io/scheme`: `internet-facing` or `internal`
- `alb.ingress.kubernetes.io/target-type`: `ip` (for Fargate/IP mode) or `instance`
- `alb.ingress.kubernetes.io/listen-ports`: `[{"HTTP": 80}, {"HTTPS": 443}]`
- `alb.ingress.kubernetes.io/ssl-redirect`: `443` (redirect HTTP to HTTPS)
- `alb.ingress.kubernetes.io/certificate-arn`: ARN of ACM certificate for HTTPS
- `alb.ingress.kubernetes.io/load-balancer-name`: Custom ALB name
- `alb.ingress.kubernetes.io/subnets`: Comma-separated subnet IDs (optional, uses cluster subnets by default)

## Troubleshooting

### Controller not creating ALB

1. Check controller logs:
   ```bash
   kubectl logs -n kube-system deployment/aws-load-balancer-controller
   ```

2. Verify IAM role is attached:
   ```bash
   kubectl describe sa aws-load-balancer-controller -n kube-system
   ```

3. Check Ingress events:
   ```bash
   kubectl describe ingress <ingress-name>
   ```

### ALB created but not accessible

1. Check security groups allow traffic
2. Verify subnets have proper tags (`kubernetes.io/role/elb = "1"`)
3. Check ALB target group health

## Additional Resources

- [AWS Load Balancer Controller Documentation](https://kubernetes-sigs.github.io/aws-load-balancer-controller/)
- [EKS Ingress Best Practices](https://docs.aws.amazon.com/eks/latest/userguide/alb-ingress.html)

