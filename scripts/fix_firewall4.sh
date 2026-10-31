#!/bin/bash
# Conserta o estado FAILED do firewalld causado pelas regras --direct do fix_firewall2.sh
# (a regra ipv6 aponta para DOCKER-USER, que nao existe no ip6tables) e aplica a policy.
IFACE="${IFACE:-wlan0}"   # ajuste para a interface Wi-Fi da sua estacao

echo "== removendo regras direct quebradas (configuracao permanente, offline)"
for fam in ipv4 ipv6; do
  firewall-offline-cmd --direct --remove-rule $fam filter DOCKER-USER 0 \
    -i "$IFACE" -m conntrack --ctstate NEW -j DROP
done
firewall-offline-cmd --direct --get-all-rules

echo "== checando configuracao"
firewall-offline-cmd --check-config && echo "config OK"

echo "== reiniciando firewalld e docker"
systemctl restart firewalld
systemctl restart docker
firewall-cmd --state

echo "== aplicando zona drop + policy"
bash "$(dirname "$0")/fix_firewall3.sh"
