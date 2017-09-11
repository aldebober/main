variable "vpc_cidr" {}
variable "env" {}
variable "public_subnets" { default = [] }
variable "subnet_availability_zones" { default = [] }
variable "gateway_enabled" { default = 1 }

variable "name" {
  description = "Name to be used on all the resources as identifier"
  default     = ""
}

variable "tags" {
  description = "A map of tags to add to all resources"
  default     = {}
}

variable "allowed_cidr" {
  type        = "list"
  default     = ["0.0.0.0/0"]
  description = "A list of CIDR Networks to allow ssh access to."
}

variable "allowed_ipv6_cidr" {
  type        = "list"
  default     = ["::/0"]
  description = "A list of IPv6 CIDR Networks to allow ssh access to."
}

variable "allowed_security_groups" {
  type        = "list"
  default     = []
  description = "A list of Security Group ID's to allow access to."
}

variable "instance_type" {
  default = "t2.micro"
}

variable "user_data_file" {
  default = "user_data.sh"
}

variable "s3_bucket_name" {
  default = "simplinic-ssh-public-keys"
}

variable "s3_bucket_uri" {
  default = ""
}

variable "ssh_user" {
  default = "ubuntu"
}

variable "enable_hourly_cron_updates" {
  default = "false"
}

variable "keys_update_frequency" {
  default = ""
}

variable "additional_user_data_script" {
  default = ""
}

variable "aws_region" {
  default = "eu-central-1"
}

variable "eip" {
  default = ""
}

variable "associate_public_ip_address" {
  default = false
}

variable "key_name" {
  default = ""
}
