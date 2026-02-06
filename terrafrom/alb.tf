# ==============================================================================
# Elastic Load Balancing Service-Linked Role
# ==============================================================================
# AWS requires this service-linked role to exist before creating load balancers.
# When creating via console, AWS creates it automatically, but Terraform needs it explicitly.
# Note: If the role already exists (created via console), you may need to import it:
# terraform import aws_iam_service_linked_role.elb arn:aws:iam::ACCOUNT_ID:role/aws-service-role/elasticloadbalancing.amazonaws.com/AWSServiceRoleForElasticLoadBalancing

resource "aws_iam_service_linked_role" "elb" {
  aws_service_name = "elasticloadbalancing.amazonaws.com"

  description = "Service-linked role for Elastic Load Balancing"
}

# Note: The Network Load Balancer (NLB) is created by the AWS Load Balancer Controller
# which is installed via Helm in the pipeline. The NLB DNS name is then updated
# in the API Gateway integration via the pipeline using sed.
