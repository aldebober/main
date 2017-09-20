variable "subnet_ids" {type = "list" }
variable "elb_name" {
   default = "grafana"
}
variable "bastion_host_ip" { }
variable "availability_zones" { type = "list" }
variable "aws_key_pair" {
   default = "yurix-test"
}
variable "sec_primary_id" { }
variable "instance_type" {
  default = "t2.small"
}
variable "aws_region" {
  default = "eu-central-1"
}
variable "name" {
  default = "Nomad"
}
variable "iam_role_id" { }

