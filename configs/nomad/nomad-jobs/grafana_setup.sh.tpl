#!/usr/bin/bash

until curl -sf admin:admin@localhost:3000 > /dev/null; do sleep 1; echo "Grafana is not started yet";done; echo "Grafana is started"
curl -XPUT "admin:admin@localhost:3000/api/user/password" -H "Content-Type:application/json" -d '{"oldPassword":"admin","newPassword":"{{ env "grafana_pass" }}","confirmNew":"{{ env "grafana_pass" }}"}'
curl -XPOST "admin:{{ env "grafana_pass" }}@localhost:3000/api/datasources" -H "Content-Type:application/json" -d '{"name":"Prometheus","type":"prometheus","url":"http://127.0.0.1:9090","access":"proxy"}'
curl -XPOST "admin:{{ env "grafana_pass" }}@localhost:3000/api/dashboards/db" -H "Content-Type:application/json" -d @/opt/grafana/dashboards/Host.json
curl -XPOST "admin:{{ env "grafana_pass" }}@localhost:3000/api/dashboards/db" -H "Content-Type:application/json" -d @/opt/grafana/dashboards/consul.json
curl -XPOST "admin:{{ env "grafana_pass" }}@localhost:3000/api/dashboards/db" -H "Content-Type:application/json" -d @/opt/grafana/dashboards/vernemq.json
curl -XPOST "admin:{{ env "grafana_pass" }}@localhost:3000/api/dashboards/db" -H "Content-Type:application/json" -d @/opt/grafana/dashboards/rabbitmq.json
