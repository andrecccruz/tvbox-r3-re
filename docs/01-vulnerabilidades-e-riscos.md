# TV Box "R3" — Vulnerabilidades, exposição e riscos

> Alvo: TV Box genérica Allwinner H313, IP `<box>`
> Análise: 2026-10-24/25, somente leitura via ADB (nada foi alterado no aparelho)
> Veredito: **comprometida de fábrica** — rootada, firmware de desenvolvimento e malware de proxy residencial ativo

---

## 1. Resumo executivo

| # | Achado | Severidade |
|---|--------|-----------|
| V1 | Malware de proxy residencial ativo (Honeygain SDK e CastarSDK) | **Crítica** |
| V2 | Instaladores silenciosos com UID de sistema (dropper) | **Crítica** |
| V3 | Root de fábrica: `su` setuid + daemon `qw` rodando como root no boot | **Crítica** |
| V4 | SELinux em modo *Permissive* | Alta |
| V5 | Build `userdebug` (`ro.debuggable=1`) | Alta |
| V6 | Patch de segurança de 2019-12-05 (cerca de 7 anos sem correções) | Alta |
| V7 | ADB exposto na rede (TCP 5555) | Alta |
| V8 | Porta TCP 14035 escutando em 0.0.0.0 (UID 1041) | Média (a investigar) |
| V9 | Especificações falsificadas (Android, RAM) | Baixa (fraude, não vulnerabilidade) |
| V10 | Binário `dom2reg` como root com `NET_ADMIN`, ofuscado | Média (a investigar) |

---

## 2. Vulnerabilidades detalhadas

### V1 — Proxyware (revenda da sua conexão de internet)
- `com.systemguard.android`: embute o **Honeygain SDK** (445 referências a `com.honeygain.*`) e carrega código em tempo de execução (`DexClassLoader`). Domínios de comando de aparência aleatória: `xepith.com`, `upiral.com`, `thewsoral.com`, `nagopore.com`, `fepoth.com`, `crowsember.com`, `optimizerapi.long.tv`.
- `com.core.rss`: SDK nativo `libszbx_sdk.so` com o caminho de build `castar_sdk` (**CastarSDK**). Tem túnel TCP (`TcpTunnelPipeline`, `TunnelTcpLinkGuard`) e "route server". Mantém conexões em portas não padrão (116, 143, 159, 175, 190, 197, 276) com `43.102.x` (Alibaba Cloud), `43.130.x` e `101.32.x` (Tencent Cloud) e `207.166.164.30` (BytePlus/ByteDance).
- **Impacto:** terceiros navegam e acessam serviços **usando o seu IP**. Se houver abuso (fraude, scraping, ataques), ele aparece como vindo da sua casa.

### V2 — Dropper / instalação silenciosa
- `com.android.netservice`: UID de sistema (1000), 342 permissões, funções `silentInstall` e `installApp [downloadFinishHandler_thirdParty]`, referência a `Nebula-app.apk`. Comando e controle em `heartbeat.dnsyc.top` e `business.dnsyc.top`. Atualizado sozinho em 2026-09-07.
- `com.android.domain`: UID de sistema, C2 em `v105.imptor.top`.
- `com.lssa.service`: `silentInstall`, telemetria em `*.tentvs.com`, localização precisa concedida.
- `com.android.assistant.setting.iknew`: UID de sistema, atualizador em `upgrade.boxstv.com` e `upgrade.tvsetting.com`.
- `com.android.netservice` e `com.android.domain` usam **DNS sobre HTTPS** (`doh.pub`, `dns.alidns.com`, `cloudflare-dns.com`), o que **contorna bloqueio por DNS** no roteador.
- **Impacto:** os operadores podem instalar **qualquer** app ou módulo a qualquer hora, inclusive de DDoS, roubo de dados ou varredura da rede local.

### V3 — Root de fábrica
- `/system/xbin/su`: `-rwsr-sr-x root shell`.
- `/system/bin/qw --daemon`: iniciado como root, classe `core` (`/system/etc/init/qw.rc`). Pelas strings, é um daemon de Superuser (koush).
- Processos `daemonsu:master` e `daemonsu:mount:master` rodando.
- **Impacto:** qualquer app pode virar root. Remover apps não basta, porque o mecanismo de reinfecção está em `/system`.

### V4–V6 — Base de segurança desligada
- `getenforce` = Permissive.
- `ro.build.type=userdebug`, `ro.debuggable=1`.
- `ro.build.version.security_patch=2019-12-05`, kernel 4.9.170.

### V7 — ADB na rede
- `adbd` escuta em `:::5555`. Qualquer aparelho na rede pode pedir conexão (a tela pede autorização, mas o malware já tem root de qualquer forma).

### V8 — Porta 14035
- `0.0.0.0:14035 LISTEN`, dono UID 1041 (audioserver). Não é comportamento padrão do Android; pode ser um endpoint de proxy. **Investigar.**

### V10 — `dom2reg`
- `/vendor/bin/dom2reg`, root, grupo system, capabilities `BLOCK_SUSPEND NET_ADMIN`, oneshot. Sem strings legíveis (provavelmente compactado). **Investigar.**

---

## 3. O que está exposto

### Na TV Box
| Serviço | Porta | Exposto para |
|---|---|---|
| ADB | TCP 5555 | rede local |
| Desconhecido (UID 1041) | TCP 14035 | rede local |
| mDNS | UDP 5353 | rede local |

### Dados que os apps coletam ou enviam
- IP público e geolocalização (`ipapi.co`, `freeipapi.com`, `ip-api.io`, `freegeoip.app`)
- Lista de apps instalados e desinstalados (`upload-uninstall.tentvs.com`)
- Localização precisa (`com.lssa.service`)
- Estado do "telefone" e ID do dispositivo
- Contas logadas na box (Google, Netflix) estão ao alcance de qualquer app com root

### Na estação de análise, visto a partir da TV Box
A partir da box dava para alcançar **vários serviços que escutavam na estação de análise**
(administração remota e serviços de desenvolvimento, parte deles em containers). O ponto
importante para este relatório é o risco — um aparelho comprometido na mesma rede podia
tocar nesses serviços —, não a lista em si. A blindagem está na seção 5: parte fechou com o
`fix_firewall.sh`; os serviços em containers exigiram as regras de `DOCKER-USER`
(`fix_firewall4.sh`/`fix_firewall5.sh`).

---

## 4. Riscos

| Risco | Probabilidade | Impacto |
|---|---|---|
| Seu IP usado por terceiros (proxy residencial) | **Já acontecendo** | Alto: responsabilização, bloqueios, CAPTCHAs |
| Box recrutada para DDoS | Possível (infraestrutura pronta) | Alto |
| Ataque lateral a outros dispositivos da rede | Possível | Alto |
| Roubo de contas logadas na box | Possível | Alto |
| Coleta de dados (geo, apps, IDs) | **Já acontecendo** | Médio |
| Consumo de banda e lentidão | **Já acontecendo** | Baixo/Médio |

### DDoS
- Medição em 2026-10-25, por 15 s: cerca de 2,3 KB/s de download e 2,7 KB/s de upload. Isso é **tráfego de controle, não ataque**.
- A capacidade existe: root, instalação silenciosa e código dinâmico permitem empurrar um módulo de DDoS a qualquer momento.

### Celular
- Risco baixo se estiver atualizado, sem ADB por Wi-Fi e sem apps de servidor. Recuse pareamentos de dispositivos desconhecidos.

---

## 5. Mitigações

### Já aplicadas
- [x] Docker: `"ip": "127.0.0.1"` em `/etc/docker/daemon.json` (backup salvo como `daemon.json.bak-*`)
- [x] firewalld: `<box>` na zona `drop`
- [ ] firewalld direct: `DOCKER-USER -i <iface-wifi> --ctstate NEW -j DROP` (script `fix_firewall2.sh`, **confirmar**)

### Recomendadas (sem mexer na box)
- [ ] Colocar a box na **rede de convidados** do roteador, isolada dos outros aparelhos
- [ ] Bloquear no roteador: `dnsyc.top`, `imptor.top`, `tentvs.com`, `boxstv.com`, `tvsetting.com`, `mytvos.com`, `long.tv` e os domínios aleatórios do item V1
- [ ] Trocar as senhas de contas usadas na box
- [ ] Serviços em containers: publicar as portas só em `127.0.0.1` no compose (ex.: `127.0.0.1:porta:porta`)
- [ ] SSH da estação: só chave, `PasswordAuthentication no`

### Na box (precisa de autorização)
- [ ] Desativar ou desinstalar os apps maliciosos (`pm disable-user` / `pm uninstall --user 0`). Alívio temporário: pode haver reinfecção
- [ ] Regravar uma firmware limpa (Armbian, LibreELEC/CoreELEC ou ROM de comunidade para H313/H616). **Solução definitiva**
- [ ] Ou descartar a box e trocar por um aparelho certificado
