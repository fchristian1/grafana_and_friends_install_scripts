#!/bin/bash
tags=($("../../common/getTagsFromRepository.sh" https://github.com/prometheus/alertmanager.git))
index=$((${#tags[@]} - 1))
echo $1

# execute the menuSelectOnThree.sh script with two parameters tags and index to return the selected version

version=$(
    (
        ../../common/menuSelectOnThree.sh $index "${tags[@]}"
    ) | tee /dev/null
)

url="https://github.com/prometheus/alertmanager/releases/download/v$version/alertmanager-$version.linux-amd64.tar.gz"
file="alertmanager-$version.linux-amd64.tar.gz"
folder="alertmanager-$version.linux-amd64"

echo "download file"
if [ ! -f "$file" ]; then
    curl -LO $url
fi
echo "unpack file"
tar -xvf $file

sudo mv alertmanager-$version.linux-amd64/alertmanager /usr/local/bin/

echo "clean up"
sudo rm -rf $folder

echo "create config"
sudo mkdir /etc/alertmanager/
sudo tee /etc/alertmanager/config.yml >/dev/null <<EOF
global:
  smtp_smarthost: 'smtp.your-email-provider.com:587'
  smtp_from: 'alertmanager@yourdomain.com'
  smtp_auth_username: 'your-email@yourdomain.com'
  smtp_auth_password: 'your-email-password'

route:
  receiver: email-alert
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 1h

receivers:
  - name: email-alert
    email_configs:
      - to: 'your-email@yourdomain.com'
        send_resolved: true
groups:
  - name: cpu_alerts
    rules:
      - alert: HighCPULoad
        expr: 100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "Hohe CPU-Auslastung auf {{ $labels.instance }}"
          description: "Die CPU-Auslastung auf {{ $labels.instance }} ist über 80%. (Wert: {{ $value }})"
EOF
echo "add user"
if ! id alertmanager >/dev/null 2>&1; then
    sudo useradd -rs /bin/false alertmanager
fi

echo "create folders"
sudo mkdir /data/alertmanager -p
sudo chown alertmanager:alertmanager /data/alertmanager
sudo chmod 755 /data/alertmanager

echo "stopping service"
if ! systemctl is-active --quiet alertmanager.service; then
    sudo systemctl stop alertmanager
fi
echo create service file
sudo tee /etc/systemd/system/alertmanager.service >/dev/null <<EOF
[Unit]
Description=Alertmanager Service
After=network.target

[Service]
User=alertmanager
Group=alertmanager
Type=simple
ExecStart=/usr/local/bin/alertmanager \
    --config.file=/etc/alertmanager/config.yml
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
sudo systemctl start alertmanager
echo "enable service"
sudo systemctl enable alertmanager

echo "Alertmanager installed successfully"
echo "Alertmanager is running on port 9090"
echo "Service: sudo systemctl status alertmanager.service"
publicip=$(curl http://checkip.amazonaws.com)
if [ $publicip ]; then
    echo "http://$publicip:9090"
    echo "http://localhost:9090"
else
    echo "http://localhost:30909000"
fi
read -p "Press enter to continue"
