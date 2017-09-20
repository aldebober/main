job "vernemq" {
  datacenters = ["test4"]
  all_at_once = false

  group "vernemq" {
    count = 4

    restart {
      attempts = 10
      interval = "5m"
      delay = "25s"

      mode = "delay"
    }

    task "vernemq" {
      vault {
       policies = ["test4"]
     }
      leader = true
      driver = "docker"
#      template {
#	data = <<EOH
#EOH
#        destination   = "local/vmq.passwd"
#        change_mode   = "restart"
#      }

      config {
        image = ""
        port_map {
          mqtt = 1883
	  ws = 8888
        }
	volumes = [
		"local/vmq.passwd:/etc/vernemq/vmq.passwd"
	]
	network_mode = "host"
      }

      env {
        LISTEN_ADDRESS = "${NOMAD_ADDR_mqtt}"
      }

      service {
        name = "vernemq"
	tags = ["vernemq", "mqtt", "staging"]
        port = "mqtt"
        check {
          name = "alive"
          port = "mqtt"
          type = "tcp"
          interval = "10s"
          timeout = "2s"
        }
      }

      resources {
        cpu = 500 # 500 Mhz
        memory = 512 # 128MB
        network {
          mbits = 10
          port "mqtt" { static = "1883" }
          port "ws" { static = "8888" }
        }
      }

    }
  }
}
