variable "aws_region"   {}

variable "environment"  {}
variable "name"         {}

terraform {
  backend "s3" {}
}

provider "aws" {
  version = "~> 2.0"
  region = "${var.aws_region}"
}

resource "aws_ecs_cluster" "main" {
  name = "${var.environment}-${var.name}"

  tags = {
    ush-environment = var.environment
  }
}
