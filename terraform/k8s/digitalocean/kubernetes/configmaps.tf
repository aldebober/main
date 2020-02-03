resource "kubernetes_config_map" "monitoring" {
  metadata {
    name = "mon-config"
    namespace = "${kubernetes_namespace.test.metadata.0.name}"
  }

  data = {
    APPSIGNAL_APP_ENV             = "staging"
    APPSIGNAL_APP_NAME            = "Changeme"
    NEWRELIC_ENV                  = "staging"
  }
}

output "mon-config" {
    value   = "${kubernetes_config_map.monitoring.metadata.0.name}"
}
