#!/bin/bash
# Limpeza da TV Box: deixa so Netflix e YouTube (+ o minimo para o Android funcionar)
#
# Uso:  ./limpeza.sh            -> so mostra o que faria (padrao, seguro)
#       ./limpeza.sh --aplicar  -> executa
#
# Usa "pm uninstall --user 0": remove o app para o usuario, mas o APK de sistema continua
# em /system, entao e reversivel com:
#   adb shell cmd package install-existing <pacote>
# Rodar SO depois do backup do eMMC e de confirmar qual e o launcher (ver ETAPA 0).

set -u
DEV="${DEV:-192.168.1.100:5555}"   # ajuste: IP:porta do ADB da sua box (ou: export DEV=...)
APLICAR=0
[ "${1:-}" = "--aplicar" ] && APLICAR=1

# Malware e droppers confirmados na analise
MALWARE=(
  com.systemguard.android            # proxy Honeygain
  com.core.rss                       # proxy CastarSDK
  com.lssa.service                   # telemetria + silentInstall
  com.android.domain                 # dropper, C2 imptor.top
  com.android.assistant.setting.iknew # atualizador/telemetria
  com.android.netservice             # dropper, C2 dnsyc.top
  com.charon.rocketfly
  com.ik.TV_Stick
  com.factorytools.factorystability
  com.android.nfx
  com.hopper.rsshub.stb              # UID de sistema, DexClassLoader, servico oculto :cskd_srvj
)

# Apps de terceiros que nao serao usados (IPTV de origem duvidosa etc.)
TERCEIROS=(
  com.global.unitviptv
  com.unitvnet.tvod
  com.world.youcinetv
  com.studiosapolo.yellowbox
  com.ionitech.airscreen
  com.android.chrome
)

# Lixo de sistema seguro de remover numa TV
LIXO=(
  com.android.egg
  com.android.music
  com.android.musicfx
  com.android.gallery3d
  com.android.htmlviewer
  com.android.bookmarkprovider
  com.android.dreams.basic
  com.android.dreams.web
  com.android.printspooler
  com.android.printservice.recommendation
  com.android.bips
  com.android.providers.calendar
  com.android.traceur
  com.android.wallpaper
  com.android.wallpapercropper
  com.android.wallpaperbackup
  com.android.dynsystem
  com.android.cts.ctsshim
  com.android.cts.priv.ctsshim
  com.android.bluetoothmidiservice
  com.android.companiondevicemanager
  com.android.hotspot2
  com.google.android.feedback
  com.google.android.apps.restore
  com.softwinner.TvdFileManager
  com.softwinner.TvdVideo
  com.softwinner.agingdragonbox
  com.softwinner.dragonbox
  com.softwinner.awlogsettings
  com.softwinner.miracastReceiver
  com.softwinner.update              # OTA do fabricante: nao queremos updates dele
)

# NAO MEXER (o sistema ou os apps mantidos dependem deles)
#   android, com.android.systemui, com.android.tv.settings, com.android.shell,
#   com.android.providers.settings/media/downloads/tv, com.android.packageinstaller,
#   com.android.permissioncontroller, com.android.webview, com.android.inputmethod.latin,
#   com.android.networkstack*, com.android.bluetooth, com.android.externalstorage,
#   com.google.android.gms, com.google.android.gsf, com.android.vending (Play Store),
#   com.google.android.youtube.tv, com.netflix.mediaclient,
#   com.allwinnertech.*, com.softwinner.settingsassist, com.softwinner.provision
#   com.android.server.telecom, com.android.providers.contacts/blockednumber, com.android.mms.service
#     (o com.android.phone depende deles; remover pode gerar travamentos)
#   me.efesser.flauncher (launcher limpo, instalado em 2026-10-29)
#
# AVALIAR AMANHA (podem ser o launcher ou parte da imagem/HDMI)
#   (com.hopper.rsshub.stb movido para MALWARE: o launcher era com.ik.TV_Stick)
#   com.rk_itvui.allapp, com.google.android.leanbacklauncher.partnercustomizer
#   com.google.android.katniss, com.google.android.tvrecommendations

adb connect "$DEV" >/dev/null 2>&1

# ETAPA 0: launcher atual (se for malicioso, instalar um launcher limpo ANTES)
echo "Launcher atual:"
adb -s "$DEV" shell cmd package resolve-activity --brief -c android.intent.category.HOME -a android.intent.action.MAIN | tail -1

remover() {
  for p in "$@"; do
    if [ $APLICAR -eq 1 ]; then
      adb -s "$DEV" shell am force-stop "$p" >/dev/null 2>&1
      printf '%-45s %s\n' "$p" "$(adb -s "$DEV" shell pm uninstall --user 0 "$p" 2>&1 | tr -d '\r')"
    else
      echo "[simulacao] removeria $p"
    fi
  done
}

# FLauncher como tela inicial ANTES de remover o TV_Stick
if [ $APLICAR -eq 1 ]; then
  adb -s "$DEV" shell cmd package set-home-activity me.efesser.flauncher/.MainActivity
else
  echo "[simulacao] definiria me.efesser.flauncher como tela inicial"
fi

echo "== Malware";   remover "${MALWARE[@]}"
echo "== Terceiros"; remover "${TERCEIROS[@]}"
echo "== Lixo";      remover "${LIXO[@]}"

[ $APLICAR -eq 0 ] && echo "Nada foi alterado. Use --aplicar para executar."
