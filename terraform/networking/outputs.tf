output "openvpn_ip" {
  value = "${aws_eip.openvpn_free_version.public_ip}"
}

output "private_subnet_a" {
  value = "${aws_subnet.private-subnet-a.id}"
}

output "private_subnet_b" {
  value = "${aws_subnet.private-subnet-b.id}"
}

output "public_subnet_a" {
  value = "${aws_subnet.public-subnet-a.id}"
}

output "public_subnet_b" {
  value = "${aws_subnet.public-subnet-b.id}"
}

output "vpc_id" {
  value = "${aws_vpc.main.id}"
}

output "vpc_cidr" {
  value = "${aws_vpc.main.cidr_block}"
}

output "nata_ip" {
  value = "${aws_eip.nat-ip-a.public_ip}"
}

output "natb_ip" {
  value = "${aws_eip.nat-ip-b.public_ip}"
}
