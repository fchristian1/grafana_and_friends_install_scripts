#1/bin/bash
tags=($(git ls-remote --tags https://github.com/grafana/loki.git | awk -F'/' '{print $3}' | sed 's/\^{}//' | grep -E '^v[0-9]*\.[0-9]*\.[0-9]$' | sed 's/^v//' | sed 's/^V//' | sort -V -u))
index=$((${#tags[@]} - 1))
echo $1
if [ "$1" != "latest" ]; then
    while true; do
        clear
        echo "Wähle eine Version von "loki" mit den Pfeiltasten und drücke Enter:"
        
        # Vorherige Version anzeigen
        if [ "$index" -gt 0 ]; then
            echo "   ${tags[index-1]}"
        else
            echo ""
        fi

        # Aktuelle Auswahl anzeigen, mit " --> Latest" beim letzten Tag
        if [ "$index" -eq $((${#tags[@]} - 1)) ]; then
            echo " > ${tags[index]} --> Latest"
        else
            echo " > ${tags[index]}"
        fi

        # Nächste Version anzeigen, wenn vorhanden
        if [ "$index" -lt $((${#tags[@]} - 1)) ]; then
            echo "   ${tags[index+1]}"
        else
            echo ""
        fi

        # Benutzer-Eingabe lesen
        read -rsn1 key

        case "$key" in
            $'\x1b')  # Escape-Sequenz für Pfeiltasten beginnt mit ^[
                read -rsn2 -t 0.1 key # Die nächsten 2 Zeichen lesen
                case "$key" in
                    "[A") # Pfeil nach oben
                        ((index--))
                        if [ "$index" -lt 0 ]; then
                            index=$((${#tags[@]} - 1))
                        fi
                        ;;
                    "[B") # Pfeil nach unten
                        ((index++))
                        if [ "$index" -ge "${#tags[@]}" ]; then
                            index=0
                        fi
                        ;;
                esac
                ;;
            "") # Enter-Taste
                break
                ;;
        esac
    done
fi

version=${tags[index]}

url="https://github.com/grafana/loki/releases/download/v$version/loki-linux-amd64.zip"
     
file="loki-linux-amd64.zip"


if  [ ! -f "$file" ]; then
    echo "download file"
    curl -LO $url
fi
echo "unpack file"
unzip ./$file

mv loki-linux-amd64 loki-$version-linux-amd64
sudo cp loki-$version-linux-amd64 /usr/local/bin/loki

echo "clean up"
sudo rm -rf $folder

echo "create config"
sudo mkdir /etc/loki/
sudo tee /etc/loki/config.yml > /dev/null <<EOF
auth_enabled: false

server:
  http_listen_port: 3100
  grpc_listen_port: 9096
  log_level: debug
  grpc_server_max_concurrent_streams: 1000

common:
  instance_addr: 127.0.0.1
  path_prefix: /tmp/loki
  storage:
    filesystem:
      chunks_directory: /tmp/loki/chunks
      rules_directory: /tmp/loki/rules
  replication_factor: 1
  ring:
    kvstore:
      store: inmemory

ingester_rf1:
  enabled: false

query_range:
  results_cache:
    cache:
      embedded_cache:
        enabled: true
        max_size_mb: 100

schema_config:
  configs:
    - from: 2020-10-24
      store: tsdb
      object_store: filesystem
      schema: v13
      index:
        prefix: index_
        period: 24h

pattern_ingester:
  enabled: true
  metric_aggregation:
    enabled: true
    loki_address: localhost:3100

ruler:
  alertmanager_url: http://localhost:9093

frontend:
  encoding: protobuf

# By default, Loki will send anonymous, but uniquely-identifiable usage and configuration
# analytics to Grafana Labs. These statistics are sent to https://stats.grafana.org/
#
# Statistics help us better understand how Loki is used, and they show us performance
# levels for most users. This helps us prioritize features and documentation.
# For more information on what's sent, look at
# https://github.com/grafana/loki/blob/main/pkg/analytics/stats.go
# Refer to the buildReport method to see what goes into a report.
#
# If you would like to disable reporting, uncomment the following lines:
#analytics:
#  reporting_enabled: false
EOF

if ! id loki >/dev/null 2>&1; then
    sudo useradd -rs /bin/false loki
fi;
sudo chmod 641 /var/log/syslog

if ! systemctl is-active --quiet loki.service; then
    echo "stopping service"
    sudo systemctl stop loki
fi;
echo create service file
sudo tee /etc/systemd/system/loki.service > /dev/null <<EOF
[Unit]
Description=Loki Log Collector
After=network.target

[Service]
User=loki
Group=loki
Type=simple
ExecStart=/usr/local/bin/loki -config.file=/etc/loki/config.yml
Restart=always
RestartSec=5
StartLimitBurst=5
StartLimitIntervalSec=60

[Install]
WantedBy=multi-user.target
EOF

echo "reload daemon"
sudo systemctl daemon-reload
echo "start service"
sudo systemctl start loki
echo "enable service"
sudo systemctl enable loki
