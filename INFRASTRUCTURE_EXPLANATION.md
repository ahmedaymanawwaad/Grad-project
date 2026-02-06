# Infrastructure Architecture Explanation

## Overview
This infrastructure is based on the reference repository pattern and provides a complete AWS EKS-based platform with API Gateway, Cognito authentication, and Kubernetes cluster management.

## Infrastructure Components

### 1. **VPC (Virtual Private Cloud)** - `vpc.tf`
- **CIDR Block**: Configurable via `vpc_cidr` variable (10.0.0.0/16 for nonprod, 10.1.0.0/16 for prod)
- **Subnets**: 
  - **2 Public Subnets**: Spanning 2 availability zones for internet-facing resources
  - **2 Private Subnets**: Spanning 2 availability zones for internal resources (EKS nodes)
- **Internet Gateway**: Provides internet access for public subnets
- **NAT Gateway**: Single NAT gateway in first public subnet for private subnet internet access
- **Route Tables**: 
  - Public route table routes traffic to Internet Gateway
  - Private route table routes traffic to NAT Gateway
- **Kubernetes Tags**: Subnets are tagged for EKS load balancer integration

### 2. **EKS Cluster** - `eks.tf`
- **Cluster Configuration**:
  - Name: `{project_name}-cluster`
  - Version: Configurable (default 1.30)
  - Endpoints: Both public and private access enabled
  - Authentication: API_AND_CONFIG_MAP mode with bootstrap admin permissions
  
- **Node Group**:
  - Name: `general`
  - Instance Type: Configurable (t3.medium default)
  - AMI: AL2023_x86_64_STANDARD (Amazon Linux 2023)
  - Scaling:
    - Nonprod: 1 desired, 1 min, 2 max
    - Prod: 2 desired, 1 min, 3 max
  - Placement: Private subnets only for security

- **IAM Roles**:
  - **Cluster Role**: Allows EKS service to manage cluster resources
  - **Node Role**: Allows EC2 instances to join the cluster with required policies:
    - AmazonEKSWorkerNodePolicy
    - AmazonEKS_CNI_Policy
    - AmazonEC2ContainerRegistryReadOnly

- **Access Control**:
  - EKS Access Entry: Grants cluster access to specified IAM principal
  - Access Policy: AmazonEKSClusterAdminPolicy for full cluster management

- **Kubernetes Resources**:
  - Creates `ingress-nginx` namespace automatically via Kubernetes provider

### 3. **IRSA (IAM Roles for Service Accounts)** - `irsa.tf`
- **OIDC Provider**: Creates OpenID Connect provider for EKS cluster
- **Purpose**: Allows Kubernetes service accounts to assume IAM roles
- **Configuration**: Via `irsa_roles` variable map
- **Use Cases**: 
  - AWS Load Balancer Controller
  - Other service accounts needing AWS permissions
- **Pattern**: Each IRSA role is scoped to a specific namespace and service account

### 4. **API Gateway** - `apigateway.tf`
- **Type**: HTTP API Gateway v2 (modern, cost-effective)
- **Authentication**: JWT authorizer using Cognito User Pool
- **Integration**: 
  - HTTP_PROXY to Network Load Balancer
  - NLB DNS name provided via `nlb_dns_name` variable
  - Updated by pipeline after Helm creates the NLB
- **VPC Link**: Connects API Gateway to private subnets via VPC Link
- **Route**: Catch-all route `ANY /{proxy+}` with JWT authorization

### 5. **Cognito** - `cognito.tf`
- **User Pool**: 
  - Name: `{project_name}-user-pool-{environment}`
  - Password Policy: 8+ chars, uppercase, lowercase, numbers, symbols
  - Username: Email-based
  - Auto-verification: Email verification enabled
  
- **App Client**: 
  - Public client (no secret)
  - Auth flows: User password, SRP, refresh token, admin user password
  
- **Domain**: Custom domain for hosted UI (if needed)

### 6. **Load Balancer** - `alb.tf`
- **Service-Linked Role**: Creates ELB service-linked role required for load balancers
- **Note**: The actual Network Load Balancer is created by AWS Load Balancer Controller (installed via Helm in pipeline)
- **Purpose**: This file ensures the prerequisite role exists

### 7. **Backend Configuration** - `backend.tf`
- **State Storage**: S3 bucket (`backend-awwad`)
- **State Locking**: DynamoDB table (`grad-proj-nti`)
- **Region**: eu-central-1
- **Encryption**: Enabled

## File Structure

```
terrafrom/
├── vpc.tf              # VPC, subnets, NAT, route tables
├── eks.tf              # EKS cluster, node groups, access entries
├── irsa.tf             # IAM Roles for Service Accounts
├── apigateway.tf       # HTTP API Gateway v2 with Cognito auth
├── cognito.tf          # Cognito User Pool and Client
├── alb.tf              # ELB service-linked role
├── providers.tf        # Terraform providers (AWS, Kubernetes, Helm, TLS)
├── var.tf              # Variable definitions
├── output.tf           # Output values
├── backend.tf          # S3 backend configuration
├── nonprod.tfvars      # Non-production environment variables
├── prod.tfvars         # Production environment variables
└── terraform.tfvars    # Default variables (if needed)
```

## Key Variables

### Common Variables
- `project_name`: Resource naming prefix
- `environment`: Deployment environment (nonprod/prod)
- `aws_region`: AWS region (eu-central-1)
- `vpc_cidr`: VPC CIDR block
- `cluster_version`: Kubernetes version
- `instance_type`: EC2 instance type for nodes
- `principal_arn`: IAM principal ARN for cluster access

### Environment-Specific (nonprod.tfvars / prod.tfvars)
- **Nonprod**: Smaller VPC (10.0.0.0/16), 1 node, t3.medium
- **Prod**: Larger VPC (10.1.0.0/16), 2 nodes, t3.medium

## Architecture Flow

1. **User Request** → API Gateway (HTTP API v2)
2. **Authentication** → Cognito JWT validation
3. **Authorization** → JWT authorizer validates token
4. **Routing** → VPC Link → Network Load Balancer (created by Helm)
5. **Load Balancing** → NLB routes to Kubernetes services
6. **Kubernetes** → Pods running in EKS cluster (private subnets)
7. **Response** → Reverse path back to user

## Security Features

1. **Network Isolation**: 
   - EKS nodes in private subnets
   - Only API Gateway and NAT Gateway in public subnets

2. **Authentication**: 
   - Cognito User Pool with strong password policy
   - JWT-based API authentication

3. **IAM**: 
   - Least privilege IAM roles
   - IRSA for service account permissions
   - EKS access entries for cluster access control

4. **Encryption**: 
   - Terraform state encrypted in S3
   - TLS for API Gateway

## Deployment Process

1. **Infrastructure**: Terraform applies infrastructure (VPC, EKS, Cognito, API Gateway)
2. **Kubernetes Setup**: Pipeline configures kubeconfig
3. **Helm Charts**: Pipeline installs:
   - Ingress NGINX Controller (creates NLB)
   - Nexus Repository Manager
   - SonarQube
   - ArgoCD
4. **API Gateway Update**: Pipeline updates API Gateway integration with NLB DNS name

## Differences from Previous Structure

1. **VPC**: Consolidated into single `vpc.tf` with data-driven subnet creation
2. **EKS**: Added access entries, cleaner structure, Kubernetes namespace creation
3. **API Gateway**: Changed from REST API to HTTP API v2 (modern, cheaper)
4. **Variables**: Simplified variable structure matching reference repo
5. **IRSA**: Separate file for IAM Roles for Service Accounts pattern
6. **Load Balancer**: NLB created by Helm, not Terraform (matches reference)

## Outputs

- `vpc_id`: VPC identifier
- `cluster_name`: EKS cluster name
- `cluster_endpoint`: EKS API endpoint
- `api_gateway_url`: API Gateway endpoint URL
- `cognito_user_pool_id`: Cognito User Pool ID
- `cognito_client_id`: Cognito App Client ID
- `eks_cluster_id`: EKS Cluster ID
- `eks_node_group_id`: EKS Node Group ID
- `eks_oidc_provider_arn`: OIDC Provider ARN for IRSA

## Next Steps

1. Update `principal_arn` in tfvars files with your IAM principal ARN
2. Configure `irsa_roles` variable if you need IRSA for service accounts
3. Run `terraform init` to initialize backend
4. Run `terraform plan -var-file=nonprod.tfvars` to review changes
5. Run `terraform apply -var-file=nonprod.tfvars` to deploy
6. After deployment, pipeline will install Helm charts and configure API Gateway

