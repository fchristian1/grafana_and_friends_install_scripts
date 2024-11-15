#1/bin/bash
tags=($(git ls-remote --tags https://github.com/prometheus/node_exporter.git | awk -F'/' '{print $3}' | sed 's/\^{}//' | grep -E '^v[0-9]*\.[0-9]*\.[0-9]$' | sed 's/^v//' | sed 's/^V//' | sort -V -u))
index=$((${#tags[@]} - 1))
echo $1
if [ "$1" != "latest" ]; then
    while true; do
        clear
        echo "Wähle eine Version von "Node Exporter" mit den Pfeiltasten und drücke Enter:"
        
        # Vorherige Version anzeigen
        if [ "$index" -gt 0 ]; then
            echo "   ${tags[index-1]}"
        else
            echo ""
        fi

        # Aktuelle Auswahl anzeigen, mit " --> Latest" beim letzten Tag
        if [ "$index" -eq $((${#tags[@]} - 1)) ]; then
            echo " > ${tags[index]} --> Latest"
        else
            echo " > ${tags[index]}"
        fi

        # Nächste Version anzeigen, wenn vorhanden
        if [ "$index" -lt $((${#tags[@]} - 1)) ]; then
            echo "   ${tags[index+1]}"
        else
            echo ""
        fi

        # Benutzer-Eingabe lesen
        read -rsn1 key

        case "$key" in
            $'\x1b')  # Escape-Sequenz für Pfeiltasten beginnt mit ^[
                read -rsn2 -t 0.1 key # Die nächsten 2 Zeichen lesen
                case "$key" in
                    "[A") # Pfeil nach oben
                        ((index--))
                        if [ "$index" -lt 0 ]; then
                            index=$((${#tags[@]} - 1))
                        fi
                        ;;
                    "[B") # Pfeil nach unten
                        ((index++))
                        if [ "$index" -ge "${#tags[@]}" ]; then
                            index=0
                        fi
                        ;;
                esac
                ;;
            "") # Enter-Taste
                break
                ;;
        esac
    done
fi

version=${tags[index]}

url="https://github.com/prometheus/node_exporter/releases/download/v$version/node_exporter-$version.linux-amd64.tar.gz"
file="node_exporter-$version.linux-amd64.tar.gz"
folder="node_exporter-$version.linux-amd64"

if  [ ! -f "$file" ]; then
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
fi;
if ! systemctl is-active --quiet node_exporter.service; then
    echo "stopping service"
    sudo systemctl stop node_exporter
fi;
echo create service file
sudo tee /etc/systemd/system/node_exporter.service > /dev/null <<EOF
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
