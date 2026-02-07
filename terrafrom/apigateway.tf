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
# IMPORTANT: VPC Link creates ENIs in the subnets. It MUST be destroyed
# before subnets can be deleted. The implicit dependency via subnet_ids
# ensures Terraform destroys the VPC Link first, but ENI cleanup can take time.
resource "aws_apigatewayv2_vpc_link" "main" {
  count              = var.enable_nlb ? 1 : 0
  name               = "${var.project_name}-vpc-link"
  security_group_ids = [aws_security_group.vpc_link.id]
  subnet_ids         = aws_subnet.private[*].id

  tags = {
    Project = var.project_name
  }

  # VPC Link ENI cleanup can take time
  timeouts {
    delete = "20m"
  }
}

# Dedicated Security Group for VPC Link
# Using a dedicated SG makes it easier to identify and clean up ENIs
resource "aws_security_group" "vpc_link" {
  name        = "${var.project_name}-vpc-link-sg"
  description = "Security group for API Gateway VPC Link"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name}-vpc-link-sg"
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
