


// Create EKS Cluster
resource "aws_eks_cluster" "main" {
  name     = var.eks_cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = var.eks_cluster_version

  vpc_config {
    subnet_ids = [
      aws_subnet.private_subnet-1.id,
      aws_subnet.private_subnet-2.id,
      aws_subnet.public_subnet-1.id,
      aws_subnet.public_subnet-2.id
    ]

    endpoint_private_access = var.eks_endpoint_private_access
    endpoint_public_access  = var.eks_endpoint_public_access
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]

  tags = {
    Name = var.eks_cluster_name
  }
}

# EKS Node Group
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = var.eks_node_group_name
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = [aws_subnet.private_subnet-1.id, aws_subnet.private_subnet-2.id]

  # Instance configuration
  instance_types = var.eks_node_instance_types

  ami_type = var.eks_node_ami_type

  disk_size = var.eks_node_disk_size

  scaling_config {
    desired_size = var.eks_node_desired_size
    max_size     = var.eks_node_max_size
    min_size     = var.eks_node_min_size
  }

  # Update configuration
  update_config {
    max_unavailable = var.eks_node_max_unavailable
  }



  # Ensure IAM role is ready before creating node group
  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_container_registry_policy,
  ]

  tags = {
    Name = var.eks_node_group_name
  }
}

# Fargate Profile
resource "aws_eks_fargate_profile" "main" {
  cluster_name           = aws_eks_cluster.main.name
  fargate_profile_name   = var.eks_fargate_profile_name
  pod_execution_role_arn = aws_iam_role.eks_fargate_role.arn

  subnet_ids = [
    aws_subnet.private_subnet-1.id,
    aws_subnet.private_subnet-2.id
  ]

  dynamic "selector" {
    for_each = var.eks_fargate_selectors
    content {
      namespace = selector.value.namespace
      labels    = selector.value.labels
    }
  }

  tags = {
    Name = var.eks_fargate_profile_name
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_fargate_pod_execution_role_policy
  ]
}

