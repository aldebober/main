variable "retention" {
  default = {
    staging    = 14
    production = 30
  }
}

data "archive_file" "es_cleanup" {
  type        = "zip"
  output_path = "zips/es_cleanup.zip"
  source_file = "functions/es_cleanup.py"
}

resource "aws_iam_role" "es_cleanup" {
  name = "es_cleanup"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "es_cleanup" {
  name = "es_cleanup"
  role = "${aws_iam_role.es_cleanup.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "logs:CreateLogGroup",
      "Resource": "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": [
        "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/es_cleanup:*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "es:ESHttpPost",
        "es:ESHttpGet",
        "es:ESHttpPut",
        "es:ESHttpDelete"
      ],
      "Resource": "arn:aws:es:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:domain/mydomain/*"
    }
  ]
}
EOF
}

resource "aws_lambda_function" "es_cleanup" {
  role             = "${aws_iam_role.es_cleanup.arn}"
  handler          = "es_cleanup.lambda_handler"
  runtime          = "python2.7"
  filename         = "zips/es_cleanup.zip"
  function_name    = "es_cleanup"
  source_code_hash = "${data.archive_file.es_cleanup.output_base64sha256}"
  timeout          = 180

  environment {
    variables {
      es_endpoint  = "${data.terraform_remote_state.es.es_url}"
      delete_after = "${var.retention[terraform.workspace]}"
      index_format = "%Y%m%d"
    }
  }
}

resource "aws_cloudwatch_event_rule" "es_cleanup" {
  name                = "es_cleanup"
  schedule_expression = "cron(0 10 * * ? *)"
}

resource "aws_cloudwatch_event_target" "es_cleanup" {
  target_id = "es_cleanup"
  rule      = "${aws_cloudwatch_event_rule.es_cleanup.name}"
  arn       = "${aws_lambda_function.es_cleanup.arn}"
}

resource "aws_lambda_permission" "es_cleanup" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.es_cleanup.arn}"
  principal     = "events.amazonaws.com"
  source_arn    = "${aws_cloudwatch_event_rule.es_cleanup.arn}"
}
