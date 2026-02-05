// IAM Role for EKS Cluster
resource "aws_iam_role" "eks_cluster_role" {
  name = var.eks_cluster_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
  })
}
// Attach EKS Cluster Policy to EKS Cluster Role
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = var.eks_cluster_policy_arn
  role       = aws_iam_role.eks_cluster_role.name
}
// IAM Role for EKS Node
resource "aws_iam_role" "eks_node_role" {
  name = var.eks_node_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  tags = {
    Name = "eks-node-role"
  }
}
// Attach EKS Worker Node Policy to EKS Node Role
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = var.eks_worker_node_policy_arn
  role       = aws_iam_role.eks_node_role.name
}
// Attach EKS CNI Policy to EKS Node Role
//CNI -> container network interface
resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = var.eks_cni_policy_arn
  role       = aws_iam_role.eks_node_role.name
}
// Attach EKS Container Registry Policy to EKS Node Role
resource "aws_iam_role_policy_attachment" "eks_container_registry_policy" {
  policy_arn = var.eks_container_registry_policy_arn
  role       = aws_iam_role.eks_node_role.name
}
