resource "aws_security_group" "bastion" {
  name        = "${var.name}"
  vpc_id      = "${aws_vpc.nomad.id}"
  description = "Bastion security group (only SSH inbound access is allowed)"

  tags {
    Name = "${var.name}"
  }
}

resource "aws_security_group_rule" "ssh_ingress" {
  type              = "ingress"
  from_port         = "22"
  to_port           = "22"
  protocol          = "tcp"
  cidr_blocks       = "${var.allowed_cidr}"
  ipv6_cidr_blocks  = "${var.allowed_ipv6_cidr}"
  security_group_id = "${aws_security_group.bastion.id}"
}

resource "aws_security_group_rule" "ssh_sg_ingress" {
  count                    = "${length(var.allowed_security_groups)}"
  type                     = "ingress"
  from_port                = "22"
  to_port                  = "22"
  protocol                 = "tcp"
  source_security_group_id = "${element(var.allowed_security_groups, count.index)}"
  security_group_id        = "${aws_security_group.bastion.id}"
}

resource "aws_security_group_rule" "bastion_all_egress" {
  type              = "egress"
  from_port         = "0"
  to_port           = "65535"
  protocol          = "all"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = "${aws_security_group.bastion.id}"
}

resource "aws_security_group" "primary" {
  name   = "nomad_group"
  vpc_id = "${aws_vpc.nomad.id}"

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags             = "${merge(var.tags, map("Name", format("%s-sg-public", var.name)))}"
}

resource "aws_security_group_rule" "8000_bastion" {
  depends_on    = [ "aws_security_group.bastion", "aws_security_group.primary" ]
  type            = "ingress"
  from_port       = 8000
  to_port         = 8000
  protocol        = "tcp"
  source_security_group_id  = "${aws_security_group.bastion.id}"
  security_group_id = "${aws_security_group.primary.id}"
}

resource "aws_security_group_rule" "22_primary" {
  depends_on    = [ "aws_security_group.bastion", "aws_security_group.primary" ]
  type            = "ingress"
  from_port       = 22
  to_port         = 22
  protocol        = "tcp"
  source_security_group_id  = "${aws_security_group.bastion.id}"
  security_group_id = "${aws_security_group.primary.id}"
}
