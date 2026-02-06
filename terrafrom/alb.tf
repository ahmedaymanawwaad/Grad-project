# ==============================================================================
# Elastic Load Balancing Service-Linked Role
# ==============================================================================
# AWS requires this service-linked role to exist before creating load balancers.
# When creating via console, AWS creates it automatically, but Terraform needs it explicitly.
# Note: If the role already exists (created via console), you may need to import it:


# Note: The Network Load Balancer (NLB) is created by the AWS Load Balancer Controller
# which is installed via Helm in the pipeline. The NLB DNS name is then updated
# in the API Gateway integration via the pipeline using sed.
