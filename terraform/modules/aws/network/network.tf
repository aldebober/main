resource "aws_vpc" "nomad" {
    cidr_block = "${var.vpc_cidr}"
#    instance_tenancy = "dedicated"
    enable_dns_support  = true
    enable_dns_hostnames  = true
    tags                 = "${merge(var.tags, map("Name", format("%s-vpc", var.name)))}"
}

resource "aws_internet_gateway" "default" {
    vpc_id = "${aws_vpc.nomad.id}"
    tags   = "${merge(var.tags, map("Name", format("%s-igw", var.name)))}"
}

resource "aws_subnet" "public" {
  count                   = "${length(var.public_subnets)}"
  vpc_id                  = "${aws_vpc.nomad.id}"
  cidr_block              = "${var.public_subnets[count.index]}"
  availability_zone       = "${var.subnet_availability_zones[count.index]}"
  map_public_ip_on_launch = true
  tags             = "${merge(var.tags, map("Name", format("%s-subnet-public", var.name)))}"

}

resource "aws_route_table" "public" {
  count             = "${length(var.public_subnets)}"
  vpc_id            = "${aws_vpc.nomad.id}"
  tags = {
    Name = "${element(var.subnet_availability_zones, count.index)}-public"
    terraform = "true"
  }
}

resource "aws_route" "public_igw" {
  count                   = "${length(var.public_subnets) * var.gateway_enabled}"
  route_table_id          = "${element(aws_route_table.public.*.id, count.index)}"
  destination_cidr_block  = "0.0.0.0/0"
  gateway_id              = "${aws_internet_gateway.default.id}"
  depends_on              = ["aws_route_table.public"]
}

resource "aws_route_table_association" "public" {
  count           = "${length(var.public_subnets)}"
  subnet_id       = "${element(aws_subnet.public.*.id, count.index)}"
  route_table_id  = "${element(aws_route_table.public.*.id, count.index)}"
}

output "vpc_id" {
  value = "${aws_vpc.nomad.id}"
}

output "security_group_id" {
  value = "${aws_security_group.primary.id}"
}

output "route_table_ids_public" {
  value = ["${aws_route_table.public.*.id}"]
}

output "subnet_availability_zones_public" {
  value = ["${aws_subnet.public.*.availability_zone}"]
}

output "subnet_cidr_blocks_public" {
  value = ["${aws_subnet.public.*.cidr_block}"]
}
output "subnet_ids_public" {
  value = ["${aws_subnet.public.*.id}"]
}

output "subnet_id_by_availability_zone_public" {
  value = "${
    zipmap(
      aws_subnet.public.*.availability_zone,
      aws_subnet.public.*.id
    )
  }"
}

output "subnet_cidr_block_by_availability_zone_public" {
  value = "${
    zipmap(
      aws_subnet.public.*.availability_zone,
      aws_subnet.public.*.cidr_block
    )
  }"
}

