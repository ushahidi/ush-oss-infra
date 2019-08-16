terraform {
  source = "../../../../../stacks//redis"
}
include {
  path = "${find_in_parent_folders()}"
}

inputs = {
}
