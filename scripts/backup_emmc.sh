#!/bin/bash
# Backup das particoes de sistema do eMMC da TV Box (so leitura na box).
# Fica de fora: UDISK (/data, 4 GB, dados + malware) e cache (vazia).
# Cada imagem e conferida pelo SHA-256 calculado na box e na estação.
# Requer "adb root" (firmware userdebug). NAO usar su: ele passa por um pty e corrompe dados binarios.

DEV="${DEV:-192.168.1.100:5555}"   # ajuste: IP:porta do ADB da sua box (ou: export DEV=...)
OUT="$(dirname "$0")/../backup/$(date +%Y%m%d)"
mkdir -p "$OUT"
cd "$OUT" || exit 1

A="adb -s $DEV"
[ "$($A shell id -u | tr -d "\r")" = "0" ] || { echo "rode antes: adb -s $DEV root"; exit 1; }
PARTS="bootloader env boot super misc recovery vbmeta vbmeta_system vbmeta_vendor metadata private frp empty media_data Reserve0 mmcblk0boot0 mmcblk0boot1"

{
  $A shell 'ls -l /dev/block/by-name/; cat /proc/partitions'
  $A shell 'for p in /sys/block/mmcblk0/mmcblk0p*; do echo "$(basename $p) start=$(cat $p/start) size=$(cat $p/size)"; done'
} > particoes.txt

dump() {  # $1 = nome, $2 = comando dd na box
  local n="$1" cmd="$2"
  printf '%-14s ' "$n"
  local remote
  remote=$($A shell "$cmd 2>/dev/null | sha256sum" | awk '{print $1}')
  local localsum
  localsum=$($A exec-out "$cmd 2>/dev/null" | tee >(zstd -q -3 -o "$n.img.zst") | sha256sum | awk '{print $1}')
  sleep 1
  echo "$localsum  $n.img" >> SHA256SUMS
  if [ "$remote" = "$localsum" ]; then echo "OK  $(du -h "$n.img.zst" | cut -f1)"; else echo "ERRO: hash diferente"; fi
}

# Inicio do disco ate a particao 1 (tabela de particoes, boot0, u-boot)
START=$($A shell cat /sys/block/mmcblk0/mmcblk0p1/start | tr -d '\r')
dump header "dd if=/dev/block/mmcblk0 bs=512 count=$START"

for p in $PARTS; do
  dump "$p" "dd if=/dev/block/by-name/$p bs=1M"
done

echo "Backup em: $(pwd)"
du -sh .
