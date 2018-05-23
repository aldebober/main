module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${format("%s.%s.%s.vpc", var.product_code_tag, var.environment_tag, var.aws_region)}"

  cidr = "${var.vpc_cidr}"

  azs             = "${split(",", var.vpc_azs)}"
  private_subnets = "${split(",",var.vpc_priv_subnets)}"
  public_subnets  = "${split(",",var.vpc_pub_subnets)}"

  enable_nat_gateway = true
  enable_vpn_gateway = true

  enable_s3_endpoint = true

  #  enable_dynamodb_endpoint = true

  enable_dhcp_options              = true
  enable_dns_hostnames             = true
  enable_dns_support               = true
  dhcp_options_domain_name         = "ec2.internal"
  dhcp_options_domain_name_servers = ["AmazonProvidedDNS"]
  tags = {
    Owner                 = "${var.product_code_tag}"
    Environment           = "${var.environment_tag}"
    "transitvpc:is_spoke" = "true"
  }
}

# Create routes for private subnets
resource "aws_route" "peering_to_main_aws_account_private" {
  count = "${length(module.vpc.private_route_table_ids)}"

  route_table_id            = "${element(module.vpc.private_route_table_ids, count.index)}"
  destination_cidr_block    = "10.0.0.0/16"
  vpc_peering_connection_id = "${var.peering_to_main_aws_id}"
}

resource "aws_route" "peering_to_jenkins_vpc_private" {
  count = "${length(module.vpc.private_route_table_ids)}"

  route_table_id            = "${element(module.vpc.private_route_table_ids, count.index)}"
  destination_cidr_block    = "10.203.0.0/16"
  vpc_peering_connection_id = "${var.peering_to_jenkins_id}"
}

resource "aws_route" "vpn_gateway_private" {
  count = "${length(module.vpc.private_route_table_ids)}"

  route_table_id         = "${element(module.vpc.private_route_table_ids, count.index)}"
  destination_cidr_block = "10.0.0.0/8"
  gateway_id             = "${var.vpn_gateway_id}"
}

resource "aws_route" "vpn_gateway_to_git" {
  count = "${length(module.vpc.private_route_table_ids)}"

  route_table_id         = "${element(module.vpc.private_route_table_ids, count.index)}"
  destination_cidr_block = "10.50.0.0/16"
  gateway_id             = "${var.vpn_gateway_to_git_id}"
}


# Create routes for public subnets
resource "aws_route" "peering_to_main_aws_account_public" {
  count = "${length(module.vpc.public_route_table_ids) > 0 ? 1 : 0}"

  route_table_id            = "${element(module.vpc.public_route_table_ids, count.index)}"
  destination_cidr_block    = "10.0.0.0/16"
  vpc_peering_connection_id = "${var.peering_to_main_aws_id}"
}

resource "aws_route" "peering_to_jenkins_vpc_public" {
  count = "${length(module.vpc.public_route_table_ids) > 0 ? 1 : 0}"

  route_table_id            = "${element(module.vpc.public_route_table_ids, count.index)}"
  destination_cidr_block    = "10.203.0.0/16"
  vpc_peering_connection_id = "${var.peering_to_jenkins_id}"
}

resource "aws_route" "vpn_gateway_public" {
  count = "${length(module.vpc.public_route_table_ids) > 0 ? 1 : 0}"

  route_table_id         = "${element(module.vpc.public_route_table_ids, count.index)}"
  destination_cidr_block = "10.0.0.0/8"
  gateway_id             = "${var.vpn_gateway_id}"
}

resource "aws_route" "vpn_gateway_public_to_git" {
  count = "${length(module.vpc.public_route_table_ids)  > 0 ? 1 : 0}"

  route_table_id         = "${element(module.vpc.public_route_table_ids, count.index)}"
  destination_cidr_block = "10.50.0.0/16"
  gateway_id             = "${var.vpn_gateway_to_git_id}"
}

