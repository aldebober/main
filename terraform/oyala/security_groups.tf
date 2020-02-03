module "security_group_base" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "${module.naming.aws_security_group}base"
  description = "Base security group providing ssh port"
  vpc_id      = "${module.vpc.vpc_id}"

  ingress_cidr_blocks = "${var.ssh_cidrs}"
  ingress_rules       = ["ssh-tcp"]
  egress_cidr_blocks  = ["0.0.0.0/0"]
  egress_rules        = ["all-all"]
}

module "security_group" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "jenkins_slave"
  description = "Security group for jenkins slave"
  vpc_id      = "${module.vpc.vpc_id}"

  ingress_cidr_blocks = "${var.ssh_cidrs}"
  ingress_rules       = ["ssh-tcp"]
  egress_cidr_blocks  = ["0.0.0.0/0"]
  egress_rules        = ["all-all"]
}

module "security_group_emr_master" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "emr_master"
  description = "Security group for EMR master"
  vpc_id      = "${module.vpc.vpc_id}"

  ingress_cidr_blocks = ["${var.vpc_cidr}"]
  ingress_rules       = ["all-tcp"]
  ingress_rules       = ["all-udp"]
  ingress_rules       = ["all-icmp"]

  egress_cidr_blocks = ["0.0.0.0/0"]
  egress_rules       = ["all-all"]
}

module "security_group_emr_slave" {
  source = "terraform-aws-modules/security-group/aws"

  name                = "emr_slave"
  description         = "Security group for EMR slave"
  vpc_id              = "${module.vpc.vpc_id}"
  ingress_cidr_blocks = ["${var.vpc_cidr}"]
  ingress_rules       = ["all-tcp"]
  ingress_rules       = ["all-udp"]
  ingress_rules       = ["all-icmp"]

  egress_cidr_blocks = ["0.0.0.0/0"]
  egress_rules       = ["all-all"]
}

module "security_group_emr_service" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "emr_service"
  description = "Security group for EMR service"
  vpc_id      = "${module.vpc.vpc_id}"

  egress_with_cidr_blocks = [
    {
      from_port   = 8443
      to_port     = 8443
      protocol    = "tcp"
      description = "emr service"
      cidr_blocks = "${var.vpc_cidr}"
    },
  ]
}
