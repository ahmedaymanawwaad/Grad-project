# ===============================
# API Gateway REST API
# ===============================
resource "aws_api_gateway_rest_api" "main" {
  name = "main-api"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

# ===============================
# Catch-all proxy resource
# ===============================
resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "{proxy+}"
}

# ===============================
# Cognito Authorizer
# ===============================
resource "aws_api_gateway_authorizer" "cognito" {
  name            = "cognito-authorizer"
  rest_api_id     = aws_api_gateway_rest_api.main.id
  type            = "COGNITO_USER_POOLS"

  identity_source = "method.request.header.Authorization"
  provider_arns  = [aws_cognito_user_pool.main.arn]
}

# ===============================
# ANY Method (Protected)
# ===============================
resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "ANY"

  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id

  request_parameters = {
    "method.request.path.proxy" = true
  }
}

# ===============================
# VPC Link for NLB
# ===============================
resource "aws_api_gateway_vpc_link" "nlb" {
  name        = "${var.eks_cluster_name}-nlb-vpc-link"
  target_arns = [aws_lb.my_nlb.arn]
  description = "VPC link for the NLB"
  
  tags = {
    Name = "${var.eks_cluster_name}-nlb-vpc-link"
  }
}

# ===============================
# HTTP Integration → NLB via VPC Link
# ===============================
resource "aws_api_gateway_integration" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.proxy.http_method

  type                    = "HTTP_PROXY"
  integration_http_method = "ANY"
  connection_type         = "VPC_LINK"
  connection_id           = aws_api_gateway_vpc_link.nlb.id

  uri = "http://${aws_lb.my_nlb.dns_name}/{proxy}"

  request_parameters = {
    "integration.request.path.proxy" = "method.request.path.proxy"
  }
}

# ===============================
# Deployment
# ===============================
resource "aws_api_gateway_deployment" "main" {
  rest_api_id = aws_api_gateway_rest_api.main.id

  depends_on = [
    aws_api_gateway_method.proxy,
    aws_api_gateway_integration.proxy
  ]

  lifecycle {
    create_before_destroy = true
  }
}

# ===============================
# Stage
# ===============================
resource "aws_api_gateway_stage" "prod" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  deployment_id = aws_api_gateway_deployment.main.id
  stage_name    = "prod"
}
