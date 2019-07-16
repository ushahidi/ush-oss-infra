variable "aws_region"     {}
variable "environment"    {}
variable "name"           {}

# -- init stuff

terraform {
  backend "s3" {}
}

provider "aws" {
  version = "~> 2.0"
  region = "${var.aws_region}"
}

# --

resource "aws_s3_bucket" "main" {
  bucket = "zzint-ush-${var.environment}-codepipeline-${var.name}"
  acl = "private"

  tags = {
    ush-environment = "${var.environment}"
    ush-purpose = "codepipeline-artifacts"
    ush-name = "${var.name}"
  }
}