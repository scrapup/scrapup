---
name: commit-message
description: Sempre utilize esta skill para criar ou revisar mensagens de commit (Conventional Commits — tipos em inglês, texto em PT-BR). Faz git add determinístico dos arquivos tocados pela mudança (nunca git add . ou -A) e executa git commit. Aplica-se ao redigir, validar ou executar git commit.
user-invocable: true
metadata:
  obsidian_identifier: scrapup:commit-message
---

# Padrão de Commits (Conventional Commits PT-BR)

Redija e valide toda mensagem de commit segundo o padrão **Conventional Commits 1.0.0** (changelogs automáticos e rastreabilidade semântica dependem dessa consistência).

**Utilizador:** a pessoa que interage com o agente no Claude Code. Para a definição completa do papel do utilizador, ver a skill /scrapup:perfil-utilizador.

**Comunicação:** Aplicar a filosofia de comunicação /scrapup:cnv — tom direto, imperativo, sem preâmbulo.

## 1. Estrutura Obrigatória

*   Ao escrever ou sugerir mensagens de commit, sempre respeite o [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/#specification).

```text
<tipo>(<escopo opcional>): <descrição no imperativo>

[Corpo opcional com detalhes da motivação e solução]

[Rodapé opcional para Breaking Changes ou referência a issues]
```

## 2. Idioma e Gramática

*   **Idioma:** A descrição DEVE ser escrita em **Português do Brasil (PT-BR)**.
*   **Tempo Verbal:** Use o **Imperativo Presente**.
    *   ✅ Correto: "adiciona endpoint", "corrige erro", "refatora serviço".
    *   ❌ Errado: "adicionado", "corrigindo", "added", "fixed".
*   **Caixa:** Inicie a descrição com letra minúscula.
*   **Pontuação:** Não use ponto final no título (primeira linha).
*   **Termos técnicos:** Mantenha em **inglês** nomes de tecnologias, conceitos de programação, APIs e jargão de domínio (ex.: endpoint, timeout, webhook, DTO, pipeline, deploy, bugfix, refactor, merge, branch, cache, middleware, API, SDK). O restante da frase permanece em PT-BR.

## 3. Limite de Caracteres

*   **Descrição (primeira linha):** A descrição do commit DEVE ter no **máximo 100 caracteres**.
*   **Corpo:** As linhas no corpo do commit DEVEM ter quebra de linha quando forem superiores a 100 caracteres (cada linha do corpo com no máximo 100 caracteres).

> **Nota:** O limite de **100 caracteres** é o configurado no linter de mensagem deste projeto, e difere da convenção clássica **50/72** do Conventional Commits. Quando o linter do repositório impuser outro limite, ele prevalece — ajuste a mensagem ao limite efetivo do projeto.

## 4. Tipos Permitidos (`<tipo>`)

Utilize apenas os tipos abaixo. O uso de tipos fora desta lista será rejeitado pelo linter.

| Tipo | Descrição | Exemplo |
| :--- | :--- | :--- |
| **feat** | Nova funcionalidade para o utilizador ou sistema. | `feat(api): implementa endpoint de cotação` |
| **fix** | Correção de defeito (bug). | `fix(sync): corrige erro de timeout no webhook` |
| **docs** | Alterações apenas em documentação. | `docs: atualiza diagrama de sequência no readme` |
| **style** | Formatação, ponto e vírgula, lint (sem alteração de lógica). | `style(core): aplica formatação prettier` |
| **refactor** | Alteração de código que não corrige bug nem adiciona feature. | `refactor(math): simplifica lógica de arredondamento` |
| **perf** | Melhoria de desempenho. | `perf(mongo): adiciona índice para planMvId` |
| **test** | Adição ou correção de testes. | `test(e2e): adiciona cenário de falha no webhook` |
| **chore** | Alterações de build, ferramentas, deps (sem alteração de src). | `chore(deps): atualiza nestjs para v11` |
| **ci** | Alterações em arquivos de CI/CD (GitHub Actions). | `ci: configura pipeline de deploy` |
| **revert** | Reversão de um commit anterior. | `revert: reverte commit a1b2c3d` |

## 5. Escopo opcional (`<escopo>`)

O escopo indica **qual parte do sistema ou do repositório** é afetada pelo commit. É opcional, mas recomendado para facilitar filtros em changelog e revisões.

*   **Como definir:** Use o nome do **módulo**, **pacote**, **camada** ou **área funcional** principal tocada pelas alterações (ex.: pasta do código, domínio, serviço).
*   **Formato:** Uma única palavra ou termo em **minúsculas**, sem espaços; use hífen se necessário (ex.: `api`, `auth`, `pricing`, `e2e`, `core`).
*   **Quando usar:** Preencha o escopo quando a mudança for claramente localizada; omita quando o commit for genérico (ex.: `docs: atualiza readme`).
*   **Consistência:** Mantenha os mesmos nomes de escopo ao longo do projeto (evite misturar `api` e `API` ou `backend` e `server`).

**Exemplos de escopos:** `api`, `auth`, `core`, `deps`, `e2e`, `mongo`, `sync`, `math`, `pricing`, `ci`.

## 6. Breaking Changes

Alterações que quebram a compatibilidade (ex: mudança de contrato de API) devem ser sinalizadas explicitamente:

1.  Adicionando uma exclamação `!` após o tipo/escopo.
2.  Adicionando o rodapé `BREAKING CHANGE:` com a descrição.

**Exemplo:**
```text
feat(api)!: altera contrato de resposta do endpoint quote

BREAKING CHANGE: o campo 'price' agora retorna um objeto com moeda e valor.
```

## 7. Exemplos Práticos (Do & Don't)

### ✅ Aprovados
*   `feat(pricing): implementa cálculo de desconto por idade`
*   `fix(core): corrige validação de cpf no DTO`
*   `docs: adiciona ADR de arquitetura ODS`
*   `chore: remove logs desnecessários`

### ❌ Reprovados (O Agente deve corrigir)
*   `Fixed bug in calculation` (Inglês / Passado) -> **Corrigir para:** `fix(math): corrige erro no cálculo`
*   `Adicionando nova rota` (Gerúndio) -> **Corrigir para:** `feat(api): adiciona nova rota`
*   `update` (Tipo genérico não permitido) -> **Corrigir para:** `chore` ou `refactor`

## 8. Checklist de validação

Antes de usar ou sugerir uma mensagem de commit, verifique:

- [ ] **Estrutura:** Segue o formato `tipo(escopo?): descrição` e, se houver, corpo/rodapé opcionais.
- [ ] **Tipo:** É um dos permitidos (`feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `chore`, `ci`, `revert`).
- [ ] **Idioma:** Descrição em **PT-BR** e no **imperativo presente** (ex.: "adiciona", "corrige").
- [ ] **Termos técnicos:** Nomes de tecnologias, APIs e jargão de programação mantidos em **inglês**.
- [ ] **Caixa e pontuação:** Descrição começa com **minúscula** e **sem ponto final** no título.
- [ ] **Tamanho:** A **primeira linha** tem no **máximo 100 caracteres**.
- [ ] **Corpo:** Se existir corpo, cada linha tem no **máximo 100 caracteres** (quebras quando passar).
- [ ] **Escopo (se usado):** Está em minúsculas, sem espaços e consistente com o projeto.
- [ ] **Breaking change:** Se houver mudança incompatível, há `!` após tipo/escopo e rodapé `BREAKING CHANGE:`.
- [ ] **Sem coautoria do agente:** A mensagem **não** contém `Co-Authored-By: Claude` nem qualquer trailer/linha de coautoria ou geração pelo agente.

## 9. Comportamento do agente em relação ao Git

*   **Proibição de coautoria do agente (EXTREMA IMPORTÂNCIA):** O agente é **ferramenta**; a autoria é **exclusivamente humana**. A mensagem de commit gerada por esta skill **nunca** contém `Co-Authored-By: Claude` nem qualquer outro trailer ou linha que atribua coautoria, geração ou assistência ao agente (ex.: `Co-Authored-By: Claude <...>`, `Generated with ...`, `🤖 ...`). Isto aplica-se **independentemente** do CLAUDE.md do projeto — a regra vive também nesta skill e não depende de contexto externo.
    *   Ao **gerar** a mensagem: não adicionar esses trailers em nenhuma hipótese.
    *   Ao **revisar** uma mensagem que já contenha esse trailer: removê-lo antes de validar.
    *   Se um commit já criado contiver o trailer: removê-lo via `git commit --amend` (ou rebase) antes de qualquer push; avisar o utilizador quando exigir force-push.
*   **Stage determinístico:** O agente **nunca** deve executar `git add .`, `git add -A` ou qualquer forma não-explícita — isso arrasta mudança não preparada. **Pode e deve** fazer `git add` dos arquivos claramente relacionados ao contexto do pedido, listados explicitamente (ex.: `git add src/foo.ts test/foo.spec.ts`). Não adicionar arquivos alheios à mudança solicitada.
*   **Escopo do commit:** O commit deve considerar **apenas** os arquivos que o agente tocou na mudança solicitada (mais o que o utilizador já tiver em stage). Em caso de dúvida sobre se um arquivo pertence ao escopo, não fazer o stage dele e sinalizar ao utilizador.
*   **Execução do commit sem aprovação prévia da mensagem:** Após validar a mensagem contra este documento, o agente **executa** `git commit` com essa mensagem **sem pedir aprovação** ao utilizador. Pode incluir a mensagem no resumo da resposta (antes ou depois do comando), mas o fluxo não bloqueia à espera de confirmação explícita.
*   **Falha de validação do commit — nunca usar `--no-verify`:** O agente **nunca** usa `--no-verify` nem sugere o seu uso; bypassar a validação compromete a segurança e a consistência do repositório. Diante de uma falha, classifique a causa antes de escalar:
    *   **Falha do linter de mensagem (auto-reparável):** Se a falha for do linter da própria mensagem (formato Conventional Commits, tipo inválido, idioma, caixa, pontuação ou limite de caracteres), corrija a mensagem conforme as seções 1-7 e **re-tente** o `git commit`, até no **máximo 3 tentativas** de auto-reparo. A cada tentativa, ajustar apenas a mensagem ao erro reportado pelo linter — nunca o stage nem `--no-verify`.
    *   **Esgotadas as tentativas, ou falha não relacionada à mensagem:** Se o auto-reparo esgotar as 3 tentativas, ou se a falha for de **hook não relacionado à mensagem** (test, lint de código, build, secret scan, etc. — fora do escopo desta skill), o agente **informa que não é possível executar o commit com segurança** e **entrega ao utilizador a mensagem de commit** preparada e a causa exata da falha, para que o utilizador decida como proceder (corrigir a causa, ajustar a mensagem ou executar o commit manualmente, assumindo a responsabilidade). Não tentar auto-reparar falhas de hook fora do escopo da mensagem.
    *   Se a falha ocorrer no âmbito de um **plano de execução** em que existam **tarefas posteriores** dependentes do commit, o agente deve **solicitar explicitamente a ação do utilizador** e **aguardar a confirmação** antes de prosseguir com as próximas atividades. Não assumir que o commit foi feito nem continuar o plano sem essa confirmação.

## 10. Instruções para o Agente

Ao receber um pedido para "commitar" ou "sugerir mensagem de commit":
1.  Faça `git add` explícito dos arquivos tocados pela mudança solicitada (nunca `git add .`/`-A`) e analise o que está em stage.
2.  Identifique o módulo principal afetado (escopo).
3.  Determine a intenção semântica (tipo).
4.  Escreva a mensagem seguindo estritamente as regras de gramática PT-BR acima.
5.  Execute `git commit` com essa mensagem (sem pedir aprovação prévia); relate o resultado e a mensagem usada na resposta.
6.  Se houver múltiplas alterações desconexas, sugira a separação em múltiplos commits atômicos.
7.  Respeite o limite de 100 caracteres na descrição (primeira linha) e quebre as linhas do corpo quando ultrapassarem 100 caracteres.

## 11. Contrato de saída por modo

Esta skill opera em dois modos. Cada um tem um retorno definido:

*   **Modo criar** (pedido de "commitar" / "sugerir e commitar"): retornar a **mensagem de commit** final usada e o **resultado do `git commit`** (sucesso com hash/branch, ou falha com a causa exata e a classificação da seção 9). Em caso de separação em múltiplos commits, listar cada mensagem e o respectivo resultado.
*   **Modo revisar** (pedido de "revisar/validar mensagem", sem executar commit): retornar o **veredito** (aprovada / reprovada), a **lista de violações** ao checklist da seção 8 (item violado + motivo) e a **mensagem corrigida** pronta para uso. Não executar `git commit` neste modo.