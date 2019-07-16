terraform {
  source = "../../../stacks//public-alb"
}

include {
  path = "${find_in_parent_folders()}"
}

inputs = {
  name = "public"
  default_hostname = "public-dev-alb"
  default_hostname_zone = "oss.ush.zone"
}
