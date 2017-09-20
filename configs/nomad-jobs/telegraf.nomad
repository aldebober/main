job "telegraf" {
  datacenters = ["test6", "prometheus"]
  type = "system"

  group "telegraf" {

    task "telegraf" {
      driver = "raw_exec"

      artifact {
 	source = "https://s3.eu-central-1.amazonaws.com/simplinic-configs/services/telegraf.conf.tpl"
	destination = "local"
      }

      template {
	source      = "local/telegraf.conf.tpl"
        destination   = "local/telegraf.conf"
        change_mode   = "restart"
      }

      config {
	command = "local/telegraf/usr/bin/telegraf"
	args = ["--config=local/telegraf.conf"]
      }

      artifact {
    	source = "https://dl.influxdata.com/telegraf/releases/telegraf-1.4.0_linux_amd64.tar.gz"
      }

      service {
        name = "telegraf"
	tags = ["telegraf", "prometheus"]
        port = "prom"
        check {
          name = "alive"
          port = "prom"
          type = "tcp"
          interval = "10s"
          timeout = "2s"
        }
      }

      resources {
	network { 
	  port "prom" { static = "9126" }
	}
      }

    }
  }
}
