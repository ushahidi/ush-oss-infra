# --

data "aws_ecs_cluster" "cluster" {
  cluster_name = "${var.environment}-${var.ecs_cluster_name}"
}

resource "aws_security_group" "public_http_s" {
  name = "${var.environment}-${var.product}-${var.app}-${var.name}"
  description = "Allow HTTP and HTTPS to all addresses"
  vpc_id = data.aws_vpc.main.id

  ingress {
    from_port   = var.container_port
    to_port     = var.container_port
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_iam_role" "fargate" {
  name = "${var.environment}-${var.product}-${var.app}-${var.name}-fargate-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "fargate_to_registry" {
  name = "registry_policy"
  role = aws_iam_role.fargate.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "logs:CreateLogStream",
        "logs:CreateLogGroup",
        "logs:PutLogEvents"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage"
      ],
      "Resource": "${aws_ecr_repository.main.arn}"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "fargate_to_ssm" {
  name = "ssm_parameter_policy"
  role = aws_iam_role.fargate.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ssm:GetParameters",
        "ssm:GetParametersByPath"
      ],
      "Resource": [
        "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/${var.environment}/${var.product}/*"
      ]
    }
  ]
}
EOF
}

resource "aws_ecs_task_definition" "main" {
  family = "${var.environment}-${var.product}-${var.app}-${var.name}"
  cpu = 256
  memory = 512
  network_mode = "awsvpc"
  container_definitions = <<DEF
[
  {
    "essential": true,
    "name": "${var.container_name}",
    "image": "${aws_ecr_repository.main.repository_url}:latest",
    "portMappings": [
      {
        "containerPort": ${var.container_port},
        "hostPort": ${var.container_port},
        "protocol": "tcp"
      }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "/${var.environment}/${var.product}/${var.app}/${var.name}",
        "awslogs-region": "${var.aws_region}",
        "awslogs-stream-prefix": "[${var.container_name}]"
      }
    },
    "environment": ${jsonencode(var.container_environment)},
    "secrets": ${jsonencode(var.container_environment_secrets)}
  }
]
DEF

  requires_compatibilities = [ "FARGATE" ]

  task_role_arn = aws_iam_role.fargate.arn
  execution_role_arn = aws_iam_role.fargate.arn

  tags = {
    ush-environment = var.environment
    ush-product = var.product
    ush-app = var.app
  }

}

data "aws_subnet" "main" {
  count = length(var.azs)
  availability_zone = "${var.aws_region}${var.azs[count.index]}"
  tags = {
    ush-environment = var.environment
    ush-product = var.product
  }
}

resource "aws_ecs_service" "main" {
  name = "${var.environment}-${var.product}-${var.app}-${var.name}"
  cluster = data.aws_ecs_cluster.cluster.arn
  task_definition = aws_ecs_task_definition.main.arn
  desired_count = 1
  launch_type = "FARGATE"

  network_configuration {
    subnets = data.aws_subnet.main.*.id
    security_groups = [ aws_security_group.public_http_s.id ]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.main.arn
    container_name = var.container_name
    container_port = var.container_port
  }
}

# --

data "aws_vpc" "main" {
  tags = {
    ush-environment = var.environment
  }
}

data "aws_alb" "lb" {
  name = "${var.environment}-${var.lb_name}-alb"
}

data "aws_alb_listener" "https" {
  load_balancer_arn = data.aws_alb.lb.arn
  port = 443
}

data "aws_route53_zone" "main" {
  name = var.dns_zone
}

resource "aws_alb_target_group" "main" {
  name        = "${var.app}-${var.name}"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.main.id
  target_type = "ip"

  health_check {
    enabled   = true
    interval  = 10
    path = "/"
    port = "traffic-port"
    protocol = "HTTP"
  }

  tags = {
    ush-environment = var.environment
    ush-product = var.product
    ush-app = var.app
  }
}

resource "aws_alb_listener_certificate" "main" {
  listener_arn = data.aws_alb_listener.https.arn
  certificate_arn = module.acm.this_acm_certificate_arn
}

resource "aws_alb_listener_rule" "main" {
  listener_arn = data.aws_alb_listener.https.arn

  condition {
    field = "host-header"
    values = [ "${var.hostname}.${var.dns_zone}" ]
  }

  action {
    type = "forward"
    target_group_arn = aws_alb_target_group.main.arn
  }
}

module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> v2.0"

  domain_name  = "${var.hostname}.${var.dns_zone}"
  zone_id      = data.aws_route53_zone.main.zone_id

  wait_for_validation = true

  tags = {
    ush-environment = var.environment
    ush-product = var.product
    ush-app = var.app
  }
}

resource "aws_route53_record" "main" {
  zone_id = data.aws_route53_zone.main.zone_id
  name = "${var.hostname}.${var.dns_zone}"
  type = "A"

  alias {
    name = data.aws_alb.lb.dns_name
    zone_id = data.aws_alb.lb.zone_id
    evaluate_target_health = true
  }
}