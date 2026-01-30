# Cognito User Pool
resource "aws_cognito_user_pool" "main" {
  name = "main-user-pool"

  # Password policy
  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
    require_uppercase = true
  }

  # User attributes
  schema {
    name                = "email"
    attribute_data_type = "String"
    required            = true
    mutable             = true
  }

  schema {
    name                = "name"
    attribute_data_type = "String"
    required            = true
    mutable             = true
  }

  # Email configuration
  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }

  # Auto-verify email
  auto_verified_attributes = ["email"]

  # MFA configuration - set to OFF to avoid configuration errors
  mfa_configuration = "OFF"

  # Account recovery
  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  tags = {
    Name = "main-user-pool"
  }

  # Ignore schema changes after creation (Cognito doesn't allow schema modifications)
  lifecycle {
    ignore_changes = [schema]
  }
}

# Cognito User Pool Client
resource "aws_cognito_user_pool_client" "main" {
  name         = "main-user-pool-client"
  user_pool_id = aws_cognito_user_pool.main.id

  # Authentication flows
  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH"
  ]

  # Token validity (values are in minutes)
  # Note: These are optional - Cognito will use defaults if not specified
  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "days"
  }

  access_token_validity  = 60 # 60 minutes
  id_token_validity      = 60 # 60 minutes  
  refresh_token_validity = 30 # 30 days

  # Prevent user existence errors
  prevent_user_existence_errors = "ENABLED"

  # Supported identity providers
  supported_identity_providers = ["COGNITO"]

  callback_urls = [
     "https://<API_GATEWAY_ID>.execute-api.<REGION>.amazonaws.com/prod/callback"
  ]

  # Logout URLs
  logout_urls = [
  
       "https://<API_GATEWAY_ID>.execute-api.<REGION>.amazonaws.com/prod/logout"

  ]

  # OAuth scopes
  allowed_oauth_scopes = [
    "email",
    "openid",
    "profile"
  ]

  # OAuth flows
  allowed_oauth_flows = [
    "code",
    "implicit"
  ]
  allowed_oauth_flows_user_pool_client = true
}

# Cognito User Pool Domain
resource "aws_cognito_user_pool_domain" "main" {
  domain       = "main-user-pool-${random_id.domain_suffix.hex}"
  user_pool_id = aws_cognito_user_pool.main.id
}

# Random ID for domain uniqueness
resource "random_id" "domain_suffix" {
  byte_length = 4
}

# Cognito Identity Pool (for AWS credentials)
resource "aws_cognito_identity_pool" "main" {
  identity_pool_name               = "main_identity_pool"
  allow_unauthenticated_identities = false

  cognito_identity_providers {
    client_id               = aws_cognito_user_pool_client.main.id
    provider_name           = aws_cognito_user_pool.main.endpoint
    server_side_token_check = false
  }

  tags = {
    Name = "main-identity-pool"
  }
}

# IAM Role for authenticated users
resource "aws_iam_role" "cognito_authenticated" {
  name = "cognito-authenticated-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "cognito-identity.amazonaws.com"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "cognito-identity.amazonaws.com:aud" = aws_cognito_identity_pool.main.id
          }
          "ForAnyValue:StringLike" = {
            "cognito-identity.amazonaws.com:amr" = "authenticated"
          }
        }
      }
    ]
  })

  tags = {
    Name = "cognito-authenticated-role"
  }
}

# IAM Role attachment for authenticated users
resource "aws_cognito_identity_pool_roles_attachment" "main" {
  identity_pool_id = aws_cognito_identity_pool.main.id

  roles = {
    "authenticated" = aws_iam_role.cognito_authenticated.arn
  }
}

# IAM Policy for authenticated users (example - can invoke API Gateway)
resource "aws_iam_role_policy" "cognito_authenticated" {
  name = "cognito-authenticated-policy"
  role = aws_iam_role.cognito_authenticated.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "execute-api:Invoke"
        ]
        Resource = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
      }
    ]
  })
}

