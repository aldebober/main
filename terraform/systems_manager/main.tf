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
    workspace_key_prefix = "systems_manager"
    region               = "eu-west-1"
    profile              = ""
    acl                  = "bucket-owner-full-control"
  }
}

provider "aws" {
  version = "~> 2.0"
  region  = "eu-west-1"
  profile = "${var.workspace_profiles[terraform.workspace]}"
}

data "aws_region" "current" {}
