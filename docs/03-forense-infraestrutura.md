# TV Box "R3" — Forense da infraestrutura dos operadores

> Coleta: 2026-10-25, **somente fontes passivas e públicas**: RDAP/WHOIS, DNS (DoH Cloudflare), ipinfo.io, Shodan InternetDB e Certificate Transparency (crt.sh).
> Nenhum servidor de terceiros foi escaneado ou acessado diretamente.
> Fonte dos indicadores: strings dos APKs e conexões observadas na box (veja `02-historico-completo.md`).

---

## 1. Resumo

| Cluster | Função na box | Domínios | Hospedagem | Localização |
|---|---|---|---|---|
| **A — "akrdinfo"** | Comando do dropper (netservice/domain) | `dnsyc.top`, `imptor.top` | Alibaba Cloud (AS45102) | Los Angeles, EUA |
| **B — "tentvs"** | Telemetria, atualização, instalação silenciosa | `tentvs.com`, `mytvos.com`, `shortv.net`, `boxstv.com`, `tvsetting.com`, `longott.com`, `long.tv`, `adtvbox.com` | FDCservers (AS30058) + Cloudflare | Chicago, Los Angeles (EUA) e Viena (Áustria) |
| **C — Proxy (CastarSDK)** | Túnel de proxy residencial (`com.core.rss`) | — (IP direto) | BytePlus/ByteDance, Tencent Cloud, Alibaba Cloud | Singapura, Santa Clara (EUA), Frankfurt (Alemanha) |
| **D — Proxy (Honeygain SDK)** | Proxy residencial (`com.systemguard.android`) | `xepith.com`, `upiral.com`, `nagopore.com`, `fepoth.com`, `thewsoral.com`, `crowsember.com` | DataPacket/Datacamp (AS212238) + Cloudflare | **São Paulo, Brasil** |
| E — Utilitário | API pública chinesa | `apiopen.top` | Alibaba CN / Fuzhou | Shenzhen e Fuzhou (China) |

---

## 2. Cluster A — "akrdinfo" (comando e controle do dropper)

### Domínios
| Domínio | Criado | Expira | Registrador | Região do registrante | NS |
|---|---|---|---|---|---|
| `dnsyc.top` | 2025-09-12 | 2028-09-12 | Alibaba Cloud (阿里云) | Jiangxi, China | `vip3/vip4.alidns.com` |
| `imptor.top` | 2025-07-22 | 2027-07-22 | Dynadot | "California" (privacidade) | `vip3/vip4.alidns.com` |

`dnsyc.top` foi criado **5 dias antes** da compilação da firmware (2025-09-17).

### Hosts
| Host | IP | Hostname reverso (Shodan) | Portas abertas |
|---|---|---|---|
| `heartbeat.dnsyc.top`, `sub.dnsyc.top` | 47.251.5.25 | `filebt.akrdinfo.cn` | 22, 80, 443, 9091 |
| `business.dnsyc.top` | 47.251.105.207 | `banyandb.akrdinfo.cn` | 22, 80, 443, 7777, 8743, 9999 |
| `dns.dnsyc.top`, `dnsyc.top` | 47.251.69.129 | `git.akrdinfo.cn` | 22, 80, 443 |
| `v105.imptor.top`, `imptor.top` | 47.251.54.180 | `banyandb.akrdinfo.cn` | 22, 80, 443, 7777, 8743, 8745, 9901, 9999 |

Todos ficam em **Alibaba (US), Los Angeles**, AS45102, com Debian, nginx/OpenResty e OpenSSH 7.9–9.2.

Certificate Transparency mostra ainda `0czd47.imptor.top`, `4irosp.imptor.top` (rotativos, hoje sem DNS) e `*.dnsyc.top`.

### `akrdinfo.cn` — a infraestrutura por trás
WHOIS público (CNNIC):

| Campo | Valor |
|---|---|
| Registrado em | 2024-06-27 |
| Registrador | Alibaba Cloud (万网) |
| Registrante | *(pessoa física — redigido)* |
| E-mail | *(e-mail/celular de China Mobile — redigido)* |

> Os dados pessoais do registrante (nome, e-mail e telefone) foram **omitidos nesta versão pública**: são dados de WHOIS que podem pertencer a um laranja ou revendedor e não provam autoria. Quem precisar dessas informações para uma denúncia formal deve consultar o WHOIS/RDAP diretamente.

Subdomínios em CT, que mostram uma **empresa de tecnologia com operação completa**: `admin`, `ai`, `arthas`, `banyandb`, `claw`, `druid`, `filebt`, `git`, `grafana`, `jenkins`, `kafdrop`, `kibana`, `mcp`, `minio`, `nacos`, `network`, `portainer`, `prometheus`, `rocketmq`, `skywalking`, `tdengine`, `v2`, `v2doc`, `vn`, `net.test`.

### Ligação com a firmware
- A fingerprint da firmware é `eng.**akrc8**.20250917`: o build foi feito pelo usuário `akrc8`.
- Os servidores de comando respondem como `*.**akr**dinfo.cn`.
- **Hipótese (não provada):** o mesmo grupo ("akr…") compilou a firmware e opera o comando. Isso indicaria **infecção na cadeia de fornecimento**, não infecção posterior.

> Atribuição: os dados de registrante vêm de WHOIS público e podem ser de um laranja ou de um revendedor. **Não são prova de autoria.** Qualquer indicador aqui serve só para denúncia às autoridades e aos provedores de abuso; não tente contato.

---

## 3. Cluster B — "tentvs" (telemetria e atualização OTA)

### Domínios
| Domínio | Criado | Registrador | NS | Observação |
|---|---|---|---|---|
| `tentvs.com` | 2024-07-29 06:42:14 | GoDaddy | Cloudflare (alexis/alice) | **mesmo segundo** que `mytvos.com` |
| `mytvos.com` | 2024-07-29 06:42:13 | GoDaddy | Cloudflare (alexis/alice) | |
| `boxstv.com` | 2022-01-11 | GoDaddy | Cloudflare (alexis/alice) | |
| `tvsetting.com` | 2021-12-08 | GoDaddy | Cloudflare (alexis/alice) | |
| `longott.com` | 2017-11-05 | Name.com | Cloudflare (alexis/alice) | `ott.longott.com` aponta para 8.8.8.8 (desativado) |
| `shortv.net` | 2018-04-15 | Name.com | Cloudflare (fiona/stan) | |
| `long.tv` | 2014-06-16 | Registrar of Last Resort | `vip3/vip4.alidns.com` | `optimizerapi.long.tv` aponta para 8.8.8.9 (desativado) |
| `adtvbox.com` | 2024-01-28 | Name.com | — | hostname do servidor de Viena |

Todos usam o **mesmo par de NS da Cloudflare** (alexis/alice), ou seja, a mesma conta Cloudflare e o mesmo operador. `long.tv` usa os mesmos NS Alibaba (`vip3/vip4`) do Cluster A, o que é um **possível elo entre A e B**.

### Servidores de origem (fora da Cloudflare)
| Host | IP | ASN / Provedor | Local | Portas (Shodan) | Problemas |
|---|---|---|---|---|---|
| `upload-uninstall`, `upload-sdkuninstall.tentvs.com`, `long.tv` | 216.227.189.9 | AS30058 FDCservers | Chicago, EUA | 22, 80, 443, **3306 (MySQL)**, 8002, 9090, 10000 | MySQL 8.0.36 exposto, produto EOL, **95 CVEs** |
| `top-channel`, `timestamp-sdk.tentvs.com`, `timestamp.shortv.net` | 216.227.189.175 | AS30058 FDCservers | Chicago, EUA | 22, 80, 443, **3306**, 9090 | MySQL exposto, **109 CVEs** |
| `boxstv.com` | 23.237.233.166 | AS30058 FDCservers | Los Angeles, EUA | — | |
| `long.tv` (A), `adtvbox.com` | 67.159.17.132 | AS30058 FDCservers | Viena, Áustria | 22, 80, 443, 2222, 9090, 40005 | 37 CVEs |
| `upload-sa`, `upload-sdk.tentvs.com`, `upload.mytvos.com`, `upgrade.tvsetting.com`, `upgrade.boxstv.com` | Cloudflare (104.21.x / 172.67.x) | AS13335 | anycast | — | origem escondida |

---

## 4. Cluster C — nós do proxy CastarSDK (`com.core.rss`)

Conexões **observadas na box** em 2026-10-24:

| IP | Porta usada pela box | Provedor | Local | Abuse | Portas abertas (Shodan) | Tags |
|---|---|---|---|---|---|---|
| 207.166.164.30 | 197, 276 | BytePlus Pte. Ltd. (ByteDance), AS150436 | Singapura | `bd_abuse@bytedance.com` | 22, 101–264 (cerca de 18 portas), 9100 | Ubuntu, OpenSSH 9.6p1 |
| 43.130.3.96 | 175 | Aceville Pte. Ltd. (**Tencent Cloud**), AS132203 | Santa Clara, EUA | `abuse@tencent.com` | 100–264 (cerca de 20 portas) | |
| 101.32.166.132 | 190 | Aceville (**Tencent Cloud**), AS132203 | Singapura | `abuse@tencent.com` | 100–199, 8101 | **proxy** |
| 43.102.213.193 | 116 | **Alibaba Cloud** Singapore, AS45102 | Singapura | `abuse@alibaba-inc.com` | 22, 100–264, 887, 9100 | cloud |
| 43.102.65.55 | 159 | **Alibaba Cloud** Singapore, AS45102 | Frankfurt, Alemanha | `abuse@alibaba-inc.com` | 22, 100–264, 2345, 6666, 8102, 8888, 9100 | cloud, **proxy** |

**Padrão:** todos abrem a mesma faixa de **portas baixas incomuns (100–264)**, uma por "linha" de túnel. A box se conecta a uma porta diferente em cada nó, o que bate com o código do SDK ("server lines", "route node", "Dispatch server"). O Shodan já marca dois deles como **proxy**.

---

## 5. Cluster D — Honeygain SDK (`com.systemguard.android`)

| Domínio | Criado | NS Cloudflare | Resolve para |
|---|---|---|---|
| `xepith.com` | 2025-07-09 14:10:53 | diva/leif | cerca de 20 IPs DataPacket, São Paulo |
| `upiral.com` | 2025-07-09 14:10:51 | diva/leif | cerca de 20 IPs DataPacket, São Paulo |
| `nagopore.com` | 2025-07-09 14:15:47 | coen/pam | cerca de 20 IPs DataPacket, São Paulo |
| `fepoth.com` | 2025-07-09 14:15:47 | coen/pam | cerca de 20 IPs DataPacket, São Paulo |
| `thewsoral.com` | 2025-07-09 13:40:54 | clark/diana | Cloudflare |
| `crowsember.com` | 2025-07-09 13:40:55 | clark/diana | Cloudflare |

- Os 6 domínios foram registrados na GoDaddy **em 35 minutos**, em pares. São nomes aleatórios típicos de rotação para fugir de bloqueio.
- Os IPs ficam em `152.233.84.0/24` e `95.177.96.0/24` (AS212238 Datacamp/DataPacket, **São Paulo**), só com SSH (22) visível. O DNS é **geodirecionado**: devolve nós no Brasil para uma vítima no Brasil.
- Não está claro se esses domínios são da própria Honeygain ou de um revendedor que embutiu o SDK.

---

## 6. Cluster E — utilitários

| Host | IP | Local | Observação |
|---|---|---|---|
| `apiopen.top` | 150.242.98.76 | Fuzhou, China (AS133774) | API pública gratuita chinesa; 44 CVEs. Registrante em Sichuan, criado em 2017 |
| `api.apiopen.top` (CNAME) | 112.74.1.232, via `peakchao.oss-cn-shenzhen.aliyuncs.com` | Shenzhen, China | bucket OSS Alibaba |

Serviços de geolocalização de IP usados pelos apps (legítimos, mas usados para saber onde a vítima está): `ipapi.co`, `freeipapi.com`, `ip-api.io`, `freegeoip.app`. Resolvedores DoH embutidos: `doh.pub` (Tencent), `dns.alidns.com` (Alibaba), `cloudflare-dns.com`.

---

## 7. Mapa de localização

| País | Cidade | O que fica lá |
|---|---|---|
| EUA | Los Angeles | Comando do dropper (Cluster A, 4 servidores) e `boxstv.com` |
| EUA | Chicago | Telemetria e OTA "tentvs" (2 servidores, MySQL exposto) |
| EUA | Santa Clara | Nó de proxy Tencent |
| Singapura | — | 3 nós de proxy (ByteDance, Tencent, Alibaba) |
| Alemanha | Frankfurt | Nó de proxy Alibaba |
| Áustria | Viena | `long.tv` / `adtvbox.com` |
| **Brasil** | **São Paulo** | Cerca de 40 nós do proxy Honeygain |
| China | Jiangxi (registrante), Shenzhen, Fuzhou | Registro do domínio, `akrdinfo.cn`, API auxiliar |

---

## 8. Contatos de abuso (para denúncia)

| Provedor | E-mail | Itens |
|---|---|---|
| Alibaba Cloud | `abuse@alibaba-inc.com` | 47.251.5.25, 47.251.105.207, 47.251.69.129, 47.251.54.180, 43.102.213.193, 43.102.65.55 |
| Tencent Cloud | `abuse@tencent.com` | 43.130.3.96, 101.32.166.132 |
| BytePlus / ByteDance | `bd_abuse@bytedance.com` | 207.166.164.30 |
| FDCservers | abuse via fdcservers.net | 216.227.189.9, 216.227.189.175, 23.237.233.166, 67.159.17.132 |
| Cloudflare | abuse.cloudflare.com (formulário) | domínios dos clusters B e D |
| GoDaddy / Dynadot / Name.com | formulários de abuso dos registradores | domínios |
| **Brasil** | **CERT.br**: `cert@cert.br` | denúncia do incidente com todos os IoCs |

---

## 9. Limitações

- Dados de portas vêm do Shodan (varredura deles, com data variável), não de teste próprio.
- Geolocalização por IP é aproximada; IPs de nuvem podem ser realocados.
- DNS muda com frequência (rotação). Repetir a coleta para ver a evolução.
- Atribuição de pessoas e empresas é **indicativa**: nada aqui prova autoria.

---

## 10. IoCs consolidados

```
# Cluster A
dnsyc.top heartbeat.dnsyc.top business.dnsyc.top dns.dnsyc.top sub.dnsyc.top
imptor.top v105.imptor.top 0czd47.imptor.top 4irosp.imptor.top
akrdinfo.cn
47.251.5.25 47.251.105.207 47.251.69.129 47.251.54.180

# Cluster B
tentvs.com mytvos.com shortv.net boxstv.com tvsetting.com longott.com long.tv adtvbox.com
216.227.189.9 216.227.189.175 23.237.233.166 67.159.17.132

# Cluster C (proxy CastarSDK)
207.166.164.30 43.130.3.96 101.32.166.132 43.102.213.193 43.102.65.55

# Cluster D (proxy Honeygain)
xepith.com upiral.com nagopore.com fepoth.com thewsoral.com crowsember.com
152.233.84.0/24 95.177.96.0/24
```
