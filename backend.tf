terraform {
  backend "s3" {
    bucket         = "grad-proj-nti"       # S3 bucket name
    key            = "terraform.tfstate"   # path inside the bucket for state
    region         = "us-east-1"           # region of the bucket
    dynamodb_table = "grad-proj-nti"       # DynamoDB table for state locking
    encrypt        = true                  # enable encryption
  }
}
