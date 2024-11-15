#!/bin/bash
# check cpu architecture arm arm64 or x86 or amd64
arch=$(uname -m)
if [ "$arch" == "armv7l" ]; then
    echo "arm"
elif [ "$arch" == "aarch64" ]; then
    echo "arm64"
elif [ "$arch" == "x86_64" ]; then
    echo "amd64"
else
    echo "x86"
fi
