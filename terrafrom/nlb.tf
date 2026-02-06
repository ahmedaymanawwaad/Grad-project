# Service-Linked Role for ELB
resource "aws_iam_service_linked_role" "elb" {
  aws_service_name = "elasticloadbalancing.amazonaws.com"
  description      = "Service-linked role for Elastic Load Balancing"
}

# Network Load Balancer (Minimal Configuration)
resource "aws_lb" "nlb" {
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
  load_balancer_arn = aws_lb.nlb.arn
  port              = "80"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nlb_tg.arn
  }
}

