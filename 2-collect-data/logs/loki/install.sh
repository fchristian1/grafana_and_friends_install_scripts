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
echo "unpack file"
unzip ./$file

mv loki-linux-amd64 loki-$version-linux-amd64
sudo cp loki-$version-linux-amd64 /usr/local/bin/loki

echo "clean up"
sudo rm -rf $folder

echo "create config"
sudo mkdir /etc/loki/
echo download config
curl -LO $url_config
echo "move config"
sudo mv loki-local-config.yaml /etc/loki/config.yml

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
Description=Grafana Loki service
After=network.target

[Service]
User=loki
Group=loki
Type=simple
ExecStart=/usr/local/bin/loki -config.file=/etc/loki/config.yml

[Install]
WantedBy=multi-user.target
EOF
echo "reload daemon"
sudo systemctl daemon-reload
echo "start service"
sudo systemctl start loki
echo "enable service"
sudo systemctl enable loki
