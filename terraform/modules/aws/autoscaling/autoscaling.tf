variable "instance_type" {}
variable "aws_key_pair" {}
variable "sec_primary_id" {}
variable "aws_region" {}
variable "iam_role_name" {}
variable "name" {}
variable "tags" { 
    description = "A list of tags to add to all resources"
    type = "list" 
}

data "aws_ami" "coreos_server_ami" {
	most_recent      = true
	filter {
    	name   = "virtualization-type"
    	values = ["hvm"]
  	}
  	filter {
    	name   = "name"
    	values = ["simplinic-coreos*"]
  	}
  	owners = ["528733774338"]
}

resource "aws_launch_configuration" "nomad" {
	image_id = "${data.aws_ami.coreos_server_ami.id}"
    iam_instance_profile = "${var.iam_role_name}"
    name_prefix   = "Nomad-${terraform.env}-"
	instance_type = "${var.instance_type}"
	associate_public_ip_address = true
	key_name = "${var.aws_key_pair}"
	security_groups = ["${var.sec_primary_id}"]
	user_data = "${file("user-data.coreos")}"
	root_block_device = {
		volume_type = "gp2"
		volume_size = 15
		delete_on_termination = true
 	}
    ebs_block_device = {
        device_name = "/dev/xvdf"
		volume_type = "gp2"
		volume_size = 20
		delete_on_termination = true
 	}

  lifecycle {
    create_before_destroy = true
  }
}

variable "subnet_ids" { type = "list" }
variable "max_size" {}

resource "aws_autoscaling_group" "nomad" {
     vpc_zone_identifier = ["${var.subnet_ids}"]
     name = "nomad-${terraform.env}"
     min_size = 1
     max_size = "${var.max_size}"
     desired_capacity = "${var.max_size}"
     force_delete = false
     launch_configuration = "${aws_launch_configuration.nomad.name}"
     health_check_grace_period = 100
     health_check_type = "EC2"
#     load_balancers = ["${aws_elb.kube-master.id}"]
     tags = ["${concat(var.tags)}"]
     depends_on = ["aws_launch_configuration.nomad"]
 }

output "lc_id" {
  value = "${aws_launch_configuration.nomad.id}"
}

output "autoscale_id" {
  value = "${aws_autoscaling_group.nomad.id}"
}
