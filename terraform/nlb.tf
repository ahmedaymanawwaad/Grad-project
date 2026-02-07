# Service-Linked Role for ELB
# Note: This role may already exist in your AWS account. If so, import it:
# terraform import aws_iam_service_linked_role.elb arn:aws:iam::ACCOUNT_ID:role/aws-service-role/elasticloadbalancing.amazonaws.com/AWSServiceRoleForElasticLoadBalancing
resource "aws_iam_service_linked_role" "elb" {
  count            = var.enable_nlb ? 1 : 0
  aws_service_name = "elasticloadbalancing.amazonaws.com"
  description      = "Service-linked role for Elastic Load Balancing"

  lifecycle {
    ignore_changes = [description]
  }
}

# Network Load Balancer (Minimal Configuration)
resource "aws_lb" "nlb" {
  count              = var.enable_nlb ? 1 : 0
  name               = "${var.project_name}-nlb"
  internal           = false
  load_balancer_type = "network"
  subnets            = aws_subnet.public[*].id

  enable_cross_zone_load_balancing = true

  depends_on = [aws_iam_service_linked_role.elb]

  tags = {
    Name    = "${var.project_name}-nlb"
    Project = var.project_name
  }
}

# Target Group for NLB
resource "aws_lb_target_group" "nlb_tg" {
  count    = var.enable_nlb ? 1 : 0
  name     = "${var.project_name}-nlb-tg"
  port     = 80
  protocol = "TCP"
  vpc_id   = aws_vpc.main.id

  health_check {
    protocol = "TCP"
    port     = 80
  }

  tags = {
    Name    = "${var.project_name}-nlb-tg"
    Project = var.project_name
  }
}

# NLB Listener
resource "aws_lb_listener" "nlb_listener" {
  count             = var.enable_nlb ? 1 : 0
  load_balancer_arn = aws_lb.nlb[0].arn
  port              = "80"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nlb_tg[0].arn
  }
}
