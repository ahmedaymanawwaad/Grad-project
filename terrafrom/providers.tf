terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Note: Kubernetes and Helm providers are not included here because:
# 1. Kubernetes resources (namespaces, etc.) are created by Helm charts in the pipeline
# 2. The Kubernetes provider requires kubeconfig to be configured, which happens after Terraform apply
# 3. This avoids connection errors during Terraform plan/apply phases

