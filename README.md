# postinstall-fedora

Script pessoal de pós-instalação do Fedora, organizado em ações independentes para permitir executar somente o que for necessário.

## Uso

```bash
./install.sh <ação> [ação...]
```

### Ações disponíveis

| Ação | Descrição |
| --- | --- |
| `cleanup` | Limpa a instalação padrão do Fedora antes da configuração |
| `repos` | Configura repositórios de terceiros |
| `flatpak` | Configura Flatpak e Flathub |
| `system` | Instala pacotes básicos do sistema |
| `extensions` | Instala pacotes relacionados a extensões |
| `dev` | Instala ferramentas de desenvolvimento |
| `apps` | Instala aplicativos do usuário |
| `nvidia` | Força a reconstrução dos módulos NVIDIA com `akmods` |
| `flatpaks` | Instala os aplicativos Flatpak definidos nos manifests |
| `theme` | Configura o tema GTK para aplicações legadas |
| `icons` | Instala e ativa o tema de ícones LinuxMidnight no GNOME |
| `settings` | Aplica preferências pessoais do GNOME |
| `all` | Executa todas as ações na sequência padrão |
| `help` | Exibe a ajuda do script |

## Exemplos

Executar apenas a limpeza do sistema:

```bash
./install.sh cleanup
```

Reconstruir os módulos NVIDIA após instalar ou atualizar o driver:

```bash
./install.sh nvidia
```

Instalar e ativar o tema de ícones LinuxMidnight:

```bash
./install.sh icons
```

Aplicar as preferências pessoais do GNOME:

```bash
./install.sh settings
```

Executar várias ações em sequência:

```bash
./install.sh system dev apps
```

Executar toda a pós-instalação:

```bash
./install.sh all
```

Exibir a ajuda:

```bash
./install.sh help
```

Quando executado sem parâmetros, o script apenas exibe a ajuda e não realiza alterações no sistema.

## Cleanup

A ação `cleanup` prepara a instalação padrão do Fedora antes da instalação dos aplicativos e configurações desejados.

Ela executa as seguintes etapas:

1. Remove os pacotes definidos explicitamente em `packages/rpm/remove.txt`. O DNF também pode remover dependências que deixarem de ser necessárias.
2. Remove dados residuais do usuário definidos explicitamente em `packages/cleanup/home.txt`.
3. Desabilita o repositório COPR do PyCharm, quando presente.
4. Desabilita o repositório `rpmfusion-nonfree-steam`, quando presente.
5. Desabilita o remoto Flatpak `fedora`, sem removê-lo do sistema.
6. Executa `sudo dnf autoremove -y` para uma limpeza final das dependências órfãs.

### Limpeza da Home

O arquivo `packages/cleanup/home.txt` contém somente caminhos conhecidos de aplicativos removidos. A lista inicial inclui resíduos do Firefox/Mozilla e do ABRT.

O script possui proteções para essa etapa:

- aceita apenas caminhos dentro da Home do usuário atual;
- rejeita caminhos com `..`;
- nunca permite remover diretamente `$HOME`, `~/.config`, `~/.cache`, `~/.local`, `~/.local/share` ou `~/.local/state`;
- remove somente os caminhos exatos definidos no manifesto;
- registra cada caminho efetivamente removido.

Isso evita varreduras genéricas ou remoções indiscriminadas dentro da Home. Para adicionar outro aplicativo à limpeza, deve-se acrescentar somente os diretórios específicos e conhecidos desse aplicativo ao manifesto.

Os repositórios RPM são desabilitados com `dnf config-manager`, que cria uma configuração de override. Os arquivos `.repo` fornecidos pelos pacotes do Fedora não são apagados ou modificados diretamente.

O repositório `fedora-cisco-openh264` é mantido habilitado, pois não é exclusivo do Firefox e pode ser utilizado por outros componentes multimídia do sistema.

## NVIDIA

A ação `nvidia` força a reconstrução dos módulos de kernel do driver NVIDIA instalado via RPM Fusion:

```bash
sudo akmods --rebuild --force
```

Antes de executar, o script verifica se `akmod-nvidia` está instalado. Se o driver não estiver presente, a ação é ignorada sem gerar erro. Isso permite manter `nvidia` na sequência `all` mesmo em uma instalação onde o driver ainda não tenha sido instalado.

Essa ação é útil após instalar o driver NVIDIA ou depois de uma atualização de kernel/driver em que o módulo ainda não tenha sido construído corretamente.

## Ícones

A ação `icons` clona temporariamente o repositório `rafatosta/LinuxMidnight-icon-theme`, executa o instalador do próprio tema e remove o clone temporário ao terminar.

O tema é instalado em:

```text
~/.local/share/icons/LinuxMidnight
```

Depois da instalação, quando o schema do GNOME está disponível, o script ativa automaticamente o tema com:

```bash
gsettings set org.gnome.desktop.interface icon-theme 'LinuxMidnight'
```

O repositório do LinuxMidnight também possui um instalador enxuto: ele copia apenas `index.theme` e os diretórios de ícones utilizados pelo tema (`scalable` e `symbolic`), evitando levar arquivos de desenvolvimento, documentação, screenshots ou metadados do Git para `~/.local/share/icons`.

## Settings

A ação `settings` aplica preferências pessoais do usuário no GNOME usando `gsettings`.

Atualmente ela configura:

- colagem da seleção primária com o botão do meio do mouse;
- suspensão automática desativada quando o computador está ligado à tomada;
- suspensão automática após 30 minutos quando estiver usando a bateria.

As configurações aplicadas são equivalentes a:

```bash
gsettings set org.gnome.desktop.interface gtk-enable-primary-paste true

gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout 0

gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type 'suspend'
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-timeout 1800
```

Essas preferências são gravadas para o usuário atual e não modificam arquivos globais do sistema.

## Flatpak

A ação `flatpak` mantém o remoto Fedora desabilitado e configura o Flathub oficial como fonte dos aplicativos Flatpak. Caso o Flathub já exista com um filtro aplicado pela configuração do Fedora, o filtro é removido.

## Sequência executada por `all`

O `cleanup` é executado primeiro. Depois disso, o script configura e instala o ambiente desejado:

```text
cleanup
repos
flatpak
system
extensions
dev
apps
nvidia
flatpaks
theme
icons
settings
```

## Backup e restauração do Codex

O Codex armazena dados locais na pasta oculta `~/.codex`, incluindo sessões, índices, bancos SQLite, configurações e possíveis anexos. Esse backup **não sincroniza conversas com a nuvem** e a restauração não garante que todas as sessões apareçam na interface de versões futuras.

### Fazer backup antes de reinstalar o Fedora

1. Feche completamente o aplicativo Codex, para evitar copiar bancos SQLite durante operações de escrita (inclusive arquivos `-wal` e `-shm`).
2. Salve uma cópia compactada fora da instalação que será formatada, por exemplo em uma unidade externa. Para criar primeiro o arquivo em `Documents`:

```bash
tar -czf "$HOME/Documents/codex-backup-$(date +%Y-%m-%d).tar.gz" -C "$HOME" .codex
```

3. Verifique o conteúdo e a integridade do arquivo, antes de apagar a instalação original:

```bash
tar -tzf "$HOME/Documents/codex-backup-$(date +%Y-%m-%d).tar.gz" | head
gzip -t "$HOME/Documents/codex-backup-$(date +%Y-%m-%d).tar.gz"
```

**Importante:** um arquivo salvo em `~/Documents` será perdido se esse diretório for formatado. Copie o backup para um dispositivo externo ou armazenamento seguro antes da reinstalação.

### Restaurar o backup

Com o Codex fechado, em uma instalação nova (ou depois de preservar/renomear uma pasta `~/.codex` já existente), execute:

```bash
tar -xzf "/caminho/para/codex-backup-AAAA-MM-DD.tar.gz" -C "$HOME"
chmod 700 "$HOME/.codex"
```

Substitua o caminho e a data pelo nome real do arquivo. Abra o aplicativo e confira as sessões. A compatibilidade da restauração depende da versão do Codex e do estado dos dados locais; pode ser necessário autenticar novamente.

### Segurança e diretórios diferentes

- O arquivo `~/.codex/auth.json` pode conter credenciais e tokens. Trate o backup como **informação sensível**; não o publique no GitHub e criptografe-o antes de enviá-lo a um serviço de nuvem.
- Pastas de projetos, como `~/Documents/Codex`, são independentes de `~/.codex` e **não entram** nesse backup. Se contiverem arquivos importantes, copie-as separadamente.
- Para conferir onde estão os dados locais: `ls -lah ~/.codex`.
