# TV Box "R3": relatório geral (estado em 2026-10-30)

> Consolida o trabalho de 24 a 30/10/2026. Detalhes técnicos: `02-historico-completo.md` (seções 1–22) e `03-forense-infraestrutura.md`.
> Aparelho: TV Box genérica Allwinner H313 (sun50iw9), IP `<box>`, Wi-Fi SSV6x5x, eMMC de 8 GB.

---

## 1. Resumo

A box veio de fábrica com **root aberto**, **instaladores silenciosos** e, depois da compra, recebeu dois **proxyware** (Honeygain e CastarSDK) que revendiam a conexão de internet do usuário. A firmware também **mente sobre as especificações** (Android 14 / 8 GB de RAM) e bloqueia apps que revelariam o hardware real.

Hoje:
- **todo o malware conhecido foi removido**, inclusive de `/system` (não volta com reset de fábrica);
- **o root de fábrica foi apagado** (`su`, `daemonsu`, `supolicy`, `qw`, `rootservice`);
- a box usa um **launcher limpo** (FLauncher) e só tem Netflix e YouTube como apps de uso;
- a **estação de análise** foi blindada contra a box e contra a rede Wi-Fi;
- há **backup completo** das partições de sistema e cópia de cada arquivo removido.

---

## 2. O que foi feito (cronologia)

| Data | Etapa | Resultado |
|---|---|---|
| 24/10 | Instalação do `android-tools` (adb), conexão ADB | acesso à box |
| 24/10 | Levantamento só leitura: hardware, build, apps, processos, rede | specs falsas, `userdebug`, SELinux permissive, root `qw`, 11 apps maliciosos, conexões para Ásia |
| 24/10 | Análise estática de 10 APKs e 2 binários | proxyware Honeygain e CastarSDK; droppers com `silentInstall`; C2 `dnsyc.top`, `imptor.top`, `tentvs.com` |
| 24/10 | Teste de portas da estação a partir da box | vários serviços locais alcançáveis pela box |
| 24–29/10 | Firewall da estação (`fix_firewall.sh`, `4`, `5`) | todos os serviços locais fechados para a box/Wi-Fi; `fix_firewall2.sh` quebrou o firewalld e foi revertido |
| 25/10 | Forense passiva da infraestrutura (RDAP, DNS, CT, Shodan) | 5 clusters; ligação provável firmware (`akrc8`) ↔ C2 (`akrdinfo.cn`) |
| 29/10 | Backup do eMMC (18 partições, SHA-256 conferido) | `backup/20261029/`, 868 MB |
| 29/10 | Análise offline do sistema (super → system/vendor/product) | `rootservice`, `appsdisable`, `preinstall`; framework sem backdoor |
| 29/10 | Instalação do FLauncher (assinatura conferida) | launcher limpo |
| 29/10 | Limpeza fase 1: 10 maliciosos + TV_Stick + 6 terceiros + 14 de sistema | conexões C2/proxy zeradas; RAM livre 170 → 290 MB |
| 29/10 | `services.jar` descompilado (jadx) | logs `willi1` benignos; **bloqueio de CPU-Z/AIDA64/DevCheck** para esconder specs |
| 29/10 | Play Store: receivers reativados, dados limpos | loja funciona; busca não aceita clique de mouse |
| 30/10 | Netflix 9.22.1 → **9.90.0** (assinatura Netflix, Inc. conferida) | parou de pedir atualização |
| 30/10 | Porta 14035, `dom2reg`, Widevine, resolução | benignos; Widevine **L3** (sem keybox); UI 720p ampliada para 1080p |
| 30/10 | Controle remoto | controle emite, receptor IR não recebe nada; box sem Bluetooth |
| 30/10 | **Fase 2**: root e APKs maliciosos apagados de `/system` e `/vendor` | boot normal; zero arquivos setuid; sistema ro |
| 30/10 | **Rescan completo** (este relatório) | ver seção 4 |

---

## 3. Estado atual da box

| Item | Estado |
|---|---|
| Launcher | FLauncher 0.18.0 (`me.efesser.flauncher`) |
| Apps de uso | Netflix 9.90.0, YouTube 5.30.340, Play Store |
| Câmera / microfone | sem câmera; microfone improvável (codec tem captura, placa provavelmente não). Netflix bloqueada para câmera/microfone |
| Malware conhecido | **nenhum** (nem em `/data`, nem em `/system`) |
| Root de fábrica | **removido** |
| Conexões externas | só Netflix, YouTube, Google |
| RAM livre | ~290 MB (antes ~170 MB) |
| Netflix | SD (Widevine L3, sem chave de fábrica; sem correção legítima) |
| Controle remoto | não funciona (receptor IR não recebe sinal) → usando mouse USB Logitech |

---

## 4. Rescan completo (30/10, após a fase 2)

### 4.1 Root, reanalisado

| Verificação | Resultado |
|---|---|
| Arquivos setuid/setgid em `/system`, `/vendor`, `/product`, `/odm`, `/data` | **0** |
| `su`, `daemonsu`, `supolicy`, `superuser`, `busybox`, `magisk*` em qualquer lugar | **nenhum** |
| `/data/adb`, scripts em `/data` | vazio / nenhum |
| Processos root | só do Android/Allwinner: `init`, `ueventd`, `vold`, `netd`, `installd`, `zygote`, `apexd`, `storaged`, `tee_supplicant`, `adbd`, `dom2reg`, `crda.uevent`, `gpioservice`, `isomountservice`, `multi_ir`, `systemmixservice`, `iptables-restore` |
| Serviços init `qw`, `rootservice` | **não existem mais** |
| Propriedade órfã `persist.vendor.rootservice=1` | inofensiva (o serviço foi apagado) |
| `adb root` | **ainda disponível** (build `userdebug`): quem tiver acesso ADB vira root |
| SELinux | **Permissive** (forçado na linha de comando do boot) |

### 4.2 Pacotes
87 pacotes: 7 em `/data` (Play Store, GMS, Katniss, TV Recommendations, YouTube, Netflix, FLauncher), o resto de sistema. Nenhum pacote dos operadores. 14 apps de sistema desinstalados para o usuário (fase 1).

Apps com **UID de sistema (1000)**: os do Android (`android`, `tv.settings`, `providers.settings`, `keychain`, `telecom`, etc.) e **`com.softwinner.miracastReceiver`** (Allwinner).

### 4.3 Permissões perigosas concedidas (apps fora do núcleo)

| App | Permissões relevantes | Avaliação |
|---|---|---|
| **`com.softwinner.miracastReceiver`** | INSTALL_PACKAGES, DELETE_PACKAGES, MASTER_CLEAR, REBOOT, MANAGE_USERS, WRITE_SECURE_SETTINGS, READ_LOGS, INTERACT_ACROSS_USERS, CHANGE_COMPONENT_ENABLED_STATE, câmera, microfone, localização, contatos | **risco alto**: receptor de rede com poderes de sistema. Remover |
| `com.netflix.mediaclient` | CAMERA, RECORD_AUDIO, armazenamento | câmera e microfone desnecessários na TV: revogar |
| `com.google.android.katniss` | localização, câmera, microfone, contatos, CAPTURE_AUDIO_OUTPUT | assistente Google: esperado; dispensável sem controle com microfone |
| `com.google.android.tvrecommendations` | WRITE_SECURE_SETTINGS, SYSTEM_ALERT_WINDOW; listener de notificações | Google: esperado |
| `com.softwinner.settingsassist` | REBOOT | do fabricante: manter (configurações de tela/HDMI) |
| `com.softwinner.provision` | MANAGE_USERS, WRITE_SECURE_SETTINGS | assistente de primeiro uso: manter |
| `com.softwinner.TvdVideo`, `TvdFileManager` | armazenamento, internet | inúteis: remover |
| FLauncher, YouTube | internet (YouTube também microfone) | ok |

### 4.4 Configurações de segurança

| Configuração | Valor | Avaliação |
|---|---|---|
| `package_verifier_enable` (Play Protect / verificação de apps) | era **0** → **1** em 30/10 | corrigido |
| `install_non_market_apps` (fontes desconhecidas) | era **1** → **0** em 30/10 | corrigido |
| REQUEST_INSTALL_PACKAGES | só `com.softwinner.TvdFileManager` pede (modo padrão = não permitido) | correção: a leitura anterior (FLauncher/Netflix) era o "Default mode: allow" do appops, não uma concessão real. Negado explicitamente em 30/10 |
| `adb_enabled` / opções do desenvolvedor | 1 / 1 | necessário durante o trabalho; **desligar a depuração por rede quando terminar** |
| Administradores de dispositivo | nenhum | ok |
| Serviços de acessibilidade | nenhum | ok |
| VPN / proxy global / CAs de usuário | nenhum | ok |
| DNS privado | não configurado | opcional |
| Localização | desligada (`location_mode=0`) | ok |
| Teclados habilitados | LatinIME (padrão), Katniss voz, **Leanback IME (pacote não instalado)** | entrada órfã, inofensiva |
| **Permissões perigosas** | concedidas como "install permissions" (sem pedir; `pm revoke` não funciona) | **firmware modificada**: todo app instalado ganha câmera/microfone/localização. Mitigar com `appops ... ignore` e evitando instalar apps |

### 4.5 Rede da box

| Porta | Processo | Exposição | Avaliação |
|---|---|---|---|
| TCP 5555 | adbd | rede local | **desligar quando não estiver em uso** |
| TCP 9080 | Netflix | rede local | servidor de "segunda tela" da Netflix (normal) |
| TCP 14035 | HAL de áudio Allwinner | rede local | do fabricante; sem função conhecida (provável áudio do controle de voz) |
| UDP 5353/56417/42682 | mdnsd | rede local | descoberta de rede (normal) |
| UDP 5228 | GMS | — | push do Google (normal) |
| TCP 5037 | adbd | só localhost | normal |

### 4.6 Resíduos de fábrica (aceitos)
- `appsdisable` (desativa receivers Google no primeiro boot) e `preinstall` (instala `/system/preinstall/*.apk` uma vez): só agem após reset de fábrica. Em `preinstall` restam AirScreen, Chrome, Google, GSF e Netflix 9.22.1 (o SkyRocketFly foi apagado).
- Bloqueio de apps de diagnóstico no `services.jar` (fraude de especificação, sem risco de segurança).
- `rk_itvui.allapp`, `allwinnertech.*`, `softwinner.provision/settingsassist`: do fabricante, sem comportamento malicioso encontrado.

---

## 5. Apps inúteis que ainda podem sair

Todos removíveis com `pm uninstall --user 0` (reversível com `cmd package install-existing`).

### Recomendados (seguros)
| Pacote | O que é |
|---|---|
| **`com.softwinner.miracastReceiver`** | receptor Miracast com UID de sistema (**prioridade: segurança**) |
| `com.softwinner.TvdVideo` | player de vídeo da Allwinner |
| `com.softwinner.TvdFileManager` | gerenciador de arquivos da Allwinner |
| `com.softwinner.awlogsettings` | configuração de logs do fabricante |
| `com.android.htmlviewer` | visualizador HTML (só para textos legais) |
| `com.android.bookmarkprovider` | favoritos de navegador (não há navegador) |
| `com.android.traceur` | rastreamento de sistema para desenvolvedores |
| `com.android.dynsystem` | instalação de sistemas genéricos (GSI) |
| `com.android.hotspot2` | Wi-Fi Passpoint |
| `com.android.companiondevicemanager` | pareamento de acessórios de celular |
| `com.android.bluetoothmidiservice` | MIDI por Bluetooth (a box não tem Bluetooth) |
| `com.android.wallpaper`, `wallpapercropper`, `wallpaperbackup` | papéis de parede (testar o FLauncher depois) |

### Opcionais (testar depois de remover)
| Pacote | O que é | Cuidado |
|---|---|---|
| `com.google.android.katniss` | Assistente Google / busca por voz | sem controle com microfone, não tem uso; pode afetar a busca global |
| `com.google.android.tvrecommendations` | recomendações na tela inicial | o FLauncher não usa |
| `com.google.android.feedback` | envio de relatórios ao Google | — |
| `com.google.android.apps.restore` | restauração de backup na configuração inicial | — |
| `com.android.providers.calendar` | calendário | o GMS pode reclamar |
| `com.rk_itvui.allapp` | lista de apps do fabricante | atalho do controle aponta para ele |

### Manter
Netflix, YouTube, Play Store, GMS/GSF, Configurações (`tv.settings`), teclado (LatinIME), WebView, providers de mídia/downloads/settings/tv, `softwinner.settingsassist`, `softwinner.provision`, `allwinnertech.*`, telefonia (`phone`, `telecom`, `mms`, contatos), FLauncher.

---

## 6. Recomendações (por prioridade)

1. ~~Remover `com.softwinner.miracastReceiver`~~ **feito em 30/10.**
2. ~~Ligar a verificação de apps e desligar fontes desconhecidas~~ **feito em 30/10** (`package_verifier_enable=1`, `verifier_verify_adb_installs=1`, `install_non_market_apps=0`).
3. ~~Revogar CAMERA e RECORD_AUDIO da Netflix e REQUEST_INSTALL_PACKAGES de Netflix e FLauncher~~ **feito em 30/10** (câmera/microfone via `appops ignore`, porque `pm revoke` não funciona nesta firmware).
4. **Desligar a depuração por rede** quando o trabalho terminar (o `adb root` continua possível enquanto ela estiver ligada).
5. ~~Remover os apps inúteis da seção 5~~ **feito em 30/10**: todos os recomendados + `katniss` + `tvrecommendations` (ver `02`, seção 24). Restam só os opcionais `feedback`, `apps.restore`, `providers.calendar`, `rk_itvui.allapp`.
6. Manter a box em **rede de convidados** se o roteador permitir.
7. Pendente físico: **abrir a box e inspecionar o receptor IR**.
8. Opcional, mais arriscado: SELinux enforcing (editar o `boot.img`); interface em 1080p.

---

## 7. Arquivos do projeto

| Caminho | Conteúdo |
|---|---|
| `docs/01-vulnerabilidades-e-riscos.md` | vulnerabilidades iniciais (24–25/10) |
| `docs/02-historico-completo.md` | registro técnico detalhado, seções 1–22 |
| `docs/03-forense-infraestrutura.md` | OSINT dos servidores dos operadores |
| `docs/04-relatorio-geral.md` | este relatório |
| `iocs/iocs.txt` | indicadores de comprometimento consolidados |
| `scripts/` | firewall da estação, backup do eMMC, limpeza |

> Os backups das partições do eMMC (`backup/20261029/`, ~868 MB) e as cópias dos arquivos removidos na fase 2 (`backup/fase2_removidos/`, com APKs/binários maliciosos) **não fazem parte deste repositório público**: contêm chaves/identificadores únicos do aparelho e amostras de malware. Ficam apenas no armazenamento local do autor.
