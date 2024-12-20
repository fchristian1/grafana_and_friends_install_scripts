#!/bin/bash
tags=($("../../../common/getTagsFromRepository.sh" https://github.com/prometheus/prometheus.git))
index=$((${#tags[@]} - 1))
echo $1

# execute the menuSelectOnThree.sh script with two parameters tags and index to return the selected version

version=$(
    (
        ../../../common/menuSelectOnThree.sh $index "${tags[@]}"
    ) | tee /dev/null
)

url="https://github.com/prometheus/prometheus/releases/download/v$version/prometheus-$version.linux-amd64.tar.gz"
file="prometheus-$version.linux-amd64.tar.gz"
folder="prometheus-$version.linux-amd64"

echo "download file"
if [ ! -f "$file" ]; then
    curl -LO $url
fi
echo "unpack file"
tar -xvf $file

sudo mv prometheus-$version.linux-amd64/prometheus /usr/local/bin/

echo "clean up"
sudo rm -rf $folder

echo "create config"
sudo mkdir /etc/prometheus/
sudo tee /etc/prometheus/config.yml >/dev/null <<EOF
global:
  scrape_interval:     15s # By default, scrape targets every 15 seconds.

  # Attach these labels to any time series or alerts when communicating with
  # external systems (federation, remote storage, Alertmanager).
  external_labels:
    monitor: 'codelab-monitor'

# A scrape configuration containing exactly one endpoint to scrape:
# Here it's Prometheus itself.
scrape_configs:
  - job_name: 'prometheus'

    # Override the global default and scrape targets from this job every 5 seconds.
    scrape_interval: 5s

    static_configs:
      - targets: ['localhost:9100']
EOF
echo "add user"
if ! id prometheus >/dev/null 2>&1; then
    sudo useradd -rs /bin/false prometheus
fi
echo "create folders"
sudo mkdir /data/prometheus -p
sudo chown prometheus:prometheus /data/prometheus
sudo chmod 755 /data/prometheus

echo "stopping service"
if ! systemctl is-active --quiet prometheus.service; then
    sudo systemctl stop prometheus
fi
echo create service file
sudo tee /etc/systemd/system/prometheus.service >/dev/null <<EOF
[Unit]
Description=Prometheus Service
After=network.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
    --config.file=/etc/prometheus/config.yml \
    --storage.tsdb.path=/data/prometheus \
    --log.level=info
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

echo "Prometheus installed successfully"
echo "Prometheus is running on port 9090"
echo "Service: sudo systemctl status prometheus.service"
publicip=$(curl http://checkip.amazonaws.com)
if [ $publicip ]; then
    echo "http://$publicip:9090"
    echo "http://localhost:9090"
else
    echo "http://localhost:30909000"
fi
