# Grafana and Friends - install scripts for easy use

## Services ready to install on Ubuntu and RHEL/CentOS(EC2)

### Recoder's
- Promtail
- node-eplorer
### Collector's
- Loki
- Prometheus
### View
- Grafana

  
## what the hack do install.sh
- you can select the version from the system
- install script download the release from the named service on github
- move and rename binary to the system
- create config
- create user and group
- add user to a spec group
- create a service file
- start and enable the service

Tasks: create a overall script as menu to handle all other scripts in the folders.

## Using:

- clone the repro
- use the install.sh scripts in the folders to install the named service's
- select the version do you install or use the latest argument ( install.sh latest )

#### feel free to help me or write an issue
