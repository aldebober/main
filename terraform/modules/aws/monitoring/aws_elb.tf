resource "aws_elb" "elb" {
  name = "${var.elb_name}-${terraform.env}"
  subnets = ["${var.subnet_ids}"]
  security_groups = ["${var.sec_primary_id}"]

  listener {
    instance_port = "3000"
    instance_protocol = "http"
    lb_port = 443
    lb_protocol = "https"
    ssl_certificate_id = ""
  }

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    target = "HTTP:3000/"
    interval = 30
  }

  cross_zone_load_balancing = true
}
