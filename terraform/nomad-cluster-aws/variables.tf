variable "aws_region" {
  default = "eu-central-1"
}

variable "vault_tag" {
}

variable "iam_role_name" {
  default = "aws-ec2-describe-role"
}

variable "default_instance_user" {
  default = "core"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "aws_key_pair" {
   default = "yurix-test"
}

variable "aws_instance_type" {
  default = "t2.small"
}

variable "owner" {
  default = "528733774338"
}

variable "name" {
  default = "Nomad"
}

variable "availability_zones" {
  type    = "list"
  default = [
    "eu-central-1a",
    "eu-central-1b",
    "eu-central-1c"
  ]
}

variable "subnet_cidrs" {
  type    = "list"
  default = [
    "10.0.1.0/24",
    "10.0.2.0/24",
    "10.0.3.0/24"
  ]
}

