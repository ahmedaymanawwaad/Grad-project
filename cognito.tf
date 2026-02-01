# Cognito User Pool
resource "aws_cognito_user_pool" "main" {
  name = "main-user-pool"

  auto_verified_attributes = ["email"]

  schema {
    name                = "email"
    attribute_data_type = "String"
    required            = true
    mutable             = true
  }

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
    require_uppercase = true
  }

  lifecycle {
    ignore_changes = [schema]
  }
}

# Cognito User Pool App Client
resource "aws_cognito_user_pool_client" "main" {
  name         = "main-app-client"
  user_pool_id = aws_cognito_user_pool.main.id

  # 🔑 REQUIRED
  generate_secret = true

  # 🔐 Auth flow for username/password → token
  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]

  prevent_user_existence_errors = "ENABLED"
}
