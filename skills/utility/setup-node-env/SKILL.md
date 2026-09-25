---
name: setup-node-env
description: Configura ambiente Node.js do projeto — detecta versão (nvmrc/Dockerfile), executa nvm install/use, verifica NPM_TOKEN para pacotes privados e executa npm install. Use quando iniciar projeto Node, quando npm install falhar, ou quando versão do Node precisar ser ajustada.
user-invocable: true
metadata:
  obsidian_identifier: scrapup:setup-node-env
---

# Setup Node Environment

Configure o ambiente Node.js do projeto: ajuste a versão correta via nvm, garanta o token para pacotes privados e instale as dependências.

## Quando Usar

- Na **inicialização da demanda**, orquestrada pela skill /scrapup:baseline-assessment ao avaliar readiness do ambiente. A skill /scrapup:scrapup-forge **não** invoca esta skill diretamente — delega à baseline-assessment
- Primeiro setup de um projeto Node.js
- Quando `npm install` falhar por conflito de versão ou dependências
- Quando a versão do Node.js precisar ser alterada

## Quando NÃO Usar

- Ambiente já configurado e validado na sessão atual
- Projetos sem Node.js
- CI/CD onde o setup é gerido pelo pipeline

## Regras

- **NUNCA** usar `--legacy-peer-deps` — `npm install` deve funcionar puro
- **NUNCA** armazenar tokens em arquivos da skill ou do projeto (usar variável de ambiente)
- Conflitos de versão são resolvidos atualizando `.nvmrc` + Dockerfile, nunca forçando deps

## Scripts

Todos os scripts estão em `~/.claude/plugins/local/scrapup/skills/utilitarios/setup-node-env/`. Aceitam `[project-dir]` como primeiro argumento (padrão: `.`).

| Script | Função | Exit codes |
|--------|--------|------------|
| [`detect-node-version.sh`](detect-node-version.sh) | Detecta versão do `.nvmrc` ou Dockerfile | 0=encontrada, 1=sem arquivos, 2=Dockerfile sem versão |
| [`nvm-install-use.sh`](nvm-install-use.sh) | Carrega nvm + install + use | 0=ok, 1=nvm ausente, 2=sem .nvmrc, 3=install falhou |
| [`check-npm-token.sh`](check-npm-token.sh) | Verifica se `NPM_TOKEN` está no ambiente | 0=disponível, 1=ausente |
| [`npm-install.sh`](npm-install.sh) | Executa `npm install` e classifica falha | 0=ok, 1=conflito versão/deps, 2=outra falha |
| [`update-node-version.sh`](update-node-version.sh) `<v>` | Atualiza `.nvmrc` + Dockerfile + nvm | 0=ok, 1=versão não informada |
| [`docker-build.sh`](docker-build.sh) | Build do Dockerfile com `NPM_TOKEN` | 0=ok, 1=sem Dockerfile, 2=sem token, 3=build falhou |

## Fluxo do Agente

O diagrama completo está em [`setup-node-env-flow.puml`](setup-node-env-flow.puml) neste diretório.

### 1. Detectar versão

```bash
~/.claude/plugins/local/scrapup/skills/utilitarios/setup-node-env/detect-node-version.sh <project-dir>
```

A decisão é ancorada **no exit code** do script. `NODE_VERSION` no stdout só está presente em **exit 0** — nunca em exit 1 ou 2.

| Exit | Stdout | Ação do agente |
|------|--------|----------------|
| 0 | `NODE_VERSION=<v>` + `SOURCE=nvmrc` | `.nvmrc` existe — prosseguir para o passo 2 (nvm) |
| 0 | `NODE_VERSION=<v>` + `SOURCE=dockerfile` | Ler `NODE_VERSION` do stdout e criar `.nvmrc` com essa versão; prosseguir para o passo 2 |
| 1 | `SOURCE=none` | Nenhum `.nvmrc` nem Dockerfile — informar utilizador e solicitar a versão |
| 2 | `SOURCE=dockerfile` (sem `NODE_VERSION`) | Dockerfile existe mas versão não é extraível — informar utilizador e solicitar a versão. **Nunca** criar `.nvmrc` (não há versão a gravar) |

### 2. NVM install + use

```bash
~/.claude/plugins/local/scrapup/skills/utilitarios/setup-node-env/nvm-install-use.sh <project-dir>
```

Se exit 0: prosseguir. Caso contrário: informar utilizador e aguardar orientação.

### 3. Verificar NPM_TOKEN

```bash
~/.claude/plugins/local/scrapup/skills/utilitarios/setup-node-env/check-npm-token.sh
```

| Exit | Ação do agente |
|------|----------------|
| 0 | `NPM_TOKEN` disponível — prosseguir para o passo 4 |
| 1 | Token ausente — solicitar ao utilizador e exportar `NPM_TOKEN` no ambiente antes de prosseguir |

Fallback se o utilizador não fornecer o token (exit 1): prosseguir para o passo 4 ciente de que pacotes privados falharão na instalação, **ou** abortar com mensagem explícita. Decisão do utilizador — não inventar nem inferir token.

### 4. npm install

```bash
~/.claude/plugins/local/scrapup/skills/utilitarios/setup-node-env/npm-install.sh <project-dir>
```

| Exit | Ação do agente |
|------|----------------|
| 0 | Sucesso — Node.js configurado |
| 1 | Conflito de versão — analisar output, identificar versão necessária, executar [`update-node-version.sh`](update-node-version.sh) + [`docker-build.sh`](docker-build.sh) + [`npm-install.sh`](npm-install.sh) novamente |
| 2 | Outra falha — informar utilizador (rede, registry, permissões), aguardar orientação |

### 5. Resolver conflito de versão (se exit 1 no passo 4)

Resolver conflito **nunca** com `--legacy-peer-deps` — atualizar a versão e rebuildar. Executar na ordem, mapeando cada exit antes de avançar:

```bash
~/.claude/plugins/local/scrapup/skills/utilitarios/setup-node-env/update-node-version.sh <nova-versão> <project-dir>
~/.claude/plugins/local/scrapup/skills/utilitarios/setup-node-env/docker-build.sh <project-dir>
~/.claude/plugins/local/scrapup/skills/utilitarios/setup-node-env/npm-install.sh <project-dir>
```

`update-node-version.sh`:

| Exit | Ação do agente |
|------|----------------|
| 0 | Arquivos atualizados e nvm na nova versão — prosseguir para `docker-build.sh` |
| 1 | Versão não informada (erro de invocação) — corrigir o argumento e reexecutar |

`docker-build.sh`:

| Exit | Ação do agente |
|------|----------------|
| 0 | Build OK — prosseguir para `npm-install.sh` |
| 1 | Dockerfile não encontrado — pular o build (não bloqueia) e prosseguir para `npm-install.sh` |
| 2 | `NPM_TOKEN` não definido — voltar ao passo 3 (solicitar/exportar token) e reexecutar |
| 3 | Build falhou — informar utilizador, anexar output, aguardar orientação |

`npm-install.sh` (segunda passagem): mesmo mapeamento do passo 4. Se voltar a sair **1** (conflito persistente): escalar ao utilizador com o output, não repetir o ciclo automaticamente; saída **2** (outra falha): informar e aguardar orientação.

## Integração com Outras Skills

| Skill | Como integra |
|-------|-------------|
| /scrapup:baseline-assessment | Orquestradora na inicialização da demanda — invoca esta skill ao avaliar readiness (detecção de versão Node, nvm, `NPM_TOKEN`, `npm install` de setup inicial), antes da classificação e persistência do baseline. **Não confundir** com `npm install`/execução de testes pós-implementação, que pertencem ao ciclo TDAD |
| /scrapup:scrapup-forge | **Não invoca diretamente.** Delega à /scrapup:baseline-assessment na seção 0; esta skill é acionada por dentro da baseline-assessment |
| /scrapup:enable-docker-server | Garantir Docker disponível antes de [`docker-build.sh`](docker-build.sh) |
