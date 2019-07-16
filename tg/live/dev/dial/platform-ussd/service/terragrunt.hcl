terraform {
  source = "../../../../../stacks//codepipeline-fargate"
}
include {
  path = "${find_in_parent_folders()}"
}

inputs = {
  name = "service"
  hostname = "platform-ussd-dev"
  dns_zone = "oss.ush.zone"
  github_repo_config = {
    Owner  = "ushahidi"
    Repo   = "platform-api-ussd-service"
    Branch = "master"
  }
}