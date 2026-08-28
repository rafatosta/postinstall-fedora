# postinstall-fedora

Script pessoal de pós-instalação do Fedora, organizado em ações independentes para permitir executar somente o que for necessário.

## Uso

```bash
./install.sh <ação> [ação...]
```

### Ações disponíveis

| Ação | Descrição |
| --- | --- |
| `repos` | Configura repositórios de terceiros |
| `flatpak` | Configura Flatpak e Flathub |
| `system` | Instala pacotes básicos do sistema |
| `extensions` | Instala pacotes relacionados a extensões |
| `dev` | Instala ferramentas de desenvolvimento |
| `apps` | Instala aplicativos do usuário |
| `cleanup` | Remove aplicativos/pacotes não desejados e executa `dnf autoremove` |
| `flatpaks` | Instala os aplicativos Flatpak definidos nos manifests |
| `theme` | Configura o tema GTK para aplicações legadas |
| `all` | Executa todas as ações na sequência padrão |
| `help` | Exibe a ajuda do script |

## Exemplos

Executar apenas a limpeza do sistema:

```bash
./install.sh cleanup
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

A ação `cleanup` executa duas etapas:

1. Remove os pacotes definidos explicitamente em `packages/rpm/remove.txt`.
2. Executa `sudo dnf autoremove -y` para remover dependências órfãs que não são mais necessárias.

A remoção explícita usa `--no-autoremove`, deixando a limpeza de dependências para a etapa final do `cleanup`.

## Sequência executada por `all`

```text
repos
flatpak
system
extensions
dev
apps
cleanup
flatpaks
theme
```
