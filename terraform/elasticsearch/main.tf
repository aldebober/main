variable "workspace_profiles" {
  default = {
    staging    = "stage"
    production = "prod"
  }
}

terraform {
  backend "s3" {
    bucket               = "tf-state"
    key                  = "terraform.tfstate"
    workspace_key_prefix = "elasticsearch"
    region               = "eu-west-1"
    profile              = ""
    acl                  = "bucket-owner-full-control"
  }
}

provider "aws" {
  region  = "eu-west-1"
  profile = "${var.workspace_profiles[terraform.workspace]}"
}

# BUG: https://github.com/hashicorp/terraform/issues/17153
data "terraform_remote_state" "vpc" {
  backend = "s3"

  config {
    bucket = "tf-state"

    key     = "networking/${terraform.workspace}/terraform.tfstate"
    region  = "eu-west-1"
    profile = ""
  }
}

variable "hostname" {
  default = {
    staging    = "some.com"
    production = "some.com"
  }
}

data "aws_route53_zone" "zone" {
  name         = "${var.hostname[terraform.workspace]}."
  private_zone = false
}
