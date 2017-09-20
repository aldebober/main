terraform {
  required_version = ">= 0.9.1"
  backend "s3" { 
    region = "eu-central-1"
    encrypt = "true"
    bucket = "your_bucket_name"
    key = "global.tfstate"
  }
}

provider "aws" {
  region = "${var.aws_region}"
}

module "network" {
  source = "../modules/aws/network"

  aws_region        = "${var.aws_region}"
  vpc_cidr          = "${var.vpc_cidr}"
  public_subnets      = ["${var.subnet_cidrs}"]
  subnet_availability_zones = ["${var.availability_zones}"]
  name              = "${var.name}-${terraform.env}"
  env               = "${terraform.env}"
  tags {
    "Terraform" = "true"
    "Env" = "${terraform.env}"
  }

}

module "autoscaling" {
  source = "../modules/aws/autoscaling"

  aws_region        = "${var.aws_region}"
  instance_type     = "${var.aws_instance_type}"
  aws_key_pair      = "${var.aws_key_pair}"
  sec_primary_id    = "${module.network.security_group_id}"
  subnet_ids    = ["${module.network.subnet_ids_public}"]
  iam_role_name = "${var.iam_role_name}"
  max_size  = 3
  tags = [
    {
        key = "Name"
        value = "${var.name}-${terraform.env}"
        propagate_at_launch = true
    },
    {
        key = "Env"
        value = "${terraform.env}"
        propagate_at_launch = true
    },
    {
        key = "${terraform.env}-vault"
        value = "${var.vault_tag}"
        propagate_at_launch = true
    },
  ]
  name              = "${var.name}-${terraform.env}"
}

output "network" {
  value = <<CONFIGURATION

This is the output 
vpc_id:  ${module.network.vpc_id}
sec_group_id:    ${module.network.security_group_id}
subnet_ids:  ${join(", ", module.network.subnet_ids_public)}
zones:  ${join(", ", module.network.subnet_availability_zones_public)}
cidrs:  ${join(", ", module.network.subnet_cidr_blocks_public)}

launch configuration:    ${module.autoscaling.lc_id}
autoscaling id:  ${module.autoscaling.autoscale_id}

CONFIGURATION
}
