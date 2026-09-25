---
name: inception
description: Collects the initial scraps (documents, messages, a prompt, transcripts, or a set of artifacts) and produces brief.md — the single, complete artifact of the Inception phase — in validated layers (grounding chain), at shallow depth, asking the user instead of inferring gaps, and closing with a rigorous LCO review via the reviewer-process-lco agent. Use when the user wants to start a feature/initiative from raw material, produce the Inception brief, collect scraps, ground the "why/what" before specifying, or open the cycle in the Inception phase.
user-invocable: true
---

# scrapup Inception — da sucata ao brief

Conduz a **fase de Inception** do Unified Process: recebe **scraps** (material bruto) e produz o
**`brief.md`** — o **artefato único e completo da Inception** — crescendo o contexto em **camadas
validadas** com o utilizador, em profundidade **rasa**, e fechando no marco **LCO**.

Princípio operacional: **o agente acreta contexto; o humano valida cada camada.** Inferir para
**organizar** o que chega; **perguntar** para **preencher** o que falta — nunca chutar lacuna.

## Quando usar / não usar

**Usar:** iniciar uma feature/iniciativa a partir de scraps; produzir o brief de Inception; fundamentar
o porquê/o quê antes de especificar; abrir o ciclo na Inception.

**Não usar:** detalhar requisitos/arquitetura (isso é Elaboration — `spec.md`/`plan.md`); fatiar tarefas
(Construction); executar código. Encaminhe para a fase seguinte ao fim do LCO.

## Entrada — coleta de scraps

Aceita qualquer origem do pedido: **documento, mensagem (Slack), prompt, transcrição de reunião, ou um
conjunto completo de artefatos**. Coletores do ecossistema, quando aplicável:

Todo scrap entra no **Lastro** (§1 do brief) com tipo + link/anexo + **data de captura**. O brief
**destila** os scraps; o link não dispensa a síntese. Anexar conteúdo crítico (link rot).

## Regra de ouro — inferir para organizar, PERGUNTAR para preencher

| Inferência **permitida** | Inferência **proibida** |
|--------------------------|--------------------------|
| Classificar, rotear e organizar os scraps; mapear o recebido às camadas do brief | Preencher **lacunas de conteúdo ou decisão** |
| Propor um rascunho de camada **a partir do que os scraps dizem** | Inventar escopo, atores, riscos, números, decisões |

Diante de lacuna ou ambiguidade genuína: **pergunte** via `AskUserQuestion` (recurso padrão do
scrapup), com opções concretas e uma recomendação quando houver. Nos **fluxos core da Inception**
(vision/escopo, use cases, arquitetura candidata, business case), a **validação do utilizador é
obrigatória** antes de avançar. Use `/scrapup:brainstorming` para explorar intenção quando os scraps
forem vagos. Tom: `/scrapup:communication`.

## Cânone da Inception (UP embutido, autocontido)

Tudo que o fluxo precisa está **aqui** — a skill é **autocontida quanto ao cânone**; **não consulte o
mentor nem a fonte primária em runtime**:

- **Profundidade rasa ("inch deep"):** identificar e fundamentar, não detalhar. O brief é o suficiente
  para o **go/no-go do LCO**; o detalhe vem na Elaboration. **Calibração canônica** (Table 13.1, Cap.13):
  ~**50%** dos use cases **identificados**, só ~**10% detalhados**; demais modelos rudimentares. Produzir
  detalhe pleno **viola** o raso (é a mesma régua do `reviewer-process-lco`).
- **Deliverables (consolidados no brief, [p.392]):** lastro · vision · domain/glossário · feature list ·
  risk list+rating · use-case model · requisitos suplementares (NFR) · arquitetura **candidata** ·
  business case (rascunho) · plano de fase · **fronteira** · checklist LCO.
- **Critérios do marco LCO** ([p.443-444]): escopo claro; atores identificados; **arquitetura candidata**
  à vista (por promessa, sem protótipo exigido); riscos críticos identificados **e** mitigáveis; business
  case justifica o investimento; stakeholders concordam.
- **Convenções:** IDs `UCnnnn` / `FTnnnn` / `RKnnnn` (4 dígitos, a partir de 0001); fluxo de use case em
  lista ordenada `1, 2, 2.1, 3`; estrutura UML por UC (ator · pré-condições · fluxo · pós-condições ·
  relações); **autenticação é pré-condição, não «include»**; diagramas **C4 N1 + N2 raso** (N3 e
  sequence de componentes → Elaboration); risco ordena as iterações (ver "Rating de risco").

## Fluxo — produção do brief em camadas validadas (cadeia de lastro)

Grave o brief em **`docs/specs/{iniciativa}/brief.md`** desde a **primeira camada** (não só em contexto).
Resolva `{iniciativa}` a partir do nome no scrap; se ambíguo, **pergunte** (`AskUserQuestion`) — não
inferir o slug.

Use o template `templates/brief-template.md`. Produza **camada a camada**, na ordem **dependência +
risco** — cada elo lastreia o próximo. Para cada camada: (a) **rascunhe** a partir dos scraps
(inferência de organização); (b) **pergunte** o que falta (`AskUserQuestion`); (c) **valide** com o
utilizador; só então avance.

1. **Lastro** (fontes) → 2. **Vision/escopo** (fundacional — validar cedo) → 3. **Domain/glossário** →
4. **Feature list** (FT) → 5. **Risk list + rating** (RK) → 6. **Use-case model** (UC; atores, specs
rasas, ranking, trace) → 7. **Requisitos suplementares** (NFR) → 8. **Arquitetura candidata** (direção +
C4 N1/N2) → 9. **Business case** (rascunho) → 10. **Plano de fase** → 11. **Fronteira** → 12. **Checklist
LCO**.

Cada checkpoint é um **minor milestone**: registre a validação antes de seguir. Mantenha o estado em
`/scrapup:saga-session` em fluxos longos. Diagramas (C4 N1/N2, use-case, domain, state machine) via
`/scrapup:expert-plantuml`.

## Rating de risco (como executar — camada 5)

Para **cada risco** da risk list:

1. **Probabilidade** — chance do evento indesejável (*"probability that a project will experience
   undesirable events"*, [p.128]): `baixa` · `média` · `alta`.
2. **Impacto** — que partes do projeto/sistema o risco afeta e quão grave ([p.362-363]): `baixo` ·
   `médio` · `alto`.
3. **Rating = Priority**: os rótulos **`critical`** · **`significant`** · **`routine`** são **canônicos**
   ([p.362]); a matriz abaixo é **operacionalização scrapup** de Prob×Impacto (não há matriz canônica
   única no livro):

   | Impacto ↓ \ Prob → | baixa | média | alta |
   |---|---|---|---|
   | **alto** | significant | critical | critical |
   | **médio** | routine | significant | critical |
   | **baixo** | routine | routine | significant |

4. **Campos da risk list** ([p.362-363]): *Description · Priority (rating) · Impact · Monitor ·
   Responsibility · Contingency*.
5. **O rating ordena (risk-driven):** **`critical`** é atacado **cedo** (Fig.5.1, [p.124]); cada risco
   traduz-se num **use case mitigador** que entra na **ranking** (camada 6) na posição do seu nível
   ([p.365]).
6. A risk list é **dinâmica**: cresce ao descobrir, encolhe ao retirar/expirar.

**Não inferir** probabilidade nem impacto — quando incerto, **perguntar** (`AskUserQuestion`). O rating é
input do utilizador-validador, não chute do agente.

## Revisão LCO (gate de fim de fase)

Quando o `brief.md` estiver descrito e validado pelo utilizador, despache o agent
**`scrapup:reviewer-process-lco`** **injetando no prompt o conteúdo integral do `brief.md` e o
`templates/brief-template.md`** (contrato de entrada do reviewer — ele não lê caminhos por rotina). Em
seguida, **como orquestrador**:

1. **Aplique as correções auto-corrigíveis** que o reviewer marcou (`auto_corrigivel: true`) — formato de
   ID, numeração de fluxo, headers, convenções —, **sem inferir lacunas de conteúdo**.
2. **Apresente ao utilizador** um **sumário** + os **pontos de atenção** (lacunas e findings que exigem
   decisão). Lacuna **não** é preenchida pelo agente — vira pergunta/atenção.
3. **Auxilie o utilizador** nas modificações do brief (perguntando, não inferindo).
4. **Re-execute** o reviewer sobre o brief alterado **se solicitado**.

O reviewer **recomenda** go/no-go; o **sign-off do LCO é do humano-validador** (sela o marco). NO-GO se
houver Blocker/Critical; GO condicional se só Major; GO se só Minor/Nit. Se o brief permanecer **NO-GO**
após correções, persista o estado em `/scrapup:saga-session` e **devolva a decisão ao validador** — o
gatilho de re-execução é do utilizador (sem teto rígido de iterações). Se o validador **reprovar
definitivamente** (reescopar ou **cancelar** — consequência canônica do marco LCO), registre o desfecho
no saga e **encerre, sem re-rodar**.

## Saída

- **`brief.md`** validado (template preenchido, raso, em camadas) — gravado em
  `docs/specs/{iniciativa}/brief.md` (caminho convencionado, consumível pela Elaboration).
- **Relatório LCO** ao utilizador, derivado do JSON do reviewer: **contagem por severidade** · **pontos
  de atenção** (lacunas/decisões) · correções **auto-aplicadas** · **recomendação** (GO / GO condicional
  / NO-GO).

Ao o validador **selar o LCO**, a iniciativa segue para a **Elaboration**.

## Integração

- **Intenção:** `/scrapup:brainstorming` (scraps vagos).
- **Coleta de scraps:** `/scrapup:expert-clickup`, `/scrapup:expert-slack`, `/scrapup:tool-whisper`.
- **Perguntar:** `AskUserQuestion` (padrão do scrapup).
- **Diagramas:** `/scrapup:expert-plantuml` (C4 N1/N2, use-case, domain, state machine).
- **Gate LCO:** agent `scrapup:reviewer-process-lco`.
- **Tom:** `/scrapup:communication`. **Estado:** `/scrapup:saga-session`.
- **Template:** `templates/brief-template.md`.

## Anti-padrões

- **Não inferir lacunas** — perguntar (`AskUserQuestion`). Não inventar escopo/atores/riscos/números.
- **Não detalhar** — manter raso; fluxos alternativos, C4 N3, sequence de componentes e ADR formal são
  da Elaboration.
- **Não selar o LCO sozinho** — o reviewer recomenda; o humano-validador sela.
- **Não pular a validação por camada** — produção é incremental e validada, não big-bang.
