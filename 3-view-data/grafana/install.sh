#!/bin/bash
# check is ubuntu or cent os
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
fi

if [ "$OS" == "ubuntu" ]; then
    echo "Installing Grafana on Ubuntu"
elif [ "$OS" == "centos" ]; then
    echo "Installing Grafana on CentOS"
else
    echo "OS not supported"
    exit 1

fi
