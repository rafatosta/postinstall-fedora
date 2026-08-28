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
2. Desabilita o repositório COPR do PyCharm, quando presente.
3. Desabilita o repositório `rpmfusion-nonfree-steam`, quando presente.
4. Desabilita o remoto Flatpak `fedora`, sem removê-lo do sistema.
5. Executa `sudo dnf autoremove -y` para uma limpeza final das dependências órfãs.

Os repositórios RPM são desabilitados com `dnf config-manager`, que cria uma configuração de override. Os arquivos `.repo` fornecidos pelos pacotes do Fedora não são apagados ou modificados diretamente.

O repositório `fedora-cisco-openh264` é mantido habilitado, pois não é exclusivo do Firefox e pode ser utilizado por outros componentes multimídia do sistema.

## NVIDIA

A ação `nvidia` força a reconstrução dos módulos de kernel do driver NVIDIA instalado via RPM Fusion:

```bash
sudo akmods --rebuild --force
```

Antes de executar, o script verifica se `akmod-nvidia` está instalado. Se o driver não estiver presente, a ação é ignorada sem gerar erro. Isso permite manter `nvidia` na sequência `all` mesmo em uma instalação onde o driver ainda não tenha sido instalado.

Essa ação é útil após instalar o driver NVIDIA ou depois de uma atualização de kernel/driver em que o módulo ainda não tenha sido construído corretamente.

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
```
