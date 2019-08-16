variable "aws_region"     {}
variable "azs"            { type = list }

variable "environment"    {}
variable "product"        {}
variable "app"            {}

variable "cache_instance_type" { default = "cache.t2.micro" }
variable "redis_version"       { default = "3.2" }
variable "redis_minor_version" { default = "3.2.10" }
variable "cache_apply_immediately" { default = "true" }

# -- global kind of stuff

terraform {
  backend "s3" {}
}

provider "aws" {
  version = "~> 2.0"
  region = "${var.aws_region}"
}

# -- global lookups

data "aws_vpc" "main" {
  tags = {
    ush-environment = var.environment
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