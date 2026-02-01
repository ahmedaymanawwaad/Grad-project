output "vpc_id" {
  value = aws_vpc.main_vpc.id
}

output "api_gateway_id" {
  value = aws_api_gateway_rest_api.main.id
}



output "api_gateway_arn" {
  value = aws_api_gateway_rest_api.main.arn
}

output "cognito_user_pool_id" {
  value = aws_cognito_user_pool.main.id
}

output "cognito_user_pool_client_id" {
  value = aws_cognito_user_pool_client.main.id
}




output "eks_cluster_id" {
  value = aws_eks_cluster.main.id
}

output "eks_cluster_endpoint" {
  value = aws_eks_cluster.main.endpoint
}

output "eks_node_group_id" {
  value = aws_eks_node_group.main.id
}

output "eks_node_group_arn" {
  value = aws_eks_node_group.main.arn
}

output "eks_node_group_status" {
  value = aws_eks_node_group.main.status
}

output "alb_security_group_id" {
  description = "Security group ID for the Application Load Balancer"
  value       = aws_security_group.alb.id
}

output "aws_load_balancer_controller_role_arn" {
  description = "IAM role ARN for AWS Load Balancer Controller"
  value       = aws_iam_role.aws_load_balancer_controller.arn
}

output "eks_oidc_provider_arn" {
  description = "ARN of the EKS OIDC Provider"
  value       = aws_iam_openid_connect_provider.eks.arn
}