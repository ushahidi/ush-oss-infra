variable "aws_region"     {}
variable "azs"            { type = list }

variable "environment"    {}
variable "product"        {}

variable "subnet_bits"    {
  type = number
  default = 8
}
variable "subnet_start_idx" {
  type = number
  default = 0
}

terraform {
  backend "s3" {}
}

provider "aws" {
  version = "~> 2.0"
  region = "${var.aws_region}"
}

data "aws_vpc" "main" {
  tags = {
    ush-environment = var.environment
  }
}

data "aws_route_table" "main" {
  vpc_id = data.aws_vpc.main.id
  tags = {
    network_type = "private"
  }
}

resource "aws_subnet" "main" {
  count = length(var.azs)
  vpc_id = data.aws_vpc.main.id
  availability_zone = "${var.aws_region}${var.azs[count.index]}"
  cidr_block = cidrsubnet(data.aws_vpc.main.cidr_block, var.subnet_bits, var.subnet_start_idx + count.index)
  ipv6_cidr_block = cidrsubnet(data.aws_vpc.main.ipv6_cidr_block, 8, var.subnet_start_idx + count.index)
  
  tags = {
    ush-environment = var.environment
    ush-product = var.product
  }
}

resource "aws_route_table_association" "main" {
  count = length(var.azs)
  subnet_id = aws_subnet.main[count.index].id
  route_table_id = data.aws_route_table.main.id
}
