# TV Box "R3" — Histórico completo da investigação

> Projeto de engenharia reversa ("REA") de uma TV Box genérica.
> Estação de análise: uma máquina Linux com `android-tools` (adb).
> Regra do projeto: **somente leitura na box** até autorização explícita para alterar.

---

## 1. Identificação do aparelho

| Campo | Valor anunciado | Valor real |
|---|---|---|
| Modelo | R3 | R3 / device `titan-p1` / product `walley` |
| Fabricante (props) | Google | genérico chinês, firmware Allwinner/Softwinner |
| Android | 14.1 | **Android 10** (SDK 29, build `QP1A.191105.004`) |
| Patch de segurança | — | 2019-12-05 |
| Fingerprint | `google/walley/titan-p1:14.1/QP1A.191105.004/eng.akrc8.20250917.091416:userdebug/release-keys` | build `userdebug` de 2025-09-17 |
| SoC | — | Allwinner **sun50iw9p1** (H313/H616), 4× ARMv8, rodando em 32 bits (armv8l) |
| Kernel | — | Linux 4.9.170 #41 SMP PREEMPT, 2025-09-17 |
| RAM | 8 GB | **falsificada**: `MemTotal` fixo em 8.388.608 kB, cerca de 170 MB livres |
| Armazenamento | — | eMMC de cerca de 8 GB (`mmcblk0` = 7.634.944 KB), `/data` com 3,9 GB |
| Chip ID | — | `«removido»` |
| Serial sunxi | — | `«removido»` |
| Secure boot | — | `sunxi_secure: secure`, `verifiedbootstate=green`, `flash.locked=1` |

### Partições montadas
| Dispositivo | Ponto | Tamanho | Uso |
|---|---|---|---|
| dm-0 | `/` (system) | 1,3G | 100% |
| dm-1 | `/vendor` | 165M | 100% |
| dm-2 | `/product` | 132M | 100% |
| mmcblk0p17 | `/data` | 3,9G | 48% |
| mmcblk0p7 | `/cache` | 1,0G | 1% |
| mmcblk0p11 | `/metadata` | 11M | 1% |
| mmcblk0p16 | `/Reserve0` | 16M | 1% |

---

## 2. Linha do tempo

### Vida do aparelho (pelas datas de instalação)
| Data | Evento |
|---|---|
| 2025-09-17 | Firmware compilada e gravada (kernel, `qw`, `su`, apps de sistema) |
| 2025-09-17 10:14 | `com.charon.rocketfly` instalado (fábrica) |
| 2026-05-06 03:33 | `com.android.assistant.setting.iknew` e `com.android.domain` instalados **silenciosamente** |
| 2026-05-08 07:49 | `com.hopper.rsshub.stb` instalado; `iknew` atualizado |
| 2026-05-28 09:36 | `com.lssa.service` instalado |
| 2026-06-18 07:29 | `com.systemguard.android` (Honeygain) instalado |
| 2026-07-08 08:12 | `com.core.rss` (CastarSDK) instalado |
| 2026-07-16 | `com.android.domain` e `com.core.rss` atualizados |
| 2026-09-05 | `com.hopper.rsshub.stb` atualizado |
| 2026-09-07 07:57 | `com.android.netservice` (app de sistema) atualizado via `/data/app` |

### Investigação
| Data | Etapa |
|---|---|
| 2026-10-24 | `android-tools` (adb) instalado na estação |
| 2026-10-24 | Conexão ADB em `<box>:5555`, estação autorizada na TV |
| 2026-10-24 | Levantamento de hardware, build, segurança, pacotes, processos e rede |
| 2026-10-24 | Cópia e análise estática de `qw`, `dom2reg` e 10 APKs suspeitos |
| 2026-10-24 | Teste a partir da box: vários serviços locais da estação estavam alcançáveis |
| 2026-10-24 | Aplicado `fix_firewall.sh` (Docker em 127.0.0.1, box na zona `drop`) |
| 2026-10-25 | Novo teste: parte fechou; os serviços em containers continuavam alcançáveis |
| 2026-10-25 | Criado `fix_firewall2.sh` (DOCKER-USER), aplicação **não confirmada** |
| 2026-10-25 | Medição de tráfego por 15 s: cerca de 2–3 KB/s em cada sentido, sem sinal de DDoS no momento |
| 2026-10-25 | Perdido o alcance da box; amostras da pasta temporária perdidas (reboot). Relatórios criados |
| 2026-10-25 | A estação mudou de sub-rede; a box ficou em outra. A regra `drop` para o IP da box só vale na sub-rede original |
| 2026-10-25 | Forense passiva da infraestrutura (RDAP, DNS, CT, Shodan): `03-forense-infraestrutura.md` |

---

## 3. Configuração de segurança da box

| Propriedade | Valor |
|---|---|
| `ro.build.type` | userdebug |
| `ro.build.tags` | release-keys |
| `ro.debuggable` | 1 |
| `ro.secure` | 1 |
| `ro.adb.secure` | 1 |
| `ro.boot.verifiedbootstate` | green |
| `ro.boot.flash.locked` | 1 |
| `ro.boot.vbmeta.device_state` | locked |
| SELinux | **Permissive** |
| `su` | `/system/xbin/su`, `-rwsr-sr-x root shell`, 75348 bytes |
| Usuário do shell ADB | `uid=2000(shell)`, contexto `u:r:shell:s0` |

---

## 4. Pacotes

### Apps de terceiros (`pm list packages -3`)
`com.android.assistant.setting.iknew`, `com.android.chrome`, `com.android.domain`, `com.charon.rocketfly`, `com.core.rss`, `com.global.unitviptv`, `com.hopper.rsshub.stb`, `com.ionitech.airscreen`, `com.lssa.service`, `com.netflix.mediaclient`, `com.studiosapolo.yellowbox`, `com.systemguard.android`, `com.unitvnet.tvod`, `com.world.youcinetv`

### Apps de sistema que não são do Android original
`com.allwinnertech.gmsintegration`, `com.allwinnertech.packageoverride`, `com.android.netservice`, `com.android.nfx`, `com.factorytools.factorystability`, `com.ik.TV_Stick`, `com.rk_itvui.allapp`, `com.softwinner.*` (TvdFileManager, TvdVideo, agingdragonbox, awlogsettings, dragonbox, miracastReceiver, provision, settingsassist, update)

### Pacotes suspeitos analisados
| Pacote | Caminho | Versão | UID | Permissões concedidas |
|---|---|---|---|---|
| com.android.netservice | /data/app (atualiza um app de sistema) | 3.6.0 | system (1000) | 342 |
| com.android.domain | /data/app | 1.0.6 | system (1000) | 228 |
| com.android.assistant.setting.iknew | /data/app | 1.2.8 | system (1000) | 228 |
| com.hopper.rsshub.stb | /data/app | 2.0.7 | system (1000) | 228 |
| com.charon.rocketfly | /data/app | 1.0 | system (1000) | 228 |
| com.ik.TV_Stick | /system/app/TVStick | 1.6.0 | system (1000) | 228 |
| com.factorytools.factorystability | /system/app/FactoryStability | 2.2.2 | system (1000) | 228 |
| com.lssa.service | /data/app | 2.0.1 | app | 38 (inclui localização precisa) |
| com.systemguard.android | /data/app | 2.0.1 | u0_a79 | 9 |
| com.core.rss | /data/app | 1.0.2 | u0_a80 (10080) | 7 |
| com.android.nfx | /system/app/AtvWidegtUI | v1.0.7 | u0_a59 | 0 |

---

## 5. Processos de interesse

| Usuário | Processo | Observação |
|---|---|---|
| root | `qw` (PID 1872) | daemon su, iniciado por `/system/etc/init/qw.rc` |
| root | `daemonsu:master`, `daemonsu:mount:master` | root ativo |
| root | `dom2reg` | `/vendor/etc/init/dom2reg.rc`, caps `NET_ADMIN`, ofuscado |
| root | `systemmixservice`, `isomountservice`, `gpioservice`, `multi_ir` | serviços Allwinner |
| system | `app_process ... com.softwinner.display.DisplayDaemon` | daemon de vídeo Allwinner |
| system | `com.hopper.rsshub.stb` + `:cskd_srvj` | serviço oculto |
| system | `com.android.domain`, `com.android.netservice`, `com.android.assistant.setting.iknew` | droppers |
| u0_a79 | `com.systemguard.android` | Honeygain |
| u0_a80 | `com.core.rss` | CastarSDK |

`init.sun50iw9p1.usb.rc:47` escreve `qw_sign "MSFT100"` no gadget USB. Isso é o descritor padrão de SO da Microsoft no USB, provavelmente sem relação com o daemon `qw`.

---

## 6. Rede da box

### Escutando
- TCP `0.0.0.0:14035`: UID 1041 (audioserver). **Anômalo**
- TCP `:::5555`: adbd
- UDP 5353 (mDNS), 5228 e efêmeras

### Conexões de saída suspeitas (UID 10080 = `com.core.rss`)
| Destino | Porta(s) |
|---|---|
| 207.166.164.30 | 197 (ativa), 276 (reconexões repetidas) |
| 43.130.3.96 | 175 |
| 43.102.213.193 | 116 |
| 43.102.65.55 | 159 |
| 43.102.x | 143 |
| 101.32.166.132 | 190 |

Confirmado por RDAP: `43.130.x` e `101.32.x` = Tencent Cloud; `43.102.x` = Alibaba Cloud; `207.166.164.30` = BytePlus (ByteDance). Detalhes em `03-forense-infraestrutura.md`.

### Conexões aparentemente legítimas
Netflix/Open Connect (`45.57.x`, `168.90.x`, `168.181.x`, QUIC para `168.90.227.7:443`), Google (`142.250.x`, `142.251.x`, `172.217.x`, `64.233.190.x:5228`), AWS e Cloudflare em 443 (origem não atribuída).

### DNS
`net.dns1 = <roteador>` (roteador), mas os droppers têm DoH embutido.

### Medição de tráfego (2026-10-25, 15 s, wlan0)
RX 34.710 bytes / 143 pacotes, TX 40.465 bytes / 152 pacotes.

---

## 7. Análise estática

### Binários nativos
| Arquivo | SHA-256 | Notas |
|---|---|---|
| `/system/bin/qw` (452.300 B) | `a7ca20c61f5a13d85bbd607e84edc6600f880a3bad7daaf34267eccdb98f731d` | su daemon; strings: `start the su daemon agent`, `com.koushikdutta.superuser`, `su.sqlite` |
| `/vendor/bin/dom2reg` (31.004 B) | `d9c1b3959172201f3301e9b03162f9c190e2c5124aa745ac0c575f21af1fb246` | sem strings úteis, provavelmente compactado |

### APKs
| Pacote | SHA-256 |
|---|---|
| com.android.netservice | `33feb99dfca28f97aed5ef1cbcb1c9ebfe215fcb8c54c56cd79a7efcfac1e77f` |
| com.android.domain | `5b029abe4ad2cd6dfa18064899b50190e00ce0f50bac57cbd849502ab3108f30` |
| com.android.assistant.setting.iknew | `54a9649ce848be2b29967179d462f8a6a6f5023498c1a9731101addff4c9aa96` |
| com.hopper.rsshub.stb | `e795f898552ca40c06ecf31330918d803793003da0aa6d69260a4536db7b5519` |
| com.lssa.service | `a0113e5c2670c118067568f3cf24871f747efb98f08771baca8652b51b133a49` |
| com.systemguard.android | `579d07eb81f22e665abd9ae87f6b8738dbeb28d2feb771d4f443b57e8f600549` |
| com.core.rss | `d070fd928b8ae06e6532232904c6bbac0bdc21ce078e90295c5c1cbc11de5e97` |
| com.charon.rocketfly | `8da1a29167d75c163d5052b4d9827532fbab17f027a7d9eaa28c23bbd3a47e68` |
| com.ik.TV_Stick | `45f46ebc4ac4930bd578935d5673adc92a7ff7904e025f8e208532188911de59` |
| com.android.nfx | `2ab0c4a55d689ef6a7c83ca42be1e18cf1571bc6b6804d199cd180bcf5bf145c` |

> Os arquivos foram perdidos com a limpeza da pasta temporária. Puxar de novo e conferir estes hashes; uma diferença indica que o malware se atualizou.

### Indicadores por APK
| Pacote | Destaques |
|---|---|
| netservice | `silentInstall`, `installApp [downloadFinishHandler_thirdParty]`, `Nebula-app.apk`, `heartbeat.dnsyc.top`, `business.dnsyc.top`, DoH, `assets/filter_apps.txt`, `assets/rk_filter_apps` |
| domain | `v105.imptor.top`, DoH (`doh.pub`, `dns.alidns.com`, `cloudflare-dns.com`), `www.baidu.com` (teste de conectividade?) |
| iknew | `upload-uninstall.tentvs.com`, `upload-sa.tentvs.com`, `top-channel.tentvs.com`, `upgrade.tvsetting.com`, `upgrade.boxstv.com`, `timestamp.shortv.net`, `ott.longott.com`, geo-IP |
| lssa.service | `upload-sdk*.tentvs.com`, `timestamp-sdk.tentvs.com`, `silentInstall`, `libnative_encrypt.so`, geo-IP |
| systemguard | Honeygain SDK, `DexClassLoader`, `xepith.com`, `upiral.com`, `thewsoral.com`, `nagopore.com`, `fepoth.com`, `crowsember.com`, `optimizerapi.long.tv`, `api.apiopen.top` |
| core.rss | `libszbx_sdk.so` / `libszbx_sdk_jni.so`, caminho de build `...\castar_sdk\...`, `TcpTunnelPipeline`, "Auth payload sent to route server" |
| hopper.rsshub.stb | `DexClassLoader`, `upload.mytvos.com`, geo-IP (4 serviços), `click_url`, `evaluateJavascript` |
| TV_Stick | sem C2 evidente nas strings; analisar com jadx |
| rocketfly, nfx | pequenos, sem indicadores nas strings |

---

## 8. Indicadores de comprometimento (IoCs)

**Domínios**
```
dnsyc.top            heartbeat.dnsyc.top    business.dnsyc.top
imptor.top           v105.imptor.top
tentvs.com           shortv.net             longott.com
boxstv.com           tvsetting.com          mytvos.com
long.tv              apiopen.top
xepith.com  upiral.com  thewsoral.com  nagopore.com  fepoth.com  crowsember.com
```

**IPs**
```
207.166.164.30   43.130.3.96   43.102.213.193   43.102.65.55   101.32.166.132
```

**Pacotes**
```
com.android.netservice  com.android.domain  com.android.assistant.setting.iknew
com.hopper.rsshub.stb   com.lssa.service    com.systemguard.android
com.core.rss            com.charon.rocketfly com.ik.TV_Stick  com.android.nfx
```

---

## 9. Impacto na estação de análise

Veja `01-vulnerabilidades-e-riscos.md`, seção 3. Em resumo: os serviços locais que escutavam na estação foram fechados para a box; os que rodavam em containers exigiram as regras de `DOCKER-USER` (seção 12).

---

## 10. Pendências (próxima sessão)

1. Reconectar: `adb connect <box>:5555`
2. Confirmar o bloqueio dos serviços em containers: testar a partir da box
3. Puxar de novo `qw`, `dom2reg` e os 10 APKs e conferir os hashes
4. Descobrir quem é dono da porta 14035
5. Instalar Java (JDK 21) e o jadx, e descompilar netservice, core.rss e systemguard
6. ~~Whois dos IPs e domínios~~ (feito em 2026-10-25, ver `03-forense-infraestrutura.md`)
7. Decidir o destino da box: desativar apps, regravar firmware ou descartar

---

## 11. Decisões

| Data | Decisão |
|---|---|
| 2026-10-25 | Manter o Android e limpar (não trocar de sistema), para preservar Netflix e YouTube |
| 2026-10-25 | Apps a manter: **somente Netflix e YouTube**, mais o mínimo do sistema (Play Store/GMS, Configurações, launcher) |
| 2026-10-25 | Dongle do mouse fica dedicado à box (não usar no estação) |
| 2026-10-25 | Script `scripts/limpeza.sh` preparado (modo simulação por padrão); rodar só depois do backup do eMMC e da checagem do launcher |

### Itens a verificar antes da limpeza
- Launcher atual (`com.hopper.rsshub.stb` é suspeito e pode ser o launcher)
- Versão da Netflix, nível de Widevine, certificação Play Protect
- Receptor IR (`getevent` enquanto aperta o controle)

---

## 12. Correção do firewall da estação (2026-10-29)

| Etapa | Resultado |
|---|---|
| Teste a partir da box (início) | parte dos serviços locais estava **aberta** de novo (regressão da blindagem do dia 25) |
| Diagnóstico | `fix_firewall2.sh` gravou regras `--direct`; a versão IPv6 aponta para `DOCKER-USER`, inexistente no ip6tables, e o firewalld entrava em **FAILED** a cada reload, perdendo a zona `drop` |
| `fix_firewall4.sh` | Regras direct removidas offline, config validada, firewalld `running`, box de volta à zona `drop`, policy `wifi-para-docker` (public→docker, REJECT) criada |
| Teste | serviços comuns fechados; os **em containers continuavam alcançáveis**: o tráfego DNAT do Docker não é barrado por zona/policy do firewalld |
| `fix_firewall5.sh` | Drop-in `/etc/systemd/system/docker.service.d/wifi-bloqueia-docker.conf` → `iptables -I DOCKER-USER -i <iface-wifi> -m conntrack --ctstate NEW -j DROP` a cada start do Docker |
| Teste final | **todos os serviços locais fechados** a partir da box; acesso local e saída dos containers preservados |

Notas:
- `fix_firewall2.sh` está **obsoleto**: não rodar de novo.
- Um dos serviços rodava em `network_mode: host` (fora das regras do Docker; barrado pela zona `public`).
- Launcher atual da box: `com.ik.TV_Stick/com.starmax.launcher.MainActivity` (**malicioso**). Instalar um launcher limpo antes da limpeza.

## 13. Backup e preparação da limpeza (2026-10-29)

- Backup das partições de sistema em `backup/20261029/` (868 MB, zstd): header (setores 0–73727: tabela, boot0, u-boot), bootloader, env, boot, super, misc, recovery, vbmeta*, metadata, private, frp, empty, media_data, Reserve0, mmcblk0boot0/1. **18/18 SHA-256 conferidos** (box × estação). Fora: UDISK (/data) e cache.
- Primeira tentativa via `su` corrompeu os dados (pty converte LF→CRLF, +22 KB no header). Refeito com `adb root` (firmware userdebug); depois `adb unroot`.
- Play Store não pesquisa (log: `IllegalStateException: More than one auth provider provided result`).
- Launchers disponíveis: só `com.ik.TV_Stick` (malicioso) e o FallbackHome. Instalado **FLauncher 0.18.0** (`me.efesser.flauncher`), APK baixado pelo usuário do GitLab oficial; SHA-256 `376fc528c880cdf7c7c04b2d3708c69f911144498218babb6300808b772af32e`; assinado por "Étienne Fesser" (cert SHA-256 `E0:17:F5:B7:...:80:46`); permissões INTERNET e WAKE_LOCK.
- Netflix instalada = **app de celular** 9.22.1 (sem LEANBACK_LAUNCHER, `installer=null`, nunca atualizada); a versão de TV é `com.netflix.ninja`.
- Widevine: `liboemcrypto.so` + OP-TEE presentes; nível real (L1/L3) não confirmado.
- IR: receptor `sunxi-ir` (NEC) presente, 15 mapas `customer_ir_*.kl`; nenhum evento em 2 capturas. Controle não pareado (verificar depois).
- Mouse: `Logitech USB Receiver`.
- `limpeza.sh`: `com.hopper.rsshub.stb` movido para MALWARE; telecom/contatos/mms mantidos (dependências do com.android.phone); FLauncher definido como tela inicial antes das remoções.

## 14. Análise offline do sistema pelo backup (2026-10-29)

`super` extraída no estação (parser LP próprio + `debugfs rdump`, em RAM, sem montar): system 1420 MiB, vendor 167 MiB, product 134 MiB (ext4), 2.978 arquivos.

### Mecanismos de fábrica encontrados
| Serviço | Arquivo | Gatilho | O que faz |
|---|---|---|---|
| `qw` | `/system/bin/qw` (`/system/etc/init/qw.rc`) | boot (classe core), root | daemon su |
| **`rootservice`** | `/vendor/bin/rootservice` (`/vendor/etc/init/hw/init.root.rc`) | `sys.boot_completed=1`, root | executa `/system/xbin/daemonsu --auto-daemon &`. A condição original `persist.vendor.rootservice=1` foi **comentada**: o root sobe sempre |
| — | `/system/xbin/su`, `/system/xbin/daemonsu`, `/system/xbin/supolicy` | — | kit SuperSU (supolicy reescreve a política SELinux) |
| **`appsdisable`** | `/system/bin/appsdisable` (script) | primeiro boot, root | `pm disable` em **todos os receivers BOOT_COMPLETED de pacotes com.google.android** → provável causa dos problemas da Play Store/GMS |
| **`preinstall`** | `/system/bin/preinstall` (script) | `sys.boot_completed=1`, shell | instala uma vez cada APK de `/*/preinstall` (marcador em `/data/local/tmp/preinstalled`) |
| `format_device` | `/system/bin/format_device` | boot | formata `Reserve0` (Allwinner, provavelmente benigno) |
| `DisplayDaemonService` | script → `DisplayDaemon.jar` | boot | daemon de vídeo Softwinner (benigno) |

### `/system/preinstall` (reinstalados após reset de fábrica)
`AirScreen.apk` (80 MB), `chrome126.0.6478.apk`, `Google_7.3.20230424.9.apk`, `GoogleServicesFramework.apk`, `Netflix_9.22.1.apk` (app de celular), **`SkyRocketFly.apk` = `com.charon.rocketfly`** (113.847 B, mesmo tamanho).

### Apps maliciosos dentro de `/system/app` (voltam após reset)
`netserevice-release` (= `com.android.netservice`), `TVStick` (launcher `com.ik.TV_Stick`), `FactoryStability`, `AtvWidegtUI` (`com.android.nfx`). `LauncherCustomizerak` em priv-app (sufixo "ak", ver `akrc8`/`akrdinfo`) a analisar.

### Verificado e aparentemente limpo
- `framework.jar`, `services.jar`, `ext.jar`: sem URLs ou pacotes estranhos; `libandroid_runtime.so` sem strings suspeitas. Sem artefatos conhecidos de Vo1d (`wd`, `vo1d`, `install-recovery.sh`).
- Nenhuma string dos IoCs de rede no sistema: os domínios C2 só aparecem nos apps de `/data` (baixados depois) e em `netservice`.
- Acertos em SystemUI/TvSettings/Tubesky eram falsos positivos (`tvsettingssliceprovider` do Google). `Tubesky` = Play Store renomeada.

### Implicações
1. `pm uninstall --user 0` remove os apps, mas **o root (`qw`, `rootservice`/`daemonsu`) fica**: está em `/system`/`/vendor`, protegido por dm-verity.
2. Firmware `userdebug` permite `adb disable-verity` + `adb remount` → seria possível apagar `su`/`daemonsu`/`qw.rc`/`init.root.rc` e os APKs de `/system/app` de forma permanente (fase 2, opcional; reverter = gravar `super`/`vbmeta` do backup).
3. Após um reset de fábrica, `preinstall` reinstala o SkyRocketFly, e `netservice`/`TVStick` voltam; repetir a limpeza nesse caso.
4. Reativar os receivers Google desativados pelo `appsdisable` pode consertar a Play Store.

## 15. Limpeza, etapa 1: malware removido (2026-10-29, com a Netflix aberta)

Removidos com `pm uninstall --user 0` (todos `Success`): `com.systemguard.android`, `com.core.rss`, `com.lssa.service`, `com.android.domain`, `com.android.assistant.setting.iknew`, `com.android.netservice`, `com.hopper.rsshub.stb`, `com.charon.rocketfly`, `com.factorytools.factorystability`, `com.android.nfx`.

| | Antes | Depois |
|---|---|---|
| Conexões TCP UID 10080 (CastarSDK) | 8 | 0 |
| Conexões TCP UID 1000 (droppers) | 6 | 0 |
| Processos maliciosos | 10 | 0 |
| Netflix (UID 10073) | ativa | ativa, sem interrupção |

- `com.ik.TV_Stick` **mantido** por enquanto (é o launcher; sai junto com a troca para o FLauncher).
- Porta **14035 continua escutando** (UID 1041 audioserver) após a remoção: não pertencia aos apps maliciosos. Investigar.
- Pendente: trocar a tela inicial e remover o TV_Stick, os terceiros, o lixo, reiniciar, testar e reativar os receivers Google (`appsdisable`).

## 16. Limpeza, etapa 2: versão reduzida + reboot (2026-10-29)

- `cmd package set-home-activity me.efesser.flauncher/.MainActivity` → Success.
- Removidos (`pm uninstall --user 0`, todos Success): `com.ik.TV_Stick`; terceiros `com.global.unitviptv`, `com.unitvnet.tvod`, `com.world.youcinetv`, `com.studiosapolo.yellowbox`, `com.ionitech.airscreen`, `com.android.chrome`; sistema `com.android.egg`, `music`, `musicfx`, `gallery3d`, `printspooler`, `printservice.recommendation`, `bips`, `dreams.basic`, `dreams.web`, `com.softwinner.update`, `agingdragonbox`, `dragonbox`, `cts.ctsshim`, `cts.priv.ctsshim`.
- Adiados por risco de dependência: `google.feedback`, `apps.restore`, `providers.calendar`, `wallpaper*`, `softwinner.TvdVideo/TvdFileManager/miracastReceiver/awlogsettings`, `htmlviewer`, `traceur`, `dynsystem`, `hotspot2`, `companiondevicemanager`, `bluetoothmidiservice`, `bookmarkprovider`.

### Após o reboot
| Verificação | Resultado |
|---|---|
| Tela inicial | FLauncher |
| ADB por rede | continuou ativo |
| Apps de terceiros | só `me.efesser.flauncher` e `com.netflix.mediaclient` |
| Algum malicioso voltou? | nenhum |
| Conexões externas | só Google (AS15169): Katniss, GMS/GSF; nenhuma para IoCs |
| RAM disponível | 290 MB (antes cerca de 170 MB) |
| Root de fábrica | **continua**: `qw`, `daemonsu:master`, `daemonsu:mount:master`, `dom2reg` rodando (fase 2) |

## 17. Descompilação do `services.jar` (jadx 1.5.6, 2026-10-29)

| Achado | Local | Avaliação |
|---|---|---|
| `Slog.d("willi1", "pkg name " + ...)` + largura fixa 1280 para `com.trioscope.chameleon` | `WindowManagerService.relayoutWindow` (linha ~1558) | log de depuração do fabricante: **benigno** |
| `" start  launcher  !!!!  "` | `ActivityRecord.setState`, estado DESTROYED (~1490) | log enganoso; ao destruir FallbackHome encerra a animação de boot: **benigno** |
| **Bloqueio de apps de diagnóstico de hardware** | `PackageManagerService` (~11128) | instalação de `flar2.devcheck`, `org.integrityaction.devcheck`, `com.liuzh.deviceinfo`, `com.finalwire.aida64`, `ru.andr7e.deviceinfohw`, `com.ytheekshana.deviceinfo`, `com.cpuid.cpu_z`, `com.abs.cpu_z_advance` retorna **-19 (INSTALL_FAILED_INVALID_INSTALL_LOCATION)**. **Serve para esconder as especificações falsas** (RAM/Android) |
| Atalhos de teclas do controle para Netflix, Prime Video, Disney+ e AllApp | `TvWindowManager` | benigno (botões do controle) |
| `DexClassLoader("system/framework/softwinner.audio.jar")` | `SystemServer` | carrega jar do próprio sistema (Allwinner): benigno |
| `Runtime.exec` em `NewNetworkTimeUpdateService` | sincronização de hora | método utilitário; sem URLs externas |

Sem URLs de C2, sem pacotes dos operadores, sem carregamento de código de `/data`. **O framework não tem backdoor**; tem fraude de especificação (bloqueio dos apps que revelariam o hardware real).

## 18. Play Store (2026-10-29)

- `appsdisable` deixou desativados (entre outros) `com.android.vending/androidx.work...RescheduleReceiver`, `gms ...GmsIntentOperationService$PersistentTrustedReceiver`, `gsf ...MigrateToAccountManagerBroadcastReceiver`: **reativados** via `adb root` + `pm enable` (shell comum recebe SecurityException). `GcmInternalReceiver`, `CheckinServiceLegacyGcmTriggerReceiver`, `OneTimeInitializerReceiver` não existem mais nesta versão do GMS (restos). Outros componentes desativados (nearby, car, OCR...) são desativados pelo próprio GMS em TV: mantidos.
- `pm clear com.android.vending` executado (dados da loja zerados; conta Google preservada).
- Play Store **funciona** (abre página de app, conta OK). O botão de busca **não responde a clique de mouse** (nenhum START nem pedido de IME; `show_ime_with_hard_keyboard` já era 1). Contorno: abrir busca ou página por intent (`market://search?q=...`, `market://details?id=...`).
- `com.netflix.ninja` (Netflix de TV) na Play Store: **"Item is not available. Reason: 9"**, aparelho incompatível/não certificado. A Netflix de TV não é oferecida para esta box.

## 19. Netflix atualizada (2026-10-30)

- Instalada: `com.netflix.mediaclient` 9.22.1 (de `/system/preinstall`), cert v1 `META-INF/NFPPDKEY.RSA` = "Netflix, Inc., Los Gatos, CN=PPD Builder", SHA-256 `363863596ea99241eb71b1a985553aa604de3ea3c5f0c546742390e682164e6b` → **legítima**.
- Nova: APKMirror `com.netflix.mediaclient_9.90.0_build_10_74712...apkm` (SHA-256 `d9ad285ce4f5f3d2f419f018a3ec7ed9a7f734d3fe01cc4803d8a9dd6952fbf3`), min_api 28. Cert v3 de base e splits = **idêntico** ao instalado (verificado com `scratchpad/tools/apkcert.py`, parser próprio do APK Signing Block).
- `adb install-multiple -r` base + `armeabi_v7a` + `pt` + `en` + `tvdpi` → Success. Versão 9.90.0 build 10 74712, armeabi-v7a.

## 20. Investigações antes da fase 2 (2026-10-30)

### Porta 14035 → benigna
`0.0.0.0:14035` LISTEN, inode 5352, dono **pid 1826 `/vendor/bin/hw/android.hardware.audio@2.0-service`** (HAL de áudio Allwinner, UID 1041). Não tem relação com o malware. Exposta para a LAN, mas é do fornecedor; avaliar bloqueio depois.

### `dom2reg` → benigno
SHA-256 `d9c1b395…fb246` (igual ao de 24/10). Não compactado (entropia 4,57 bits/byte; sem UPX). Usa libnl/genetlink (nl80211), `property_get`, 415 nomes de fuso horário e códigos de país de 2 letras, sem strings de rede/URL/exec. Função: **converte o fuso horário em domínio regulatório de Wi-Fi** ("domain to regulatory"); o `NET_ADMIN` serve para isso. Fica fora da fase 2.

### Widevine → L3 (definitivo)
`WVCdm: LoadLevel1 Could not find /factory/wv.keys. Falling Back to L3`; `OEMCrypto_IsKeyboxOrOEMCertValid return 28` (keybox inválido/ausente); `UsageTableHeader security level: 3`; só existe `/data/vendor/mediadrm/IDM1013/L3`. O `keybox_list=widevine` do bootloader não tem chave gravada. **Netflix limitada a SD** (L3); não há correção legítima.

### Resolução
HDMI em **1920x1080@60** (`/sys/class/disp/disp/attr/sys`: `hdmi output mode(10)`), mas a interface do Android é desenhada em **1280x720** e ampliada pelo hardware (`fb[1280,720] → frame[1920,1080]`; `wm size` 1280x720; density 213). Apps limitados pela resolução da tela (ex.: YouTube) tendem a ficar em 720p.

## 21. Controle remoto (2026-10-30)

- Receptor IR: `/sys/devices/platform/soc/7040000.s_cir`, rc0, só protocolo `[nec]` disponível. Interrupção `RemoteIR_RX` (IRQ 275) = **0 desde o boot**, inclusive durante 60 s de botões apertados → **nenhum sinal IR chega ao receptor**, de qualquer protocolo.
- Bluetooth: `SystemServer: isBluetoothSupport: false`; serviço `bluetooth_manager` inexistente; `rfkill sunxi-bt state=0`. Módulo Wi-Fi **SSV6x5x** (driver `ssv6x5x`), que não tem Bluetooth. A box **não tem Bluetooth funcional**, embora o HAL de áudio traga o driver de controle BLE com microfone `BLEAudioDrive_HV409` (vendor 0x1d5a, "aikeweida"), da plataforma genérica.
- Conclusão: o controle só pode ser IR, e o receptor não recebe nada. Ou o controle não emite (pilha/defeito), ou o receptor está ausente/desconectado na placa. Pendente: teste da câmera do celular e teste com outro controle IR.
- Alternativa: **air mouse / controle 2,4 GHz com dongle USB** (setas, OK, voltar, home, teclado), que funciona como o mouse atual, sem IR nem Bluetooth.
- Teste da câmera do celular: **o LED do controle pisca**, ou seja, o controle emite.
- Teste direcional (90 s, controle a ~10 cm de todos os lados da box): `RemoteIR_RX` continuou em **0**. Conclusão: receptor ausente, defeituoso, desconectado ou ligado num pino diferente do device tree. Não há correção por software sem inspecionar a placa. Opções: abrir a box e fotografar a placa, ou usar um air mouse 2,4 GHz.

## 22. Fase 2: root de fábrica removido (2026-10-30)

### Pré-checagem
- `dmctl table`: system/vendor/product são alvos **`linear`** sobre `super` (179:4): **sem dm-verity**. Não foi necessário `adb disable-verity` nem mexer em `vbmeta`.
- ext4 `s_feature_ro_compat = 0x7b` (sem `shared_blocks` 0x4000): remontável rw direto, sem overlayfs.

### Execução (`adb root`)
1. Cópia de cada item para `backup/fase2_removidos/` (18 arquivos, 43 MB, `SHA256SUMS`). `su` = `daemonsu` (`ae3ef435…0bee`); `qw` = `a7ca20c6…731d` (igual ao de 24/10); `rootservice` = `94e405dc…63d3`.
2. `blockdev --setrw` dm-0/dm-1, `mount -o remount,rw` em `/` e `/vendor`.
3. Removidos: `/system/xbin/su`, `/system/xbin/daemonsu`, `/system/xbin/supolicy`, `/system/bin/qw`, `/system/etc/init/qw.rc`, `/vendor/bin/rootservice`, `/vendor/etc/init/hw/init.root.rc`, `/system/app/netserevice-release`, `/system/app/TVStick`, `/system/app/FactoryStability`, `/system/app/AtvWidegtUI`, `/system/preinstall/SkyRocketFly.apk`.
4. `sync`; `/vendor` voltou a ro (`/` ficou "busy" até o reboot); reboot.

### Depois do reboot
| Verificação | Resultado |
|---|---|
| Boot | normal, FLauncher; Netflix e YouTube abrem |
| ADB por rede | voltou sozinho (primeiros ~2 min sem resposta a ping/ARP enquanto o Wi-Fi subia) |
| Processos `qw` / `daemonsu` / `rootservice` | nenhum |
| `su` no sistema | não existe |
| `/`, `/vendor`, `/product` | montados **ro** |
| `netservice`, `TV_Stick`, `factorystability`, `nfx`, `rocketfly` | sumiram também de `pm list packages -u` (não voltam com reset) |
| Conexões externas | só Netflix, YouTube, Katniss, GMS |

### Como reverter
Copiar de volta os arquivos de `backup/fase2_removidos/` (mesmo procedimento de remount) ou regravar `super` do backup de 29/10.

### Ainda presentes (aceitos)
`appsdisable` e `preinstall` (scripts de primeiro boot), build `userdebug` (`adb root` continua disponível) e SELinux permissive (cmdline do boot).

## 23. Rescan e endurecimento (2026-10-30)

- Rescan completo registrado em `04-relatorio-geral.md` (seção 4).
- **Câmera/microfone:** 0 câmeras (`media.camera`), sem `/dev/video*`, USB só com o receptor **Logitech Lightspeed `046d:c539`** (não Unifying; corrige a seção 13). O codec do SoC tem endpoints de captura (`pcmC0D0c` etc.), mas não há microfone conhecido na placa nem Bluetooth. Captura de imagem impossível; de áudio, improvável (confirmar ao abrir a box).
- `com.softwinner.miracastReceiver` (UID 1000, INSTALL/DELETE_PACKAGES, MASTER_CLEAR, REBOOT...) → `pm uninstall --user 0` **Success**.
- `REQUEST_INSTALL_PACKAGES` → `appops set ... deny` para `com.netflix.mediaclient` e `me.efesser.flauncher`.
- **Achado: permissões perigosas concedidas como permissões de instalação.** A plataforma declara CAMERA/RECORD_AUDIO/ACCESS_FINE_LOCATION como `prot=dangerous`, mas a Netflix (instalada por nós via `adb install-multiple`, targetSdk 35) as recebeu na seção **install permissions** com `granted=true`, sem perguntar; `pm revoke` não tem efeito. Contagem de perigosas auto-concedidas: Netflix 4, YouTube 2, Katniss 18, Play Store 10, FLauncher 0 (não pede nenhuma). Indica modificação no PackageManager da firmware: **qualquer app instalado recebe câmera/microfone/localização sem pedir**. Mitigação aplicada: `appops set com.netflix.mediaclient CAMERA ignore` e `RECORD_AUDIO ignore`.
- **Item 2 aplicado:** `settings put global package_verifier_enable 1`, `global verifier_verify_adb_installs 1`, `secure install_non_market_apps 0` (conferidos).
- **Correção:** a afirmação da seção 4.4/23 de que Netflix e FLauncher tinham `REQUEST_INSTALL_PACKAGES` estava errada: `appops get` imprime "Default mode: allow" para qualquer app. Conferindo os pacotes que **pedem** a permissão, só `com.softwinner.TvdFileManager` pede (modo padrão = não permitido); foi negado explicitamente. O `deny` aplicado a Netflix/FLauncher é inofensivo.

## 24. Limpeza final de apps inúteis (2026-10-30)

- Removidos (`pm uninstall --user 0`, todos Success): `com.softwinner.TvdVideo`, `com.softwinner.TvdFileManager`, `com.softwinner.awlogsettings`, `com.android.htmlviewer`, `com.android.bookmarkprovider`, `com.android.traceur`, `com.android.dynsystem`, `com.android.hotspot2`, `com.android.companiondevicemanager`, `com.android.bluetoothmidiservice`, `com.android.wallpaper`, `com.android.wallpapercropper`, `com.android.wallpaperbackup`, `com.google.android.katniss`, `com.google.android.tvrecommendations`.
- Configurações órfãs limpas: `enabled_notification_listeners` = vazio (era tvrecommendations); `enabled_input_methods` = só `LatinIME` (tinha Leanback IME não instalado e a voz do Katniss).
- Teste: YouTube, Netflix e Play Store abrem; Home volta ao FLauncher; 0 crashes no buffer `crash`. Pacotes ativos: 87 → 71. RAM disponível ~268 MB logo após os testes.
- Mantidos (opcionais não removidos): `google.android.feedback`, `apps.restore`, `providers.calendar`, `rk_itvui.allapp`.
