variable "aws_region"     {}
variable "azs"            { type = list }

variable "environment"    {}
variable "product"        {}
variable "app"            {}
variable "name"           {}

variable "lb_name"        { default = "public" }

variable "hostname"       {}
variable "dns_zone"       {}

variable "ecs_cluster_name" { default = "fargate" }

variable "artifacts_bucket_name" {  default = "default" }

variable "github_repo_config" { type = "map" }
variable "github_oauth_token_name"  { default = "GitHub" }

variable "build_timeout"  { default = 30 }   # this is minutes

variable "container_name" { default = "service" }

variable "keep_n_last_images" {
  type = number
  default = 20
}

# -- global kind of stuff

terraform {
  backend "s3" {}
}

provider "aws" {
  version = "~> 2.0"
  region = "${var.aws_region}"
}
