data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

data "template_file" "openvpn_free_version" {
  template = "${file("scripts/openvpn_free_version.sh")}"

  vars {
    eip = "${aws_eip.openvpn_free_version.public_ip}"
  }
}

resource "aws_security_group" "openvpn-sg" {
  name        = "openvpn_sg"
  description = "OpenVPN SG, allows VPN access from anywhere"
  vpc_id      = "${aws_vpc.main.id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 1194
    to_port     = 1194
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_eip" "openvpn_free_version" {
  vpc = true
}

resource "aws_instance" "openvpn_free_version" {
  instance_type               = "t3.micro"
  associate_public_ip_address = true

  iam_instance_profile   = "${data.terraform_remote_state.iam.openvpn_profile}"
  ami                    = "${data.aws_ami.ubuntu.id}"
  subnet_id              = "${aws_subnet.public-subnet-a.id}"
  vpc_security_group_ids = ["${aws_security_group.openvpn-sg.id}"]
  user_data              = "${data.template_file.openvpn_free_version.rendered}"

  tags {
    Name = "openvpn_free_version"
  }

  lifecycle {
    ignore_changes = ["tags", "ami", "user_data", "key_name"]
  }
}

resource "aws_eip_association" "openvpn_free_version" {
  instance_id   = "${aws_instance.openvpn_free_version.id}"
  allocation_id = "${aws_eip.openvpn_free_version.id}"
}
