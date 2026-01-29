terraform {
  backend "s3" {
    bucket         = "grad-proj-nti"       
    key            = "terraform.tfstate"   
    region         = "us-east-1"           
    dynamodb_table = "grad-proj-nti"       
    encrypt        = true                 
  }
}
