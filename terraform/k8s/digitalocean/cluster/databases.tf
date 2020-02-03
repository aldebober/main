resource "digitalocean_database_cluster" "postgresql-dev" {
  name       = "dev-cluster"
  engine     = "pg"
  version    = "11"
  size       = "db-s-1vcpu-1gb"
  region     = "${var.cluster-region}"
  node_count = 1
}

resource "digitalocean_database_firewall" "example-fw" {
  cluster_id = "${digitalocean_database_cluster.postgresql-dev.id}"

  rule {
    type  = "ip_addr"
    value = "8.8.8.8"
  }

  rule {
    type  = "k8s"
    value = "${digitalocean_kubernetes_cluster.cluster.id}"
  }
}

resource "digitalocean_database_db" "backend" {
  cluster_id = "${digitalocean_database_cluster.postgresql-dev.id}"
  name       = "backend"
}

resource "digitalocean_database_user" "backend" {
  cluster_id = "${digitalocean_database_cluster.postgresql-dev.id}"
  name       = "backend"
}

resource "digitalocean_database_cluster" "redis" {
  name       = "redis"
  engine     = "redis"
  size       = "db-s-1vcpu-1gb"
  region     = "${var.cluster-region}"
  node_count = 1
  version    = "5.0.6"
}

output "redis-user" {
    value = "${digitalocean_database_cluster.redis.user}"
}

output "redis-password" {
    value = "${digitalocean_database_cluster.redis.password}"
}

output "pg-host" {
    value = "${digitalocean_database_cluster.postgresql-dev.host}"
}

output "pg-port" {
    value = "${digitalocean_database_cluster.postgresql-dev.port}"
}

output "pg-database" {
    value = "${digitalocean_database_cluster.postgresql-dev.database}"
}

output "pg-user" {
    value = "${digitalocean_database_cluster.postgresql-dev.user}"
}

output "pg-password" {
    value = "${digitalocean_database_cluster.postgresql-dev.password}"
}

output "backend-user-password" {
    value = "${digitalocean_database_user.backend.password}"
}

output "redis-host" {
    value = "${digitalocean_database_cluster.redis.host}"
}

output "redis-port" {
    value = "${digitalocean_database_cluster.redis.port}"
}
