data_dir = "/opt/nomad/data"
region = "eu-central"
leave_on_terminate = true
leave_on_interrupt = false
enable_syslog = false
disable_update_check = false
disable_anonymous_signature = false
log_level = "DEBUG"
bind_addr = "0.0.0.0"

client {
  enabled = true
  options {
    "docker.auth.config" = "/opt/nomad/conf/docker.json"
    "driver.raw_exec.enable" = "1"
  }
}

server {
  enabled          = true
  bootstrap_expect = 3
}

consul {
  address = "127.0.0.1:8500"
  server_service_name = "nomad"
  client_service_name = "nomad-client"
  auto_advertise = true
  server_auto_join = true
  client_auto_join = true
}

