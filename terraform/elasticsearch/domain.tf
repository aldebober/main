variable "volume_size" {
  default = {
    staging    = 20
    production = 35
  }
}

resource "aws_elasticsearch_domain" "this" {
  domain_name           = "mydomain"
  elasticsearch_version = "6.3"

  cluster_config {
    instance_type = "t2.small.elasticsearch"
  }

  ebs_options {
    ebs_enabled = true
    volume_size = "${var.volume_size[terraform.workspace]}"
  }

  tags {
    Name = "mydomain"
  }
}
