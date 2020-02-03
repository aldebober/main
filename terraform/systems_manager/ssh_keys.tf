data "template_file" "ssh_keys" {
  template = "${file("scripts/ssh_keys.sh")}"
}

resource "aws_ssm_association" "ssh_keys" {
  name                = "AWS-RunShellScript"
  association_name    = "ssh-keys"
  schedule_expression = "cron(0 0/30 * 1/1 * ? *)"

  parameters {
    commands = "${data.template_file.ssh_keys.rendered}"
  }

  targets {
    key    = "tag:UserData"
    values = ["finished"]
  }
}
