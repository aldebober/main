/*
 * All terraform variables
*/

variable "terraformer_bucket" {}

variable "aws_region" {}
variable "aws_profile" {}

variable "product_name" {}
variable "product_code_tag" {}
variable "environment_tag" {}

variable "emr_role" {}
variable "lambda_file" {}

variable "vpc_cidr" {}
variable "vpc_azs" {}
variable "vpc_pub_subnets" {}
variable "vpc_priv_subnets" {}

variable "vpn_gateway_id" {
  type = "string"
}

variable "peering_to_main_aws_id" {
  type = "string"
}

variable "peering_to_jenkins_id" {
  type = "string"
}

variable "route53_subzone_for_ooyala_com" {
  type = "string"
}

variable "vpn_gateway_to_git_id" {
  type = "string"
}

variable "ssh_cidrs" {
  type = "list"
}
