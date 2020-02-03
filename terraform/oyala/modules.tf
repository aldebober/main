module "naming" {
  source           = "git::ssh://git@git.corp.ooyala.com:7999/emig/terraform.git//modules/naming"
  product_code_tag = "${var.product_code_tag}"
  environment_tag  = "${var.environment_tag}"
  product_name     = "${var.product_name}"
  aws_region       = "${var.aws_region}"
}
