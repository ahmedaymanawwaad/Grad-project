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

output "aws_load_balancer_controller_role_arn" {
  description = "IAM role ARN for AWS Load Balancer Controller"
  value       = aws_iam_role.aws_load_balancer_controller.arn
}

output "eks_oidc_provider_arn" {
  description = "ARN of the EKS OIDC Provider"
  value       = aws_iam_openid_connect_provider.eks.arn
}
output "api_gateway_url" {
  value = aws_api_gateway_stage.prod.invoke_url
}
output "api_gateway_vpc_link_id" {
  value = aws_api_gateway_vpc_link.nlb.id
}
output "nlb_arn" {
  description = "ARN of the Network Load Balancer"
  value       = aws_lb.my_nlb.arn
}

output "nlb_dns_name" {
  description = "DNS name of the Network Load Balancer"
  value       = aws_lb.my_nlb.dns_name
}

output "nlb_target_group_arn" {
  description = "ARN of the Network Load Balancer target group"
  value       = aws_lb_target_group.nlb_target_group.arn
}

output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = aws_eks_cluster.main.name
}