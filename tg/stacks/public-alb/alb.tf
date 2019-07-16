variable "aws_region"     {}
variable "azs"            { type = list }
variable "environment"    {}

variable "name"           {}

variable "default_hostname"         {}
variable "default_hostname_zone"    {}
# --

terraform {
  backend "s3" {}
}

provider "aws" {
  version = "~> 2.0"
  region = "${var.aws_region}"
}

# --

data "aws_vpc" "main" {
  tags = {
    ush-environment = var.environment
  }
}

data "aws_subnet" "public" {
  count = length(var.azs)
  vpc_id = data.aws_vpc.main.id
  availability_zone = "${var.aws_region}${var.azs[count.index]}"
  tags = {
    network_type = "public"
  }
}

resource "aws_security_group" "public_http_s" {
  name = "allow_http_s_publicly"
  description = "Allow HTTP and HTTPS to all addresses"
  vpc_id = data.aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
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

module "alb" {
  source  = "terraform-aws-modules/alb/aws"

  load_balancer_name            = "${var.environment}-${var.name}-alb"
  security_groups               = [ aws_security_group.public_http_s.id ]
  subnets                       = data.aws_subnet.public.*.id
  vpc_id                        = data.aws_vpc.main.id

  enable_http2                  = true
  ip_address_type               = "dualstack"
  load_balancer_is_internal     = false
  enable_cross_zone_load_balancing = true
  logging_enabled               = false

  tags = {
    ush-environment = var.environment
  }
}


resource "aws_lb_listener" "http" {
  load_balancer_arn = module.alb.load_balancer_id
  port = "80"
  protocol = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      status_code = "HTTP_301"
      protocol = "HTTPS"
    }
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = module.alb.load_balancer_id
  port = "443"
  protocol = "HTTPS"
  certificate_arn = module.acm.this_acm_certificate_arn

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "OK"
      status_code = "200"
    }
  }
}

# --

data "aws_route53_zone" "default" {
  name = var.default_hostname_zone
  private_zone = false
}

module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> v2.0"

  domain_name  = "${var.default_hostname}.${var.default_hostname_zone}"
  zone_id      = data.aws_route53_zone.default.zone_id

  tags = {
    ush-environment = var.environment
  }
}

resource "aws_route53_record" "default" {
  zone_id = data.aws_route53_zone.default.zone_id
  name = var.default_hostname
  type = "A"

  alias {
    name = module.alb.dns_name
    zone_id = module.alb.load_balancer_zone_id
    evaluate_target_health = true
  }
}