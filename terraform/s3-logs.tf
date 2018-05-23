resource "aws_s3_bucket" "logs" {
  bucket = "${module.naming.aws_s3_bucket}logs"
  acl    = "private"

  lifecycle {
    create_before_destroy = true
  }

  policy = <<POLICY
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          "${aws_iam_role.default.arn}"
        ]
      },
      "Action": [
        "s3:List*",
        "s3:Get*"
      ],
      "Resource": "arn:aws:s3:::${module.naming.aws_s3_bucket}logs"
    },
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          "${aws_iam_role.default.arn}"
        ]
      },
      "Action": [
        "s3:List*",
        "s3:Get*"
      ],
      "Resource": "arn:aws:s3:::${module.naming.aws_s3_bucket}logs/*"
    }
  ]
}
POLICY

  tags {
    "ProductCode" = "${var.product_code_tag}"
    "Environment" = "${var.environment_tag}"
  }
}

resource "aws_iam_policy" "S3LogBucketFullAccess" {
  name        = "${aws_s3_bucket.logs.id}.S3LogBucketFullAccess"
  path        = "/"
  description = "Allow full access to the product s3 bucket ${aws_s3_bucket.logs.arn}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:ListBucket"],
      "Resource": "${aws_s3_bucket.logs.arn}"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject"
      ],
      "Resource": [
        "${aws_s3_bucket.logs.arn}/*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "EC2S3LogsBucketFullAccess" {
  name   = "${format("%s.%s.%s", var.product_code_tag, var.environment_tag, var.aws_region)}.S3LogBucketFullAccess"
  role   = "${aws_iam_role.default.id}"
  policy = "${aws_iam_policy.S3LogBucketFullAccess.policy}"
}
