terraform {
  source = "../../../stacks//vpc"
}
include {
  path = "${find_in_parent_folders()}"
}

inputs = {
  vpc_cidr = "10.128.0.0/16"
  base_private_dns_zone = "oss.aws.infra"
}