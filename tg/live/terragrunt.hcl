remote_state {
  backend = "s3"
  config = {
    bucket = "ush-oss-terraform-states"
    key = "${path_relative_to_include()}/terraform.tfstate"
    encrypt = true
    dynamodb_table = "ush-oss-terraform-states-lock"
    region = "eu-west-1"
  }
}

terraform {
  extra_arguments "common_vars" {
    commands = get_terraform_commands_that_need_vars()
    required_var_files = [
      "${get_parent_terragrunt_dir()}/common.tfvars"
    ]
    optional_var_files = [
      "${get_terragrunt_dir()}/../env.tfvars",
      "${get_terragrunt_dir()}/../../env.tfvars",
      "${get_terragrunt_dir()}/../../../env.tfvars",
      "${get_terragrunt_dir()}/../product.tfvars",
      "${get_terragrunt_dir()}/../../product.tfvars",
      "${get_terragrunt_dir()}/../app.tfvars",
      "${get_terragrunt_dir()}/terraform.tfvars"
    ]
  }
}
