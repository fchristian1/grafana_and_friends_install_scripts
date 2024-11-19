#1/bin/bash
tags=($(git ls-remote --tags https://github.com/prometheus/prometheus.git | awk -F'/' '{print $3}' | sed 's/\^{}//' | grep -E '^v[0-9]*\.[0-9]*\.[0-9]$' | sed 's/^v//' | sed 's/^V//' | sort -V -u ))
index=$((${#tags[@]} - 1))
echo $1
if [ "$1" != "latest" ]; then
    while true; do
        clear
        echo "Wähle eine Version von "Node Exporter" mit den Pfeiltasten und drücke Enter:"
        
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

url="https://github.com/prometheus/prometheus/releases/download/v$version/prometheus-$version.linux-amd64.tar.gz"
file="prometheus-$version.linux-amd64.tar.gz"
folder="prometheus-$version.linux-amd64"

echo "download file"
if  [ ! -f "$file" ]; then
    curl -LO $url
fi
echo "unpack file"
tar -xvf $file

sudo mv prometheus-$version.linux-amd64/prometheus /usr/local/bin/

echo "clean up"
sudo rm -rf $folder

echo "create config"
sudo mkdir /etc/prometheus/
sudo tee /etc/prometheus/config.yml > /dev/null <<EOF
global:
  scrape_interval:     15s # By default, scrape targets every 15 seconds.

  # Attach these labels to any time series or alerts when communicating with
  # external systems (federation, remote storage, Alertmanager).
  external_labels:
    monitor: 'codelab-monitor'

# A scrape configuration containing exactly one endpoint to scrape:
# Here it's Prometheus itself.
scrape_configs:
  # The job name is added as a label `job=<job_name>` to any timeseries scraped from this config.
  - job_name: 'prometheus'

    # Override the global default and scrape targets from this job every 5 seconds.
    scrape_interval: 5s

    static_configs:
      - targets: ['localhost:9100']
EOF
echo "create folders"
sudo mkdir /data/ -p
sudo chmod 777 /data

echo "add user"
if ! id prometheus >/dev/null 2>&1; then
    sudo useradd -rs /bin/false prometheus
fi;
echo "stopping service"
if ! systemctl is-active --quiet prometheus.service; then
    sudo systemctl stop prometheus
fi;
echo create service file
sudo tee /etc/systemd/system/prometheus.service > /dev/null <<EOF
[Unit]
Description=Prometheus Service
After=network.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus --config.file=/etc/prometheus/config.yml
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
sudo systemctl start prometheus
echo "enable service"
sudo systemctl enable prometheus
