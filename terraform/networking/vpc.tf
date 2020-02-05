variable "vpc" {
  default = {
    staging.cidr                = "10.10.0.0/16"
    staging.public_subnet_a     = "10.10.1.0/24"
    staging.public_subnet_b     = "10.10.2.0/24"
    staging.private_subnet_a    = "10.10.3.0/24"
    staging.private_subnet_b    = "10.10.4.0/24"
    production.cidr             = "10.0.0.0/16"
    production.public_subnet_a  = "10.0.1.0/24"
    production.public_subnet_b  = "10.0.2.0/24"
    production.private_subnet_a = "10.0.3.0/24"
    production.private_subnet_b = "10.0.4.0/24"
  }
}

# BUG: https://github.com/hashicorp/terraform/issues/17153
data "terraform_remote_state" "iam" {
  backend = "s3"

  config {
    bucket = "tf-state"

    key     = "iam/${terraform.workspace}/terraform.tfstate"
    region  = "eu-west-1"
    profile = ""
  }
}

data "aws_region" "current" {}

resource "aws_vpc" "main" {
  cidr_block           = "${lookup(var.vpc, "${terraform.workspace}.cidr")}"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags {
    Name = "main"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = "${aws_vpc.main.id}"
}

resource "aws_subnet" "public-subnet-a" {
  vpc_id = "${aws_vpc.main.id}"

  cidr_block        = "${lookup(var.vpc, "${terraform.workspace}.public_subnet_a")}"
  availability_zone = "${data.aws_region.current.name}a"

  tags {
    Name = "public-a"
  }
}

resource "aws_subnet" "public-subnet-b" {
  vpc_id = "${aws_vpc.main.id}"

  cidr_block        = "${lookup(var.vpc, "${terraform.workspace}.public_subnet_b")}"
  availability_zone = "${data.aws_region.current.name}b"

  tags {
    Name = "public-b"
  }
}

resource "aws_subnet" "private-subnet-a" {
  vpc_id = "${aws_vpc.main.id}"

  cidr_block        = "${lookup(var.vpc, "${terraform.workspace}.private_subnet_a")}"
  availability_zone = "${data.aws_region.current.name}a"

  tags {
    Name = "private-a"
  }
}

resource "aws_subnet" "private-subnet-b" {
  vpc_id = "${aws_vpc.main.id}"

  cidr_block        = "${lookup(var.vpc, "${terraform.workspace}.private_subnet_b")}"
  availability_zone = "${data.aws_region.current.name}b"

  tags {
    Name = "private-b"
  }
}

resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.main.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.main.id}"
  }

  tags {
    Name = "public"
  }
}

resource "aws_route_table" "private-a" {
  vpc_id = "${aws_vpc.main.id}"

  tags {
    Name = "private-a"
  }
}

resource "aws_route_table" "private-b" {
  vpc_id = "${aws_vpc.main.id}"

  tags {
    Name = "private-b"
  }
}

resource "aws_route_table_association" "public-a" {
  subnet_id      = "${aws_subnet.public-subnet-a.id}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_route_table_association" "public-b" {
  subnet_id      = "${aws_subnet.public-subnet-b.id}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_route_table_association" "private-a" {
  subnet_id      = "${aws_subnet.private-subnet-a.id}"
  route_table_id = "${aws_route_table.private-a.id}"
}

resource "aws_route_table_association" "private-b" {
  subnet_id      = "${aws_subnet.private-subnet-b.id}"
  route_table_id = "${aws_route_table.private-b.id}"
}
