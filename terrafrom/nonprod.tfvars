# ==============================================================================
# EKS Cluster Configuration - Non-Production Environment
# ==============================================================================

# Cluster name
eks_cluster_name = "my-eks-cluster-nonprod"

# Kubernetes version (must be compatible with AMI type - AL2023 supports 1.27+)
eks_cluster_version = "1.35"

# API endpoint access configuration
eks_endpoint_private_access = true
eks_endpoint_public_access  = true

# ==============================================================================
# IAM Role Names
# ==============================================================================

eks_cluster_role_name = "eks-cluster-role-nonprod"
eks_node_role_name    = "eks-node-role-nonprod"
eks_fargate_role_name = "eks-fargate-pod-execution-role-nonprod"

# ==============================================================================
# IAM Policy ARNs (AWS Managed Policies)
# ==============================================================================

eks_cluster_policy_arn                        = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
eks_worker_node_policy_arn                    = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
eks_cni_policy_arn                           = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
eks_container_registry_policy_arn             = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
eks_fargate_pod_execution_role_policy_arn     = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"

# ==============================================================================
# Node Group Configuration
# ==============================================================================

# Node group name
eks_node_group_name = "main-node-group-nonprod"

# Instance types (can specify multiple for mixed instance types)
eks_node_instance_types = ["t2.micro"]

# AMI type - Options: AL2023_x86_64_STANDARD, AL2023_ARM_64_STANDARD, AL2_x86_64, AL2_ARM_64, BOTTLEROCKET_x86_64, etc.
eks_node_ami_type = "AL2023_x86_64_STANDARD"

# Scaling configuration
eks_node_desired_size = 1
eks_node_min_size     = 1
eks_node_max_size     = 2

# Update configuration
eks_node_max_unavailable = 1

# Disk size in GiB
eks_node_disk_size = 20

# ==============================================================================
# Fargate Profile Configuration
# ==============================================================================

# Fargate profile name
eks_fargate_profile_name = "fargate-profile-nonprod"

# Fargate selectors - defines which pods run on Fargate
# Pods matching these selectors will run on Fargate instead of EC2 nodes
eks_fargate_selectors = [
  {
    namespace = "fargate"
    labels    = {}
  },
  {
    namespace = "default"
    labels = {
      workload = "fargate"
    }
  }
]

# ==============================================================================
# AWS Load Balancer Controller Configuration
# ==============================================================================

# Kubernetes namespace for AWS Load Balancer Controller
aws_load_balancer_controller_namespace = "kube-system"

# Kubernetes service account name for AWS Load Balancer Controller
aws_load_balancer_controller_service_account_name = "aws-load-balancer-controller"

