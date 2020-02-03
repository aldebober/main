variable "cluster-name" {
    default = "changeme-com"
}

variable "cluster-region" {
    default = "fra1"
}

variable "cluster-version" {
    default = "1.16.2-do.1"
}

variable "cluster-node-pool-name" {
    default = "arca-worker-pool"
}

variable "cluster-node-pool-size" {
    default = "s-1vcpu-2gb"
}

variable "cluster-node-pool-node-count" {
    default = 3
}

resource "digitalocean_kubernetes_cluster" "cluster" {
  name    = "${var.cluster-name}"
  region  = "${var.cluster-region}"
  version = "${var.cluster-version}"
  tags = ["${var.cluster-name}"]

  node_pool {
    name       = "${var.cluster-node-pool-name}"
    size       = "${var.cluster-node-pool-size}"
    node_count = "${var.cluster-node-pool-node-count}"
  }
}

resource "local_file" "kubeconfig" {
  content = "${digitalocean_kubernetes_cluster.cluster.kube_config.0.raw_config}"
  filename = ".kubeconfig"
}

output "endpoint" {
    value = "${digitalocean_kubernetes_cluster.cluster.endpoint}"
}

output "token" {
    value = "${digitalocean_kubernetes_cluster.cluster.kube_config.0.token}"
}

output "client_certificate" {
    value = "${digitalocean_kubernetes_cluster.cluster.kube_config.0.client_certificate}"
}

output "client_key" {
    value = "${digitalocean_kubernetes_cluster.cluster.kube_config.0.client_key}"
}

output "cluster_ca_certificate" {
    value = "${digitalocean_kubernetes_cluster.cluster.kube_config.0.cluster_ca_certificate}"
}

output "kubeconfig" {
    value = "${digitalocean_kubernetes_cluster.cluster.kube_config.0.raw_config}"
}
