data "aws_iam_policy_document" "assume_role" {
	statement {
		effect = "Allow"
		actions = [
			"sts:AssumeRole",
		]
		principals {
			type = "Service"
			identifiers = ["ec2.amazonaws.com"]
		}
	}
}

resource "aws_iam_role" "default" {
  name = "${module.naming.aws_iam_role}.default"
  assume_role_policy = "${data.aws_iam_policy_document.assume_role.json}"
}

resource "aws_iam_user" "packer" {
  name = "packer"
}

resource "aws_iam_user_policy" "packer_ec2" {
  name = "packer_ec2_policy"
  user = "${aws_iam_user.packer.name}"
  policy = "${file("policies/packer_ec2_policy.json")}"
}

#EMR instance profile

resource "aws_iam_instance_profile" "emr_launcher_ip" {
  name = "emr_launcher_ip"
  role = "${aws_iam_role.emr_launcher_role.name}"
}

resource "aws_iam_role_policy" "emr_launcher_policy" {
  name = "emr_launcher_policy"
  role = "${aws_iam_role.emr_launcher_role.id}"
  policy = "${file("policies/emr_launcher_policy.json")}"
}

resource "aws_iam_role_policy" "route53_launcher_policy" {
  name = "route53_launcher_policy"
  role = "${aws_iam_role.emr_launcher_role.id}"
  policy = "${file("policies/route53_launcher_policy.json")}"
}

resource "aws_iam_role" "emr_launcher_role" {
  name = "emr_launcher_role"
  assume_role_policy = "${data.aws_iam_policy_document.assume_role.json}"
}

resource "aws_iam_role_policy_attachment" "emr_launcher_attach_EC2S3LogsBucketFullAccess" {
  role       = "${aws_iam_role.emr_launcher_role.id}"
  policy_arn = "${aws_iam_policy.S3LogBucketFullAccess.arn}"
}

# DataDog Integration policy
# It's required to create Role to Datadog AWS account with external ID option manually.

resource "aws_iam_policy" "datadog_integration_policy" {
  name = "DatadogAWSIntegrationRole"
  path = "/"
  description = "Datadog policy"
  policy = "${file("policies/datadog_policy.json")}"
}

