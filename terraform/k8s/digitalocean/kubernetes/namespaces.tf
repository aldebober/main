resource "kubernetes_namespace" "test" {
  metadata {
    name = "test"
    labels {
      env = "test"
    }
  }
}

output "namespace" {
    value = "${kubernetes_namespace.test.metadata.0.name}"
}
