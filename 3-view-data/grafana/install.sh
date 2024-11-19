#!/bin/bash
# https://github.com/grafana/grafana.git
tags=($("../../common/getTagsFromRepository.sh" https://github.com/grafana/grafana.git))
index=$((${#tags[@]} - 1))
echo $1

# execute the menuSelectOnThree.sh script with two parameters tags and index to return the selected version

version=$(
    (
        ../../common/menuSelectOnThree.sh $index "${tags[@]}"
    ) | tee /dev/null
)

# check is ubuntu or cent os
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
fi

version=$(echo $version | sed 's/-/~/g')
if [ "$OS" == "ubuntu" ]; then
    echo "Installing Grafana on Ubuntu"
    # $version replace - to ~
    sudo apt-get install -y adduser libfontconfig1 musl &&
        wget https://dl.grafana.com/oss/release/grafana_"$version"_amd64.deb &&
        sudo dpkg -i grafana_11.3.0+security~01_amd64.deb &&
        sudo systemctl enable grafana-server &&
        sudo systemctl start grafana-server
#centos or amazon linux
elif [ "$OS" == "centos" ] || [ "$OS" == "amzn" ]; then
    echo "Installing Grafana on CentOS"
    sudo yum install -y https://dl.grafana.com/oss/release/grafana-"$version"-1.x86_64.rpm &&
        sudo systemctl enable grafana-server &&
        sudo systemctl start grafana-server
else
    echo "OS not supported"
    exit 1

fi
