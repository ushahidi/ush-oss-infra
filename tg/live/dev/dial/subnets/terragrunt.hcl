terraform {
  source = "../../../../stacks//product-subnets"
}
include {
  path = "${find_in_parent_folders()}"
}

inputs = {
  subnet_start_idx = 16
}
