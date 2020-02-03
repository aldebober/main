# Service Roles
resource "aws_iam_role" "dumbifier-service" {
  name  = "dumbifier-service"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": [
          "ec2.amazonaws.com",
          "ssm.amazonaws.com",
          "events.amazonaws.com"
        ]
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "dumbifier-service" {
  name  = "dumbifier-service"
  role  = "${aws_iam_role.dumbifier-service.name}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "iam:PassRole",
      "Resource": "${aws_iam_role.dumbifier-instance.arn}"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "dumbifier-aws-ssm-automation-service" {
  role       = "${aws_iam_role.dumbifier-service.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonSSMAutomationRole"
}

# Instance Roles
resource "aws_iam_role" "dumbifier-instance" {
  name  = "dumbifier-instance"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": [
          "ec2.amazonaws.com",
          "ssm.amazonaws.com"
        ]
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "depersonalisation-s3-owner-acl" {
  count     = "${terraform.workspace == "production" ? 1 : 0}"
  name        = "depersonalisation-s3-owner-acl"
  description = "set owner on object on depersonalisation-s3"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "s3:ObjectOwnerOverrideToBucketOwner",
                "s3:PutObjectAcl"
            ],
            "Resource": "arn:aws:s3:::depersonalisation-stage-arcanebet/*"
        }
  ]
}
EOF
}

resource "aws_iam_policy" "dumbifier-instance" {
  name        = "dumbifier-instance"
  description = "dumbifier-instance"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ecs:Describe*",
        "ssm:Get*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "dumbifier-aws-ssm-automation-instance" {
  role       = "${aws_iam_role.dumbifier-instance.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

resource "aws_iam_role_policy_attachment" "dumbifier-aws-ssm-automation-instance-2" {
  role       = "${aws_iam_role.dumbifier-instance.name}"
  policy_arn = "${aws_iam_policy.dumbifier-instance.arn}"
}

resource "aws_iam_role_policy_attachment" "dumbifier-aws-ssm-automation-instance-3" {
  count     = "${terraform.workspace == "production" ? 1 : 0}"
  role       = "${aws_iam_role.dumbifier-instance.name}"
  policy_arn = "${aws_iam_policy.depersonalisation-s3-owner-acl.arn}"
}

resource "aws_iam_instance_profile" "dumbifier" {
  name  = "dumbifier"

  role = "${aws_iam_role.dumbifier-instance.name}"
}
