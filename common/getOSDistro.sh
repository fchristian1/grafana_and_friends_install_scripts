#!/bin/bash
# check is ubuntu or cent os
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
fi
echo $OS
