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
    workspace_key_prefix = "networking"
    region               = "eu-west-1"
    profile              = ""
    acl                  = "bucket-owner-full-control"
  }
}

provider "aws" {
  region  = "eu-west-1"
  profile = "${var.workspace_profiles[terraform.workspace]}"
}
