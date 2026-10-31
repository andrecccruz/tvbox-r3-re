#!/bin/bash
# Substitui fix_firewall.sh (parte firewalld) e fix_firewall2.sh, que nao ficaram aplicados.
# 1) TV Box (BOX_IP) na zona drop: nada que ela inicie chega a estacao
# 2) Policy: conexoes novas vindas do Wi-Fi (zona public) para containers (zona docker)
#    sao rejeitadas. Funciona com backend nftables, ao contrario das regras --direct.
# Sem "set -e" de proposito: cada passo mostra o proprio resultado.
BOX_IP="${BOX_IP:-192.168.1.100}"   # ajuste para o IP da sua box

echo "== zona drop"
firewall-cmd --permanent --zone=drop --add-source="$BOX_IP"

echo "== policy wifi-para-docker"
firewall-cmd --permanent --new-policy wifi-para-docker 2>&1 | grep -v ALREADY_ENABLED
firewall-cmd --permanent --policy wifi-para-docker --add-ingress-zone public
firewall-cmd --permanent --policy wifi-para-docker --add-egress-zone docker
firewall-cmd --permanent --policy wifi-para-docker --set-target REJECT

echo "== recarregar"
firewall-cmd --reload

echo "== estado final"
firewall-cmd --get-active-zones
firewall-cmd --zone=drop --list-sources
firewall-cmd --info-policy wifi-para-docker
