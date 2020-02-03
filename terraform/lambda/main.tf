variable "workspace_profiles" {
  default = {
    staging    = "staging"
    production = "prod"
  }
}

terraform {
  backend "s3" {
    bucket               = "tf-state"
    key                  = "terraform.tfstate"
    workspace_key_prefix = "lambda"
    region               = "eu-west-1"
    profile              = ""
    acl                  = "bucket-owner-full-control"
  }
}

provider "aws" {
  region  = "eu-west-1"
  profile = "${var.workspace_profiles[terraform.workspace]}"
}

data "terraform_remote_state" "es" {
  backend = "s3"

  config {
    bucket = "tf-state"

    key     = "elasticsearch/${terraform.workspace}/terraform.tfstate"
    region  = "eu-west-1"
    profile = ""
  }
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
