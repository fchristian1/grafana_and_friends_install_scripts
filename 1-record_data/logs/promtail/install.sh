#1/bin/bash
tags=($(git ls-remote --tags https://github.com/grafana/loki.git | awk -F'/' '{print $3}' | sed 's/\^{}//' | grep -E '^v[0-9]*\.[0-9]*\.[0-9]$' | sed 's/^v//' | sed 's/^V//' | sort -V -u))
index=$((${#tags[@]} - 1))
echo $1
if [ "$1" != "latest" ]; then
    while true; do
        clear
        echo "Wähle eine Version von "Promtail" mit den Pfeiltasten und drücke Enter:"
        
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

url="https://github.com/grafana/loki/releases/download/v$version/promtail-linux-amd64.zip"
     
file="promtail-linux-amd64.zip"


if  [ ! -f "$file" ]; then
    echo "download file"
    curl -LO $url
fi
echo "unpack file"
unzip ./$file

mv promtail-linux-amd64 promtail-$version-linux-amd64
sudo cp promtail-$version-linux-amd64 /usr/local/bin/promtail

echo "clean up"
sudo rm -rf $folder

echo "create config"
sudo mkdir /etc/promtail/
sudo tee /etc/promtail/config.yml > /dev/null <<EOF
# This minimal config scrape only single log file.
# Primarily used in rpm/deb packaging where promtail service can be started during system init process.
# And too much scraping during init process can overload the complete system.
# https://github.com/grafana/loki/issues/11398

server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /tmp/positions.yaml

clients:
- url: http://localhost:3100/loki/api/v1/push

scrape_configs:
- job_name: system
  static_configs:
  - targets:
      - localhost
    labels:
      job: varlogs
      #NOTE: Need to be modified to scrape any additional logs of the system.
      __path__: /var/log/syslog
EOF

if ! id promtail >/dev/null 2>&1; then
    sudo useradd -rs /bin/false promtail
fi;
sudo chmod 641 /var/log/syslog
sudo usermod -aG adm promtail

if ! systemctl is-active --quiet promtail.service; then
    echo "stopping service"
    sudo systemctl stop promtail
fi;
echo create service file
sudo tee /etc/systemd/system/promtail.service > /dev/null <<EOF
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=promtail
Group=promtail
Type=simple
ExecStart=/usr/local/bin/promtail -config.file=/etc/promtail/config.yml

[Install]
WantedBy=multi-user.target
EOF
echo "reload daemon"
sudo systemctl daemon-reload
echo "start service"
sudo systemctl start promtail
echo "enable service"
sudo systemctl enable promtail
