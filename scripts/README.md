# Scripts

Utilitários usados na análise e na desinfecção. Ajuste as variáveis no topo de cada script
(IP da box, interface Wi-Fi) ao seu ambiente antes de rodar.

| Script | O que faz |
|---|---|
| `apkcert.py` | Mostra o SHA-256 do certificado de assinatura (esquema v2/v3) de um APK. Uso: `python3 -I apkcert.py arquivo.apk [...]` |
| `lpunpack.py` | Extrai as partições lógicas (`system`, `vendor`, `product`…) de uma imagem `super` do Android. Uso: `python3 -I lpunpack.py super.img saida/` |
| `backup_emmc.sh` | Backup só-leitura das partições de sistema do eMMC via ADB, com verificação de SHA-256 na box e na estação. Requer `adb root` (firmware userdebug). Defina `DEV=IP:porta`. |
| `limpeza.sh` | Remove malware, apps de terceiros e lixo de sistema (`pm uninstall --user 0`). **Simula por padrão**; `--aplicar` executa. Reversível com `cmd package install-existing`. Defina `DEV=IP:porta`. |
| `fix_firewall.sh` | Blindagem inicial da estação: Docker em `127.0.0.1` e a box na zona `drop` do firewalld. Defina `BOX_IP`. |
| `fix_firewall3.sh` | Zona `drop` para a box + policy firewalld (public→docker REJECT). Defina `BOX_IP`. |
| `fix_firewall4.sh` | Conserta o `firewalld` em estado FAILED e reaplica a policy. Defina `IFACE`. |
| `fix_firewall5.sh` | Drop-in do systemd que bloqueia, a cada start do Docker, conexões novas vindas do Wi-Fi para os containers (regra `DOCKER-USER`). Defina `IFACE`. |

> **Variáveis de ambiente**
> - `DEV` — endereço ADB da box, ex.: `export DEV=192.168.1.100:5555`
> - `BOX_IP` — IP da box na sua rede, ex.: `export BOX_IP=192.168.1.100`
> - `IFACE` — interface Wi-Fi da estação, ex.: `export IFACE=wlan0`

> **Nota histórica.** Houve um `fix_firewall2.sh` (regras `--direct`) que **quebrava o
> firewalld** e foi revertido; ele não está incluído de propósito. Os relatórios mencionam
> esse passo apenas para registrar a cronologia. Os scripts `fix_firewall.sh` → `3` → `4` →
> `5` são a sequência que de fato funcionou.

Scripts que agem sobre a box (`backup_emmc.sh`, `limpeza.sh`) pressupõem autorização sobre o
aparelho. `limpeza.sh` roda em modo simulação até receber `--aplicar`.
