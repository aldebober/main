data "template_file" "dumbifier" {
  template = "${file("scripts/dumbifier.yaml")}"

  vars = {
    instance_profile = "${aws_iam_instance_profile.dumbifier.name}"
    dumpDbPw         = "${data.aws_ssm_parameter.dumbified_rds_password.value}"
    replicaDbPw      = "${data.aws_ssm_parameter.rds_password.value}"
    serviceRoleArn   = "${aws_iam_role.dumbifier-service.arn}"
    hub_password     = "${data.aws_ssm_parameter.hub_password.value}"
    hub_username     = "ci"
    hub_email        = "ci@domain.com"
    dumpDbOwnerPw    = "${data.aws_ssm_parameter.dumbified_backend_password.value}"
  }
}

data "template_file" "dumbifier_stage" {
  template = "${file("scripts/dumbifier_stage.yaml")}"

  vars = {
    instance_profile = "${aws_iam_instance_profile.dumbifier.name}"
    dumpDbPw         = "${data.aws_ssm_parameter.dumbified_rds_password.value}"
    serviceRoleArn   = "${aws_iam_role.dumbifier-service.arn}"
    dumpDbOwnerPw    = "${data.aws_ssm_parameter.dumbified_backend_password.value}"
  }
}

data "aws_ssm_parameter" "hub_password" {
  name = "hub_password"
}

data "aws_ssm_parameter" "rds_password" {
  name = "/backend/web/rds_password"
}

data "aws_ssm_parameter" "dumbified_rds_password" {
  name = "dumbified_rds_password"
}

data "aws_ssm_parameter" "dumbified_backend_password" {
  name = "dumbified_backend_password"
}

resource "aws_ssm_document" "dumbifier" {
  count           = "${terraform.workspace == "production" ? 1 : 0}"
  name            = "database_copy_and_dumbify"
  document_type   = "Automation"
  document_format = "YAML"

  content = "${data.template_file.dumbifier.rendered}"
}

resource "aws_ssm_document" "dumbifier_stage" {
  count           = "${terraform.workspace == "staging" ? 1 : 0}"
  name            = "database_restore_dumb"
  document_type   = "Automation"
  document_format = "YAML"
  content = "${data.template_file.dumbifier_stage.rendered}"
}

resource "aws_cloudwatch_event_rule" "dumbifier" {
  count       = "${terraform.workspace == "production" ? 1 : 0}"
  name        = "db-dumbifier"
  description = "Dump production database, depersonalize and restore to dumbified rds"

  # Every day at 6am GMT time
  schedule_expression = "cron(00 06 * * ? *)"
}

resource "aws_cloudwatch_event_target" "sns" {
  count     = "${terraform.workspace == "production" ? 1 : 0}"
  target_id = "RunDumbifierDaily"
  rule      = "${aws_cloudwatch_event_rule.dumbifier.name}"
  arn       = "${replace(aws_ssm_document.dumbifier.arn, "document/", "automation-definition/")}"
  role_arn  = "${aws_iam_role.dumbifier-service.arn}"
  input     = "{\"FakeParam\":[\"Fake\"]}"
}

resource "aws_cloudwatch_event_rule" "dumbifier_stage" {
  count       = "${terraform.workspace == "staging" ? 1 : 0}"
  name        = "db-dumbifier"
  description = "Dump production database, depersonalize and restore to dumbified rds"

  # Every day at 6am GMT time
  schedule_expression = "cron(00 08 * * ? *)"
}

resource "aws_cloudwatch_event_target" "sns_stage" {
  count     = "${terraform.workspace == "staging" ? 1 : 0}"
  target_id = "RunDumbifierDaily"
  rule      = "${aws_cloudwatch_event_rule.dumbifier_stage.name}"
  arn       = "${replace(aws_ssm_document.dumbifier_stage.arn, "document/", "automation-definition/")}"
  role_arn  = "${aws_iam_role.dumbifier-service.arn}"
  input     = "{\"FakeParam\":[\"Fake\"]}"
}
