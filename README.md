# Grafana and Friends - install scripts for easy use

## Services ready to install on Ubuntu and RHEL/CentOS(EC2)
clone repository go into the folder an start install script
```bash
# Ubuntu
sudo yum update && sudo yum install -y git
```

```bash
# CentOs
sudo apt update && sudo apt install -y git
```

```bash
git clone https://github.com/fchristian1/grafana_and_friends_install_scripts.git
cd grafana_and_friends_install_scripts
./install
```

### Recoder's
- Promtail - its a pull service
- node-exporter - http://locahost:9100
### Collector's
- Loki - http://locahost:3100
- Prometheus - http://locahost:9090
### View
- Grafana - http://locahost:3000

  
## what the hack do install
- select the service do you want to install
- you can select the version from the service
- install script download the release from the named service on github
- move and rename binary to the system
- create config
- create user and group
- add user to a spec group
- create a service file
- start and enable the service

## Tasks: 
- better echo calls
- functions in external file to (DRY) principle
- config edit over arguments
- create a overall script as menu to handle all other scripts in the folders.

## Using:

- clone the repro
- use the install.sh scripts in the folders to install the named service's
- select the version do you install or use the latest argument ( install.sh latest )

#### feel free to help me or write an issue
