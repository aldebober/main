data "template_file" "s3-emr-policy" {
  template = "${file("policies/s3-emr-policy.json.tpl")}"

  vars {
    bucket_name = "${module.naming.aws_s3_bucket}emr"
  }
}

resource "aws_s3_bucket" "emr-discovery" {
  bucket = "${module.naming.aws_s3_bucket}emr"
  acl    = "private"

  lifecycle {
    create_before_destroy = true
  }
  lifecycle_rule {
    prefix  = ""
    enabled = true

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

  }

  policy = "${data.template_file.s3-emr-policy.rendered}"

  tags {
    "ProductCode" = "${var.product_code_tag}"
    "Environment" = "${var.environment_tag}"
  }
}

