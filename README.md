# TV Box "R3" (Allwinner H313) — Engenharia reversa e desinfecção

Análise de segurança de uma TV Box genérica Android (SoC Allwinner H313/H616, vendida
como "R3") que veio **comprometida de fábrica**: rootada, com firmware de desenvolvimento
e malware de proxy residencial ativo. O repositório documenta a investigação (somente
leitura via ADB), a forense passiva da infraestrutura dos operadores e a desinfecção
completa do aparelho.

> ⚠️ **Aviso.** Trabalho defensivo, feito sobre um aparelho do próprio autor. Os
> indicadores de comprometimento (domínios, IPs, hashes) existem para **defesa, bloqueio e
> denúncia a provedores de abuse** — não para contato com os operadores. Nenhum servidor de
> terceiros foi escaneado ou acessado: a forense usou apenas fontes públicas e passivas
> (RDAP/WHOIS, DNS, Certificate Transparency, Shodan InternetDB). Atribuição de pessoas ou
> empresas é **indicativa e não prova autoria**.

---

## Resumo dos achados

- **Proxyware (crítico):** dois SDKs de proxy residencial — Honeygain (`com.systemguard.android`)
  e CastarSDK (`com.core.rss`) — revendiam a conexão de internet do dono a terceiros.
- **Dropper / instalação silenciosa (crítico):** apps com UID de sistema e `silentInstall`,
  com C2 em `dnsyc.top` / `imptor.top`, usando DNS-over-HTTPS para contornar bloqueio no roteador.
- **Root de fábrica (crítico):** `su`/`daemonsu`/`qw` setuid, iniciados no boot; SELinux em
  *Permissive*; build `userdebug`; patch de segurança de 2019.
- **Fraude de especificação:** firmware mente sobre Android (14 vs. 10 real) e RAM (8 GB
  falsos) e **bloqueia apps de diagnóstico** (CPU-Z, AIDA64…) para esconder o hardware real.
- **Possível comprometimento de cadeia de fornecimento:** a fingerprint da firmware (`akrc8`)
  e os servidores de C2 (`akrdinfo.cn`) compartilham o mesmo prefixo — hipótese, não prova.

**Estado final:** todo o malware conhecido foi removido (inclusive de `/system`, não volta
com reset de fábrica), o root de fábrica foi apagado, o aparelho roda um launcher limpo e a
estação de análise foi blindada contra a box.

---

## Estrutura

| Caminho | Conteúdo |
|---|---|
| [`docs/01-vulnerabilidades-e-riscos.md`](docs/01-vulnerabilidades-e-riscos.md) | Vulnerabilidades, exposição, riscos e mitigações |
| [`docs/02-historico-completo.md`](docs/02-historico-completo.md) | Registro técnico detalhado, linha do tempo, análise estática |
| [`docs/03-forense-infraestrutura.md`](docs/03-forense-infraestrutura.md) | OSINT passivo da infraestrutura dos operadores |
| [`docs/04-relatorio-geral.md`](docs/04-relatorio-geral.md) | Relatório consolidado e estado final |
| [`iocs/iocs.txt`](iocs/iocs.txt) | Indicadores de comprometimento (domínios, IPs, hashes, pacotes) |
| [`scripts/`](scripts/) | Scripts auxiliares (veja o [README dos scripts](scripts/README.md)) |

**Sugestão de leitura:** comece pelo [relatório geral](docs/04-relatorio-geral.md), depois
o de [vulnerabilidades](docs/01-vulnerabilidades-e-riscos.md), e use o
[histórico](docs/02-historico-completo.md) e a [forense](docs/03-forense-infraestrutura.md)
como referência.

---

## O que **não** está neste repositório

Por privacidade e segurança, alguns artefatos da análise ficam apenas no armazenamento
local do autor e foram **deliberadamente deixados de fora**:

- **Imagens das partições do eMMC** (`backup`, ~868 MB): contêm chaves e identificadores
  únicos do aparelho (`frp`, `private`, `env`, bootloader).
- **Amostras de malware** (APKs e binários removidos na fase 2): não se publica malware vivo.
  Os hashes SHA-256 estão em [`iocs/iocs.txt`](iocs/iocs.txt) para quem quiser conferir.
- **Logs brutos** (`dmesg`/`logcat`): continham serial, MACs e outros identificadores do
  aparelho. Os achados relevantes já estão nos relatórios.

Identificadores únicos do aparelho (serial, chip ID, endereços MAC), IPs da rede local e
detalhes da estação de análise foram **removidos ou generalizados** em todo o material.

---

## Licença

[MIT](LICENSE). Os relatórios podem ser citados livremente; mantenha o aviso de que a
atribuição é indicativa e não prova autoria.
