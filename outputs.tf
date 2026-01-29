output "vpc_id" {
  value = aws_vpc.main_vpc.id
}

output "api_gateway_id" {
  value = aws_api_gateway_rest_api.main.id
}

output "api_gateway_url" {
  value = aws_api_gateway_stage.main.invoke_url
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

output "cognito_user_pool_domain" {
  value = aws_cognito_user_pool_domain.main.domain
}

output "cognito_identity_pool_id" {
  value = aws_cognito_identity_pool.main.id
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