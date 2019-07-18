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
  # github_oauthtoken -> create in secrets.tfvars

  container_port = "8080"
  container_environment = [
    {
      name = "PLATFORM_API",
      value = "https://ussd.api.ushahidi.io"
    },
    {
      name = "PLATFORM_EMAIL",
      value = "admin@ushahidi.com"
    }
  ]
  container_environment_secrets = [
    {
      name = "PLATFORM_PASSWORD",
      valueFrom = "arn:aws:ssm:eu-west-1:189125372384:parameter/dev/dial/platform-ussd/service/secrets/PLATFORM_PASSWORD"
    }
  ]
}
