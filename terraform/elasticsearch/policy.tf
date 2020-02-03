resource "aws_elasticsearch_domain_policy" "this" {
  domain_name = "${aws_elasticsearch_domain.this.domain_name}"

  access_policies = <<POLICIES
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "es:*",
            "Principal": "*",
            "Effect": "Allow",
            "Condition": {
                "IpAddress": {
                  "aws:SourceIp": [
                    "${data.terraform_remote_state.vpc.nata_ip}",
                    "${data.terraform_remote_state.vpc.natb_ip}",
                    "${data.terraform_remote_state.vpc.openvpn_ip}",
                    "8.8.8.8/32"
                  ]
                }
            },
            "Resource": "${aws_elasticsearch_domain.this.arn}/*"
        }
    ]
}
POLICIES
}
