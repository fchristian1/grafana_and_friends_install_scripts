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

echo version: $version

url="https://github.com/grafana/loki/releases/download/v$version/loki-linux-amd64.zip"
url_config="https://github.com/grafana/loki/raw/refs/tags/v$version/cmd/loki/loki-local-config.yaml"

file="loki-linux-amd64.zip"

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

exho clean up
rm $file

echo "move file"
mv loki-linux-amd64 loki-$version-linux-amd64
sudo mv loki-$version-linux-amd64 /usr/local/bin/loki

echo "create config"
sudo mkdir /etc/loki/

echo download config
curl -LO $url_config

echo "move config"
sudo mv loki-local-config.yaml /etc/loki/config.yml

echo check and create user
if ! id loki >/dev/null 2>&1; then
  sudo useradd -rs /bin/false loki
fi
sudo chmod 641 /var/log/syslog

if ! systemctl is-active --quiet loki.service; then
  echo "stopping service"
  sudo systemctl stop loki
fi

echo create service file
sudo tee /etc/systemd/system/loki.service >/dev/null <<EOF
[Unit]
Description=Loki Log Collector
After=network.target

[Service]
User=loki
Group=loki
Type=simple
ExecStart=/usr/local/bin/loki \
  -config.file=/etc/loki/config.yml \
  -log.level=info
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

echo "Loki installed successfully"
echo "Loki is running on port 3100"
echo "Service: sudo systemctl status loki.service"
publicip=$(curl http://checkip.amazonaws.com)
if [ $publicip ]; then
  echo "http://$publicip:3100"
  echo "http://localhost:3100"
else
  echo "http://localhost:3100"
fi
