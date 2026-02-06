# HTTP API Gateway v2 (Minimal Configuration)
resource "aws_apigatewayv2_api" "main" {
  name          = "${var.project_name}-api-${var.environment}"
  protocol_type = "HTTP"

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

# Default Stage
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.main.id
  name        = "$default"
  auto_deploy = true
}

# VPC Link to connect API Gateway to NLB (only when NLB is enabled)
resource "aws_apigatewayv2_vpc_link" "main" {
  count              = var.enable_nlb ? 1 : 0
  name               = "${var.project_name}-vpc-link"
  security_group_ids = [aws_eks_cluster.main.vpc_config[0].cluster_security_group_id]
  subnet_ids         = aws_subnet.private[*].id

  tags = {
    Project = var.project_name
  }
}

# JWT Authorizer using Cognito
resource "aws_apigatewayv2_authorizer" "jwt" {
  api_id           = aws_apigatewayv2_api.main.id
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]
  name             = "CognitoJWT"

  jwt_configuration {
    audience = [aws_cognito_user_pool_client.client.id]
    issuer   = "https://cognito-idp.${var.aws_region}.amazonaws.com/${aws_cognito_user_pool.main.id}"
  }
}

# Integration with NLB via VPC Link (only when NLB is enabled)
resource "aws_apigatewayv2_integration" "nlb" {
  count            = var.enable_nlb ? 1 : 0
  api_id           = aws_apigatewayv2_api.main.id
  integration_type = "HTTP_PROXY"

  integration_uri    = "http://${aws_lb.nlb[0].dns_name}"
  integration_method = "ANY"
  connection_type    = "VPC_LINK"
  connection_id      = aws_apigatewayv2_vpc_link.main[0].id
}

# Route with JWT Authorization (only when NLB is enabled)
resource "aws_apigatewayv2_route" "default" {
  count     = var.enable_nlb ? 1 : 0
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "ANY /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.nlb[0].id}"

  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.jwt.id
}
