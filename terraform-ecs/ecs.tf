############################################
# CloudWatch log group (nginx container logs)
############################################
resource "aws_cloudwatch_log_group" "nginx" {
  name              = "/ecs/${local.name}/nginx"
  retention_in_days = 7

  tags = {
    Terraform   = "true"
    Environment = local.env
  }
}

############################################
# ECS cluster
############################################
resource "aws_ecs_cluster" "this" {
  name = local.name

  tags = {
    Terraform   = "true"
    Environment = local.env
  }
}

############################################
# IAM role: lets ECS pull the image and write logs
############################################
data "aws_iam_policy_document" "ecs_tasks_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "task_execution" {
  name               = "${local.name}-task-execution"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume.json
}

resource "aws_iam_role_policy_attachment" "task_execution" {
  role       = aws_iam_role.task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

############################################
# Security groups
############################################
# ALB: allow HTTP from the internet
resource "aws_security_group" "alb" {
  name        = "${local.name}-alb-sg"
  description = "Allow HTTP from internet to ALB"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name}-alb-sg"
  }
}

# ECS tasks: allow HTTP only from the ALB
resource "aws_security_group" "ecs_service" {
  name        = "${local.name}-service-sg"
  description = "Allow HTTP from ALB to ECS tasks"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name}-service-sg"
  }
}

############################################
# Application Load Balancer (public)
############################################
resource "aws_lb" "this" {
  name               = "${local.name}-alb"
  load_balancer_type = "application"
  internal           = false
  security_groups    = [aws_security_group.alb.id]
  subnets            = module.vpc.public_subnets

  tags = {
    Terraform   = "true"
    Environment = local.env
  }
}

resource "aws_lb_target_group" "nginx" {
  name        = "${local.name}-nginx-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "ip" # required for Fargate (awsvpc networking)

  health_check {
    path                = "/"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

    default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

############################################
# Task definition: the nginx container
############################################
resource "aws_ecs_task_definition" "nginx" {
  family                   = "${local.name}-nginx"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.task_execution.arn

  container_definitions = jsonencode([
    {
      name      = "nginx"
      image     = "public.ecr.aws/nginx/nginx:stable"
      essential = true

      portMappings = [
        {
          containerPort = 80
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.nginx.name
          awslogs-region        = local.region
          awslogs-stream-prefix = "nginx"
        }
      }
    }
  ])

  tags = {
    Terraform   = "true"
    Environment = local.env
  }
}

############################################
# ECS service: keeps nginx running behind the ALB
############################################
resource "aws_ecs_service" "nginx" {
  name            = "nginx-service"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.nginx.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = module.vpc.private_subnets
    security_groups  = [aws_security_group.ecs_service.id]
    assign_public_ip = false # private subnets reach the internet through the NAT gateway
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.nginx.arn
    container_name   = "nginx"
    container_port   = 80
  }

  depends_on = [aws_lb_listener.https]

  tags = {
    Terraform   = "true"
    Environment = local.env
  }
}

############################################
# Output: open this URL in your browser
############################################
output "nginx_url" {
  description = "Open this in your browser to see the nginx welcome page"
  value       = "http://${aws_lb.this.dns_name}"
}



locals {
  domain_name = "cloudenvironment.online"
}

# Request a free certificate from ACM
resource "aws_acm_certificate" "nginx" {
  domain_name       = local.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# Terraform waits here until the certificate is validated
resource "aws_acm_certificate_validation" "nginx" {
  certificate_arn = aws_acm_certificate.nginx.arn
}

# Prints the DNS record you must add to prove you own the domain
output "acm_validation_records" {
  value = {
    for dvo in aws_acm_certificate.nginx.domain_validation_options :
    dvo.domain_name => {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  }
}

# HTTPS listener on port 443
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate_validation.nginx.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nginx.arn
  }
}