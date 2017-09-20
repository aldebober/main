resource "aws_iam_instance_profile" "lb_management" {
  name  = "lb_management-${terraform.env}"
  role = "${aws_iam_role.lb_management.name}"
}

resource "aws_iam_role" "lb_management" {
  name = "lb-management-${terraform.env}"
  path = "/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
        "Sid": "",
        "Effect": "Allow",
        "Principal": {
            "Service": "ec2.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy" "lb_management_policy" {
  name = "lb_management-policy-${terraform.env}"
  role = "${aws_iam_role.lb_management.id}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Stmt1425916919000",
            "Effect": "Allow",
            "Action": [
                "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
                "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
                "autoscaling:Describe*",
                "ec2:Describe*"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}
