variable "tag" {
    default = ""
}

variable "host" {
    default = "hostname"
}

variable "service_name" {
    default = "backend"
}

resource "kubernetes_deployment" "app" {
  metadata {
    name = "tf-${var.service_name}"
    labels = {
      app = "${var.service_name}"
    }
    namespace = "${data.terraform_remote_state.kubernetes.namespace}"
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "${var.service_name}"
      }
    }

    template {
      metadata {
        labels = {
          app = "${var.service_name}"
        }
      }

      spec {
        container {
          image = "myrepo/image:${var.tag}"
          name  = "${var.service_name}"
 
          working_dir = "/source"
          command = ["bundle"]
          args = ["exec", "rails server -p 3000 -b 0.0.0.0"]

          port {
            name           = "http"
            container_port = 3000
            protocol       = "TCP"
          }

          resources {
            limits {
              cpu    = "500m"
              memory = "1000Mi"
            }
            requests {
              cpu    = "400m"
              memory = "500Mi"
            }
          }
          env_from {
            config_map_ref {
              name   = "${data.terraform_remote_state.kubernetes.mon-config}"
            }
          }
          env_from {
            secret_ref {
              name   = "${data.terraform_remote_state.kubernetes.external-svc-secrets}"
            }
          }
          env_from {
            secret_ref {
              name   = "${data.terraform_remote_state.kubernetes.databases-secret}"
            }
          }

        }
        image_pull_secrets {
             name = "${data.terraform_remote_state.kubernetes.docker-registry}"
        }
      }
    }
  }
}

# Service
resource "kubernetes_service" "service" {
  metadata {
    name      = "${var.service_name}"
    namespace = "${data.terraform_remote_state.kubernetes.namespace}"
  }
  spec {
    selector {
      app = "${kubernetes_deployment.app.metadata.0.labels.app}"
    }
    port {
      name        = "http"
      port        = 80
      protocol    = "TCP"
      target_port = 3000
    }
  }
}

resource "kubernetes_ingress" "ingress" {
  metadata {
    annotations {
        "kubernetes.io/ingress.class"                    = "nginx"
        "nginx.ingress.kubernetes.io/ssl-passthrough"    = "true"
    }
    name      = "${var.service_name}-ingress"
    namespace = "${data.terraform_remote_state.kubernetes.namespace}"
  }
  spec {
    tls {
      hosts = ["${var.host}"]
      secret_name = "${data.terraform_remote_state.kubernetes.tls-secret-demo}"
    }
    rule {
      host = "${var.host}"
      http {
        path {
          backend {
            service_name = "${kubernetes_service.service.metadata.0.name}"
            service_port = "${kubernetes_service.service.spec.0.port.0.port}"
          }
        }
      }
    }
  }
}

