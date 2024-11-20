#1/bin/bash
tags=($("../../../common/getTagsFromRepository.sh" https://github.com/prometheus/node_exporter.git))
index=$((${#tags[@]} - 1))
echo $1

# execute the menuSelectOnThree.sh script with two parameters tags and index to return the selected version

version=$(
    (
        ../../../common/menuSelectOnThree.sh $index "${tags[@]}"
    ) | tee /dev/null
)

url="https://github.com/prometheus/node_exporter/releases/download/v$version/node_exporter-$version.linux-amd64.tar.gz"
file="node_exporter-$version.linux-amd64.tar.gz"
folder="node_exporter-$version.linux-amd64"

if [ ! -f "$file" ]; then
    echo "download file"
    curl -LO $url
fi
echo "unpack file"
tar -xvf $file

sudo mv node_exporter-$version.linux-amd64/node_exporter /usr/local/bin/

echo "clean up"
sudo rm -rf $folder

if ! id node_exporter >/dev/null 2>&1; then
    sudo useradd -rs /bin/false node_exporter
fi
if ! systemctl is-active --quiet node_exporter.service; then
    echo "stopping service"
    sudo systemctl stop node_exporter
fi
echo create service file
sudo tee /etc/systemd/system/node_exporter.service >/dev/null <<EOF
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOF
echo "reload daemon"
sudo systemctl daemon-reload
echo "start service"
sudo systemctl start node_exporter
echo "enable service"
sudo systemctl enable node_exporter

echo "Node-Exporter installed successfully"
echo "Node-Exporter is running on port 9100"
echo "Service: sudo systemctl status node_exporter.service"
publicip=$(curl http://checkip.amazonaws.com)
if [ $publicip ]; then
    echo "http://$publicip:9100"
    echo "http://localhost:9100"
else
    echo "http://localhost:9100"
fi
