data "aws_ami" "ubuntu_server_ami" {
    most_recent      = true
    filter {
        name   = "virtualization-type"
        values = ["hvm"]
    }
    filter {
        name   = "name"
        values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
    }
    owners = ["099720109477"] # Canonical
}

resource "aws_iam_instance_profile" "s3_readonly" {
  name  = "s3_readonly-${terraform.env}"
  role = "${aws_iam_role.s3_readonly.name}"
}

resource "aws_iam_role" "s3_readonly" {
  name = "s3_readonly-${var.env}"
  path = "/"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "s3_readonly_policy" {
  name = "s3_readonly-policy-${var.env}"
  role = "${aws_iam_role.s3_readonly.id}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Stmt1425916919000",
            "Effect": "Allow",
            "Action": [
                "s3:List*",
                "s3:Get*",
                "autoscaling:Describe*",
                "ec2:Describe*"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

data "template_file" "user_data" {
  template = "${file("${path.module}/${var.user_data_file}")}"
#  template = "${file("user_data.sh")}"

  vars {
    s3_bucket_name              = "${var.s3_bucket_name}"
    s3_bucket_uri               = "${var.s3_bucket_uri}"
    ssh_user                    = "${var.ssh_user}"
    main_asg                    = "nomad-${terraform.env}"
    aws_region                  = "${var.aws_region}"
    keys_update_frequency       = "${var.keys_update_frequency}"
    enable_hourly_cron_updates  = "${var.enable_hourly_cron_updates}"
    additional_user_data_script = "${var.additional_user_data_script}"
  }
}

resource "aws_instance" "bastion" {
  ami                    = "${data.aws_ami.ubuntu_server_ami.id}"
  instance_type          = "${var.instance_type}"
  iam_instance_profile   = "${aws_iam_role.s3_readonly.name}"
  subnet_id              = "${aws_subnet.public.0.id}"
  key_name              = "yurix-test"
  vpc_security_group_ids = ["${aws_security_group.bastion.id}"]
  user_data              = "${data.template_file.user_data.rendered}"

  count                  = 1

  tags {
    Name = "Bastion-${var.name}"
  }
}

output "bastion_host_ip" {
  value = "${aws_instance.bastion.public_ip}"
}

output "ssh_user" {
  value = "${var.ssh_user}"
}

output "security_group_bastion_id" {
  value = "${aws_security_group.bastion.id}"
}
