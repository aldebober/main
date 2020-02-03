variable "workspace_profiles" {
  default = {
    staging    = "default"
    production = "prod"
  }
}

terraform {
  backend "s3" {
    bucket               = "changeme-tf-state"
    key                  = "kubernetes.tfstate"
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

variable "cluster-name" {
    default = "changme"
}

provider "kubernetes" {
}
