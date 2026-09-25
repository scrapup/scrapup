---
name: skill-builder
description: "Constrói skills, agents e commands do ecossistema scrapup a partir de uma necessidade, em fluxo conduzido (descobrir, desenhar, escrever, validar, entregar), fundado nas best practices oficiais de Agent Skills da Anthropic e na convenção §Padrao de escrita do reviewer-prompt-engineering. Use quando o utilizador pedir para criar skill, construir skill, nova skill, transformar um workflow em skill, criar agent/command do scrapup, ou padronizar/refatorar um artefato de instrução existente. Não usar para revisar/validar artefato pronto (use /scrapup:review-skill) nem para especificar features de produto (use /scrapup:scrapup-blueprint)."
user-invocable: true
metadata:
  obsidian_identifier: scrapup:skill-builder
---

# Skill Builder

Conduza a construção de um artefato de instrução do scrapup — **skill** (`SKILL.md`), **agent** (`agents/*.md`) ou **command** (`commands/*.md`) — do entendimento da necessidade até a entrega validada. Entenda o problema antes de escrever; uma skill ruim que aciona errado e dá resultado inconsistente é pior que nenhuma.

## Idioma

Produza todo o artefato e a interação em **Português do Brasil (PT-BR)**, com termos técnicos consagrados em inglês na forma original (endpoint, deploy, commit, branch, frontmatter, trigger, prompt, skill, agent, command). O campo `description` do frontmatter segue a mesma regra.

## Quando usar / não usar

**Usar** para criar ou refatorar artefatos de instrução do scrapup: **skill** (`SKILL.md`), **agent** (review/persona) ou **command** (ponte MCP). Para rule, prompt ou playbook, trate como skill (mesmo frontmatter e convenções) e ajuste o diretório.

**Não usar** (delegar):

| Necessidade | Destino |
|---|---|
| Validar/revisar artefato já escrito (12 dimensões, go/no-go) | /scrapup:review-skill |
| Especificar feature de produto (spec/plan/tasks) | /scrapup:scrapup-blueprint |
| Explorar intenção antes de qualquer escrita criativa | /scrapup:brainstorming |
| Tom de comunicação com destinatários | /scrapup:cnv |
| Sincronizar README + diagrama após mexer no plugin | /scrapup:regra-scrapup-doc-sync |

## Fluxo

```
DESCOBRIR → DESENHAR → ESCREVER → VALIDAR → ENTREGAR
```

Avance em ordem. Não escreva o `SKILL.md` antes de fechar DESCOBRIR e DESENHAR. Pergunte ao utilizador em vez de inferir lacunas de escopo, gatilho ou fronteira.

### 1. Descobrir

Levante, perguntando ao utilizador (uma área por vez, não despeje o checklist):

- **Resultado** — que workflow tornar consistente; um exemplo concreto do que se faz hoje, passo a passo.
- **Dor sem a skill** — o que sai errado (passos esquecidos, output inconsistente, re-explicação).
- **Gatilho** — que frases o utilizador diria para acionar; o que **não** deve acionar (fronteira com skill-irmã).
- **Tipo de artefato** — skill (workflow), agent (review/persona autocontida) ou command (ponte direta para MCP).
- **Tools/MCP** — quais ferramentas e integrações entram.

Saída: 2-3 casos de uso (gatilho, passos, resultado esperado) e a fronteira contra artefatos existentes.

### 2. Desenhar

Decida antes de escrever:

- **Tipo e diretório** — `skills/{modulo}/{nome}/SKILL.md`, `agents/reviewer-{nome}.md` ou `commands/{nome}.md`. Escolha o módulo existente que melhor casa o domínio; criar módulo novo é decisão de arquitetura — confirme com o utilizador.
- **Avaliação primeiro** — rode a tarefa-alvo **sem** a skill e registre a falha concreta; derive >= 3 cenários (eval) com comportamento esperado. Esses cenários são a fonte da verdade do que a skill precisa cobrir, e o baseline de regressão.
- **`description` (campo mais crítico)** — controla o acionamento. Rascunhe-a agora (ver contrato abaixo).
- **Progressive disclosure** — o que fica no `SKILL.md` (< 500 linhas) e o que vai para `references/`, `scripts/`, `assets/`.

### 3. Escrever

Aplique o digest de **Regras de escrita** (abaixo) e, no detalhe, o §Padrao de escrita autoritativo. Escreva o corpo em voz imperativa ao agente executor, conciso, com exemplos e fronteira explícita.

### 4. Validar

Despache **/scrapup:review-skill** contra o artefato novo. Não reimplemente o critique aqui — quem avalia as 12 dimensões e emite go/no-go é o agent `reviewer-prompt-engineering`. Corrija os findings Blocker/Critical/Major antes de entregar; re-despache para confirmar que caíram. Se após 2 ciclos um finding persistir (decisão de design conflitante, ambiguidade de escopo), pare e leve a decisão ao utilizador em vez de iterar indefinidamente.

### 5. Entregar

Apresente o artefato, o caminho, a frase de teste sugerida e o veredito do review. Acione **/scrapup:regra-scrapup-doc-sync** para atualizar `README.md` e `docs/diagrams/scrapup-modules.puml` quando o artefato altera a composição do plugin (skill/agent/command novo ou módulo novo).

## Regras de escrita — digest de write-time

**Fonte única de verdade:** a convenção completa e autoritativa é o **§Padrao de escrita** do agent `reviewer-prompt-engineering` (ancorado na doc oficial de Agent Skills da Anthropic e em `resources/prompt-engineering-instructions/references.md`). Em divergência, ela prevalece — e é ela que /scrapup:review-skill vai cobrar. O bloco abaixo é apenas o gatilho operacional para escrever; para o detalhe de cada regra, consulte o §Padrao. Ao evoluir a convenção, altere o §Padrao **primeiro**; este digest e o doc-sync acompanham.

- **Frontmatter** — `name` <= 64 chars (minúsculas/números/hifens, sem "claude"/"anthropic", igual ao diretório); `description` <= 1024 chars, linha única, sem `< >`; scrapup exige `metadata.obsidian_identifier: scrapup:{nome}` (e `user-invocable`/`paths` quando aplicável).
- **`description`** — 3ª pessoa, estrutura **What + When (gatilhos literais) + What NOT** (`Não usar para X, use /scrapup:Y`); calibrada para acionar com confiança no próprio domínio (descrição fraca sub-aciona; a disambiguação é função do What NOT).
- **Corpo** — voz imperativa ao executor; conciso (só o contexto que o modelo não tem); progressive disclosure (< 500 linhas, referências um nível, ref > 100 linhas com table of contents); degrees of freedom calibrados à fragilidade; workflows como checklist `- [ ]` e feedback loops; exemplos concretos.
- **Composição e segurança** — delegue por `/scrapup:{skill}` sem redeclarar passos; tool MCP qualificada (`Server:tool_name`); conteúdo não confiável só em `tool_result`; escopo mínimo de tools; operação destrutiva pede confirmação; sem secrets no corpo.

Exemplo do contrato de `description` (o erro mais comum):

```
BAD:  "Ajuda a criar skills."                         (vaga, não aciona)
BAD:  "Eu ajudo você a construir skills do scrapup." (1ª/2ª pessoa quebra a discovery)
GOOD: "Constrói skills, agents e commands do scrapup em fluxo conduzido. Use quando o
       utilizador pedir criar skill, construir skill ou nova skill. Não usar para revisar
       artefato pronto (use /scrapup:review-skill)."   (3ª pessoa, What+When+What NOT)
```

## Anti-patterns

| Anti-pattern | Por quê |
|---|---|
| Escrever o `SKILL.md` antes de descobrir gatilho e fronteira | Aciona errado e dá output inconsistente; refazer custa mais que perguntar |
| `description` vaga ou em 1ª/2ª pessoa | Quebra a discovery — é a causa #1 de skill que não aciona |
| Narrar o que a skill é ("esta skill faz...") | O corpo é ordem ao executor, não ficha técnica; gasta token e dilui a instrução |
| Redeclarar os passos de outra skill | Acopla à implementação dela; quando ela muda, o chamador mente. Aponte por `/scrapup:X` |
| `MUST`/`NEVER` em instrução trivial | Dilui o peso reservado a invariantes; prefira imperativo e justifique proibições críticas |
| Referências aninhadas (arquivo → arquivo → arquivo) | Claude faz leitura parcial e perde conteúdo; mantenha um nível |
| Pular o review | Entregar sem /scrapup:review-skill omite o gate go/no-go |
| Esquecer o doc-sync | README e diagrama ficam mentindo sobre a composição do plugin |

## Checklist de entrega

- [ ] Casos de uso (gatilho, passos, resultado) e fronteira definidos com o utilizador
- [ ] >= 3 evals/cenários e baseline (sem a skill) registrados
- [ ] Frontmatter conforme (name <= 64, description <= 1024 3ª pessoa What+When+What NOT, `obsidian_identifier`)
- [ ] Corpo imperativo, < 500 linhas, progressive disclosure com referências um nível
- [ ] Exemplos concretos e anti-patterns presentes
- [ ] /scrapup:review-skill despachado e findings Blocker/Critical/Major resolvidos
- [ ] Doc-sync (README + puml) avaliado e aplicado quando aplicável

## Integração

| Skill | Quando |
|---|---|
| /scrapup:review-skill | Fase Validar — gate de qualidade (12 dimensões, go/no-go) |
| /scrapup:brainstorming | Antes de Descobrir, quando a intenção ainda é difusa |
| /scrapup:cnv | Tom de qualquer texto a destinatários gerado pelo artefato |
| /scrapup:regra-scrapup-doc-sync | Fase Entregar — sincronizar README + diagrama |
| /scrapup:verification-before-completion | Antes de afirmar conclusão — evidência do review |
