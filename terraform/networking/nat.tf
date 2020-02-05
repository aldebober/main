data "aws_ami" "ubuntu_ami" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-trusty-14.04-amd64-server-*"]
  }
}

data "template_file" "nat" {
  template = "${file("scripts/nat.sh")}"

  vars {
    region        = "${data.aws_region.current.name}"
    route_table_a = "${aws_route_table.private-a.id}"
    route_table_b = "${aws_route_table.private-b.id}"
    eip_a         = "${aws_eip.nat-ip-a.id}"
    eip_b         = "${aws_eip.nat-ip-b.id}"
  }
}

resource "aws_eip" "nat-ip-a" {
  vpc = true
}

resource "aws_eip" "nat-ip-b" {
  vpc = true
}

resource "aws_security_group" "nat" {
  name        = "nat-sg"
  description = "NAT SG, allows full access from same VPC"
  vpc_id      = "${aws_vpc.main.id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"

    cidr_blocks = ["${aws_vpc.main.cidr_block}"]
  }
}

resource "aws_launch_configuration" "nat_conf" {
  instance_type               = "t3.nano"
  associate_public_ip_address = true

  iam_instance_profile = "${data.terraform_remote_state.iam.nat_profile}"

  image_id        = "${data.aws_ami.ubuntu_ami.id}"
  security_groups = ["${aws_security_group.nat.id}"]
  user_data       = "${data.template_file.nat.rendered}"

  lifecycle {
    create_before_destroy = true
    ignore_changes = ["user_data"]
  }
}

resource "aws_autoscaling_group" "nat" {
  desired_capacity          = 2
  max_size                  = 2
  min_size                  = 2
  health_check_grace_period = 30
  health_check_type         = "EC2"

  launch_configuration = "${aws_launch_configuration.nat_conf.id}"
  vpc_zone_identifier  = ["${aws_subnet.public-subnet-a.id}", "${aws_subnet.public-subnet-b.id}"]

  tag {
    key                 = "Name"
    value               = "nat"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}
