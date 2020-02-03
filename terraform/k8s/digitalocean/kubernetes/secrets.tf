variable site_certificate {
    default = "cert.pem"
}

variable site_certificate_key {
    default = "cert.key"
}

variable "docker_user" {}

variable "docker_pw" {}

variable "docker_email" {}

variable "mongo_url" {}

variable "site_certificate" {}

variable "site_certificate_key" {}

resource "kubernetes_secret" "databases-secret" {
  metadata {
    name = "databases-secret"
    namespace = "${kubernetes_namespace.test.metadata.0.name}"
  }

  data {
    MONGO_URL       = "${var.mongo_url}"
  }
}

resource "kubernetes_secret" "docker-registry" {
  metadata {
    name = "docker-registry"
    namespace = "test"
  }

  data {
    ".dockerconfigjson" = <<EOF
{
  "auths": {
    "https://index.docker.io/v1/": {
        "username": "${var.docker_user}",
        "password": "${var.docker_pw}",
        "email": "${var.docker_email}",
        "auth": "${base64encode(format("%s:%s", var.docker_user, var.docker_pw))}"
    }
  }
}
EOF
  }

  type = "kubernetes.io/dockerconfigjson"
}

resource "kubernetes_secret" "tls-secret-demo" {
  type  = "kubernetes.io/tls"

  metadata {
    name      = "cert-test"
    namespace = "test"
  }

  data = {
    "tls.crt" = "${file("${path.module}/certs/${var.site_certificate}")}"
    "tls.key" = "${file("${path.module}/certs/${var.site_certificate_key}")}"
  }
}

output "databases-secret" {
    value = "${kubernetes_secret.databases-secret.metadata.0.name}"
}

output "docker-registry" {
    value = "${kubernetes_secret.docker-registry.metadata.0.name}"
}

output "tls-secret-demo" {
    value = "${kubernetes_secret.tls-secret-demo.metadata.0.name}"
}

