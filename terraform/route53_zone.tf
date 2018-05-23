resource "aws_route53_delegation_set" "default_ds" {
  reference_name = "OoyalaDelegationSet"
}

resource "aws_route53_zone" "ooyala_com_delegated_subzone" {
  name              = "${var.route53_subzone_for_ooyala_com}.ooyala.com"
  delegation_set_id = "${aws_route53_delegation_set.default_ds.id}"

  tags = {
    Creator = "Terraform"
    Owner   = "${var.product_code_tag}"
  }
}
