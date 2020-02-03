variable "workspace_profiles" {
  default = {
    staging    = "default"
    production = "prod"
  }
}

terraform {
  backend "s3" {
    bucket               = "changeme-tf-state"
    key                  = "backend.tfstate"
    workspace_key_prefix = "kube"
    region               = "eu-west-1"
    profile              = ""
    acl                  = "bucket-owner-full-control"
  }
}

provider "aws" {
  region  = "eu-west-1"
  profile = "${var.workspace_profiles[terraform.workspace]}"
}

provider "kubernetes" {
}

data "terraform_remote_state" "kubernetes" {
  backend = "s3"

  config {
    bucket = "changeme-tf-state"

    region  = "eu-west-1"
    key     = "kube/${terraform.workspace}/kubernetes.tfstate"
    region  = "eu-west-1"
    profile = ""
  }
}
