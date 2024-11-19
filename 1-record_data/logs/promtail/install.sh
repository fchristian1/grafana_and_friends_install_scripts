#1/bin/bash
tags=($("../../../common/getTagsFromRepository.sh" https://github.com/grafana/loki.git))
index=$((${#tags[@]} - 1))
echo $1

# execute the menuSelectOnThree.sh script with two parameters tags and index to return the selected version

version=$(
    (
        ../../../common/menuSelectOnThree.sh $index "${tags[@]}"
    ) | tee /dev/null
)

url="https://github.com/grafana/loki/releases/download/v$version/promtail-linux-amd64.zip"

file="promtail-linux-amd64.zip"

if [ ! -f "$file" ]; then
    echo "download file"
    curl -LO $url
fi
#check if unzip is installed
if ! command -v unzip &>/dev/null; then
    echo "unzip could not be found"
    if [ -f /etc/debian_version ]; then
        sudo apt-get install unzip
    else
        sudo yum install unzip
    fi
fi
echo "unpack file"
unzip ./$file

mv promtail-linux-amd64 promtail-$version-linux-amd64
sudo cp promtail-$version-linux-amd64 /usr/local/bin/promtail

echo "clean up"
sudo rm -rf $folder

echo "create config"
sudo mkdir /etc/promtail/
# check is ubutu or centos
if [ -f /etc/debian_version ]; then
    sudo tee /etc/promtail/config.yml >/dev/null <<EOF
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
          __path__: /var/log/syslog
          stream: stdout
EOF
else
    sudo tee /etc/promtail/config.yml >/dev/null <<EOF
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
      - job_name: journal
        journal:
          json: false
          max_age: 12h
          path: /var/log/journal
          labels:
            job: systemd-journal
        relabel_configs:
          - source_labels: ['__journal__systemd_unit']
            target_label: 'unit'
EOF
fi

if ! id promtail >/dev/null 2>&1; then
    sudo useradd -rs /bin/false promtail
fi
sudo chmod 641 /var/log/syslog
if [ -f /etc/debian_version ]; then
    sudo usermod -aG adm promtail
else
    sudo usermod -aG systemd-journal promtail
fi

if ! systemctl is-active --quiet promtail.service; then
    echo "stopping service"
    sudo systemctl stop promtail
fi
echo create service file
sudo tee /etc/systemd/system/promtail.service >/dev/null <<EOF
[Unit]
Description=Promtail Log Shipper
After=network.target

[Service]
User=promtail
Group=promtail
Type=simple
ExecStart=/usr/local/bin/promtail \
    -config.file=/etc/promtail/config.yml \
    -config.expand-env=true \
    -log.level=info

[Install]
WantedBy=multi-user.target
EOF
echo "reload daemon"
sudo systemctl daemon-reload
echo "start service"
sudo systemctl start promtail
echo "enable service"
sudo systemctl enable promtail

echo "done"
echo "service: promtail"
echo "config: /etc/promtail/config.yml"
