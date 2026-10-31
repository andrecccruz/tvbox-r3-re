#!/bin/bash
# Bloqueia conexoes novas vindas do Wi-Fi para containers Docker expostos na estação.
# A zona/policy do firewalld nao pega esse trafego: o Docker o encaminha pelas proprias
# regras iptables. A forma documentada pelo Docker e a cadeia DOCKER-USER (so IPv4;
# as portas [::] passam pelo docker-proxy e ja sao barradas pela zona public).
# O drop-in do systemd recria a regra toda vez que o Docker sobe.
IFACE="${IFACE:-wlan0}"   # ajuste para a interface Wi-Fi da sua estacao

RULE="DOCKER-USER -i $IFACE -m conntrack --ctstate NEW -m comment --comment wifi-bloqueia-docker -j DROP"

mkdir -p /etc/systemd/system/docker.service.d
cat > /etc/systemd/system/docker.service.d/wifi-bloqueia-docker.conf <<EOF
[Service]
ExecStartPost=/bin/sh -c 'iptables -C $RULE 2>/dev/null || iptables -I $RULE'
EOF

systemctl daemon-reload
systemctl restart docker

echo "== regra ativa"
iptables -S DOCKER-USER
