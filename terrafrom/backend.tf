terraform {
  backend "s3" {
    bucket         = "backend-awwad"
    key            = "terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "grad-proj-nti"
    encrypt        = true
  }
}
