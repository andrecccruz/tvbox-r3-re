#!/bin/bash
# Protege a estação contra a TV Box infectada.
# Ajuste BOX_IP para o IP da box na sua rede (ou: export BOX_IP=...).
set -e
BOX_IP="${BOX_IP:-192.168.1.100}"
cp -a /etc/docker/daemon.json /etc/docker/daemon.json.bak-$(date +%Y%m%d%H%M%S)
cat > /etc/docker/daemon.json <<'JSON'
{
  "log-level": "warn",
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "5"
  },
  "selinux-enabled": true,
  "ip": "127.0.0.1"
}
JSON
systemctl restart docker
firewall-cmd --permanent --zone=drop --add-source="$BOX_IP"
firewall-cmd --reload
echo "OK"
