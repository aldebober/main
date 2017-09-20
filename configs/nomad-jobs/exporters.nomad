job "exporters" {
  datacenters = ["prometheus"]
  type = "system"

  group "exporters" {

    task "nomad-exporter" {
      driver = "docker"

      config {
        image = "nomon/nomad-exporter:latest"
        port_map {
          nomad = 9172
        }
	network_mode = "host"
      }

      service {
        name = "nomad-exporter"
        tags = ["nomad-exporter", "prometheus"]
        port = "nomad"
        check {
          name = "alive"
          port = "nomad"
          type = "tcp"
          interval = "10s"
          timeout = "2s"
        }
      }

      resources {
        network {
          port "nomad" { static = "9172" }
        }
      }
    }

    task "consul-exporter" {
      driver = "docker"

      config {
        image = "prom/consul-exporter"
	args  = ["--consul.server=172.17.0.1:8500", "--web.listen-address=0.0.0.0:9117"]
        port_map {
          prom = 9117
        }
      }

      service {
        name = "consul-exporter"
	tags = ["consul-exporter", "prometheus"]
        port = "consul"
        check {
          name = "alive"
          port = "consul"
          type = "tcp"
          interval = "10s"
          timeout = "2s"
        }
      }

      resources {
	network { 
	  port "consul" { static = "9117" }
	}
      }

    }
  }
}
