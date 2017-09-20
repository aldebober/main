job "prometheus" {
  datacenters = ["prometheus"]
  type = "system"

  group "prometheus" {
    task "alertmanager" {
      driver = "raw_exec"

      env {
 #Insert yoyr slack key and url here:
   slack_key = ""
   slack_url = ""
      }
      artifact {
 	source = "https://s3.eu-central-1.amazonaws.com/bucket-name/services/alertmanager.conf.tpl"
	destination = "local"
      }
      artifact {
    	source = "https://github.com/prometheus/alertmanager/releases/download/v0.8.0/alertmanager-0.8.0.linux-amd64.tar.gz"
      }

      template {
	source      = "local/alertmanager.conf.tpl"
        destination   = "local/alertmanager.yml"
        change_mode   = "restart"
      }

      config {
	command = "local/alertmanager-0.8.0.linux-amd64/alertmanager"

	args = [
	  "-config.file=local/alertmanager.yml"
 	]
      }
      resources {
        network {
          mbits = 10
          port "alertmanager" { static = "9093" }
        }
      }
    }

    task "prometheus" {
      driver = "docker"

      config {
        image        = "prom/prometheus"
        network_mode = "host"

        port_map {
          prometheus = 9090
        }

        volumes = [
          "/opt/prometheus:/prometheus"
        ]

        args = [
	  "-alertmanager.url=http://${attr.unique.network.ip-address}:9093",
	  "-config.file=/prometheus/conf/prometheus.yml",
	  "-storage.local.path=/prometheus/data"
        ]
      }

      resources {
        cpu    = 200
        memory = 256

        network {
          mbits = 10
        }
      }
    }

    task "grafana" {
      driver = "docker"

      config {
        image        = "docker.io/grafana/grafana"
        network_mode = "host"

        port_map {
          grafana = 3000
        }
        volumes = [
          "/opt/grafana/dashboards:/var/lib/grafana/dashboards"
        ]

      }

      resources {
        cpu    = 200
        memory = 256

        network {
          mbits = 10
        }
      }
    }
    task "setup_grafana" {
      driver = "raw_exec"

      env {
	grafana_pass = "r0cks"
      }

      artifact {
 	source = "https://s3.eu-central-1.amazonaws.com/bucket-name/services/grafana_setup.sh.tpl"
	destination = "local"
      }

      template {
	source      = "local/grafana_setup.sh.tpl"
        destination   = "local/grafana_setup.sh"
      }

      config {
	command = "local/grafana_setup.sh"
      }
    }

  }
}
