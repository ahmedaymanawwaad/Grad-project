# EKS Cluster Variables
variable "eks_cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "my-eks-cluster"
}

variable "eks_cluster_version" {
  description = "Kubernetes version for the EKS cluster. Must be compatible with the selected AMI type (AL2023 supports EKS 1.27+)"
  type        = string
  default     = "1.35"
}

variable "eks_endpoint_private_access" {
  description = "Enable private API server endpoint"
  type        = bool
  default     = true
}

variable "eks_endpoint_public_access" {
  description = "Enable public API server endpoint"
  type        = bool
  default     = true
}

# IAM Role Names
variable "eks_cluster_role_name" {
  description = "Name of the EKS cluster IAM role"
  type        = string
  default     = "eks-cluster-role"
}

variable "eks_node_role_name" {
  description = "Name of the EKS node group IAM role"
  type        = string
  default     = "eks-node-role"
}

variable "eks_fargate_role_name" {
  description = "Name of the EKS Fargate pod execution IAM role"
  type        = string
  default     = "eks-fargate-pod-execution-role"
}

# IAM Policy ARNs
variable "eks_cluster_policy_arn" {
  description = "ARN of the EKS cluster policy"
  type        = string
  default     = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

variable "eks_worker_node_policy_arn" {
  description = "ARN of the EKS worker node policy"
  type        = string
  default     = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

variable "eks_cni_policy_arn" {
  description = "ARN of the EKS CNI policy"
  type        = string
  default     = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

variable "eks_container_registry_policy_arn" {
  description = "ARN of the ECR read-only policy"
  type        = string
  default     = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

variable "eks_fargate_pod_execution_role_policy_arn" {
  description = "ARN of the EKS Fargate pod execution role policy"
  type        = string
  default     = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
}

# Node Group Variables
variable "eks_node_group_name" {
  description = "Name of the EKS node group"
  type        = string
  default     = "main-node-group"
}

variable "eks_node_instance_types" {
  description = "Instance types for the EKS node group"
  type        = list(string)
  default     = ["t2.micro"]
}

variable "eks_node_ami_type" {
  description = "AMI type for the EKS node group"
  type        = string
  default     = "AL2023_x86_64_STANDARD"
}

variable "eks_node_desired_size" {
  description = "Desired number of nodes in the node group"
  type        = number
  default     = 1
}

variable "eks_node_min_size" {
  description = "Minimum number of nodes in the node group"
  type        = number
  default     = 1
}

variable "eks_node_max_size" {
  description = "Maximum number of nodes in the node group"
  type        = number
  default     = 4
}

variable "eks_node_max_unavailable" {
  description = "Maximum number of unavailable nodes during update"
  type        = number
  default     = 1
}

variable "eks_node_disk_size" {
  description = "Disk size in GiB for worker nodes"
  type        = number
  default     = 20
}

# Fargate Profile Variables
variable "eks_fargate_profile_name" {
  description = "Name of the EKS Fargate profile"
  type        = string
  default     = "fargate-profile"
}

variable "eks_fargate_selectors" {
  description = "List of selectors for Fargate profile. Each selector can have namespace and optional labels"
  type = list(object({
    namespace = string
    labels    = optional(map(string), {})
  }))
  default = [
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
}

# AWS Load Balancer Controller Variables
variable "aws_load_balancer_controller_namespace" {
  description = "Kubernetes namespace for AWS Load Balancer Controller"
  type        = string
  default     = "kube-system"
}

variable "aws_load_balancer_controller_service_account_name" {
  description = "Kubernetes service account name for AWS Load Balancer Controller"
  type        = string
  default     = "aws-load-balancer-controller"
}

