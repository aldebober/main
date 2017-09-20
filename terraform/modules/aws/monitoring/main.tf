data "aws_ami" "amazon_ami" {
  most_recent      = true
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "name"
    values = ["CoreOS-stable-*"]
  }
}

resource "aws_instance" "prometheus" {
  ami   = "${data.aws_ami.amazon_ami.id}"
  iam_instance_profile = "${var.iam_role_id}"
  instance_type = "${var.instance_type}"
  key_name = "${var.aws_key_pair}"
  vpc_security_group_ids = ["${var.sec_primary_id}"]
  availability_zone = "${var.availability_zones.[0]}"
  subnet_id = "${var.subnet_ids.[0]}"
  tags {
    Name = "Prometheus-${terraform.env}"
    Env = "${terraform.env}"
  }
  provisioner "file" {
    source      = "bin"
    destination = "/home/core/"
  }
  provisioner "file" {
    source      = "opt"
    destination = "/home/core/"
  }
  provisioner "local-exec" {
    command = "echo ${aws_instance.prometheus.private_ip} > /tmp/ip_address.txt"
  }
  connection {
    type     = "ssh"
    user     = "core"
    bastion_host    = "${var.bastion_host_ip}"
    bastion_user    = "ubuntu"
    host    = "${aws_instance.prometheus.private_ip}"
  }
}

resource "aws_ebs_volume" "prometheus-volume" {
  availability_zone = "${aws_instance.prometheus.availability_zone}"
  type              = "gp2"
  size              = 10
}

resource "aws_volume_attachment" "prometheus-volume-attachment" {
  device_name = "/dev/xvdx"
  instance_id = "${aws_instance.prometheus.id}"
  volume_id   = "${aws_ebs_volume.prometheus-volume.id}"
}

resource "null_resource" "second-exec" {
  provisioner "remote-exec" {
    inline = [
    "n | sudo mkfs.ext3 ${aws_volume_attachment.prometheus-volume-attachment.device_name}",
    "sudo mkdir /opt && sudo  mount ${aws_volume_attachment.prometheus-volume-attachment.device_name} /opt",
    "sudo mv opt/* /opt/",
    "chmod +x /home/core/bin/*",
    "/usr/bin/docker kill consul-server && /usr/bin/docker rm consul-server",
    "docker run -d --net=host --name consul-server -v /opt/consul/config:/consul/config -v /opt/consul/data:/consul/data -e 'CONSUL_ALLOW_PRIVILEGED_PORTS=' -e 'CONSUL_LOCAL_CONFIG={\"client_addr\": \"0.0.0.0\", \"node_name\": \"prometheus\", \"retry_join_ec2\": {\"region\": \"eu-central-1\", \"tag_key\": \"Env\", \"tag_value\": \"'${terraform.env}'\"}}' consul agent -dns-port=54 -recursor=8.8.8.8 -datacenter=${terraform.env} -bind=${aws_instance.prometheus.private_ip} -bootstrap-expect=3",
    "sudo mv bin/nomad.service /etc/systemd/system/nomad.service && sudo systemctl enable nomad",
    "sleep 15",
    "sudo systemctl start nomad"
    ]
  }
  connection {
    type     = "ssh"
    user     = "core"
    bastion_host    = "${var.bastion_host_ip}"
    bastion_user    = "ubuntu"
    host    = "${aws_instance.prometheus.private_ip}"
  }
}

output "public_ip" {
  value = "${aws_instance.prometheus.public_ip}"
}

output "private_ip" {
  value = "${aws_instance.prometheus.private_ip}"
}
