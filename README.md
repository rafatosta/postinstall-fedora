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
| `remove` | Remove aplicativos/pacotes indesejados |
| `flatpaks` | Instala os aplicativos Flatpak definidos nos manifests |
| `theme` | Configura o tema GTK para aplicações legadas |
| `all` | Executa todas as ações na sequência padrão |
| `help` | Exibe a ajuda do script |

## Exemplos

Executar apenas uma ação:

```bash
./install.sh remove
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

## Sequência executada por `all`

```text
repos
flatpak
system
extensions
dev
apps
remove
flatpaks
theme
```
