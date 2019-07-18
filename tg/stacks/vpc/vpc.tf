variable "aws_region"     {}
variable "azs"            { type = list }
variable "environment"    {}
variable "vpc_cidr"       {}

variable "base_private_dns_zone"  {}

locals {
  pub_subnets_base = cidrsubnet(var.vpc_cidr, 8, 254)   # /24
  prv_subnets_base = cidrsubnet(var.vpc_cidr, 8, 253)   # /24
}

terraform {
  backend "s3" {}
}

provider "aws" {
  version = "~> 2.0"
  region = "${var.aws_region}"
}

data "aws_security_group" "default" {
  name   = "default"
  vpc_id = module.vpc.vpc_id
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${var.environment}-vpc"
  cidr = var.vpc_cidr
  assign_generated_ipv6_cidr_block = true

  azs             = [ "${var.aws_region}${var.azs[0]}", "${var.aws_region}${var.azs[1]}"]
  public_subnets  = [
    cidrsubnet(local.pub_subnets_base, 1, 0),
    cidrsubnet(local.pub_subnets_base, 1, 1)
  ]
  private_subnets = [
    cidrsubnet(local.prv_subnets_base, 1, 0),
    cidrsubnet(local.prv_subnets_base, 1, 1)
  ]

  enable_dns_support = true
  enable_dns_hostnames = true

  enable_s3_endpoint = true

  enable_ssm_endpoint              = false
  # ssm_endpoint_private_dns_enabled = true
  # ssm_endpoint_security_group_ids  = [ data.aws_security_group.default.id ]

  enable_ec2_endpoint              = false
  # ec2_endpoint_private_dns_enabled = true
  # ec2_endpoint_security_group_ids  = [ data.aws_security_group.default.id ]

  enable_ecr_dkr_endpoint               = false
  # ecr_dkr_endpoint_private_dns_enabled  = true
  # ecr_dkr_endpoint_security_group_ids   = [ data.aws_security_group.default.id ]

  enable_logs_endpoint              = false
  # logs_endpoint_private_dns_enabled = true
  # logs_endpoint_security_group_ids  = [ data.aws_security_group.default.id ]

  enable_nat_gateway = true
  single_nat_gateway = true
  enable_vpn_gateway = false

  tags = {
    Terraform = "true"
    ush-environment = "${var.environment}"
  }

  private_route_table_tags = {
    network_type = "private"
  }

  private_subnet_tags = {
    network_type = "private"
  }

  public_route_table_tags = {
    network_type = "public"
  }

  public_subnet_tags = {
    network_type = "public"
  }
}


resource "aws_route53_zone" "main" {
  name = "${var.environment}.${var.base_private_dns_zone}"

  vpc {
    vpc_id = module.vpc.vpc_id
  }

  tags = {
    ush-environment = "${var.environment}"
  }
}

output "vpc" {
  value = module.vpc
}
