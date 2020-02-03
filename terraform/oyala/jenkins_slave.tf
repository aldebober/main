data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["jenkins-slave-emig-ami-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["170567814823"] # analytics account
}

module "ec2_instance" {
  source                      = "terraform-aws-modules/ec2-instance/aws"
  instance_type               = "t2.small"
  name                        = "emig-jenkins-slave"
  key_name                    = "emig-emr-discovery"
  associate_public_ip_address = false
  ami                         = "${data.aws_ami.ubuntu.id}"
  vpc_security_group_ids      = ["${module.security_group.this_security_group_id}"]
  subnet_id                   = "${element(module.vpc.private_subnets, 0)}"
  iam_instance_profile        = "${aws_iam_instance_profile.emr_launcher_ip.id}"
}

resource "aws_key_pair" "emig-emr-discovery" {
  key_name   = "emig-emr-discovery"
  public_key = "${file("keys/emig-emr-discovery.pub")}"
}
