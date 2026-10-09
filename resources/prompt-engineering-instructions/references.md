# References Matrix

Matriz de rastreabilidade por modulo e secao, com hierarquia de confiabilidade:

1. `official_doc`
2. `standard`
3. `paper`
4. `benchmark`
5. `blog` (apenas suporte, nunca fonte principal)

## Criterios de inclusion/exclusion

- Incluir apenas fontes com data/versionamento verificavel e URL acessivel.
- Excluir fonte sem autoria identificavel para recomendacao principal.
- Em caso de conflito: priorizar `official_doc`, registrar decisao e acao de mitigacao.

## Periodicidade de revisao por trilha

| Trilha | Periodicidade |
|---|---|
| Fundamentos | Trimestral |
| Structured outputs e tool use | Mensal |
| RAG e grounding | Mensal |
| Seguranca e risco | Quinzenal |
| Avaliacao e PromptOps | Mensal |
| Playbooks por caso de uso | Bimestral |

## Matriz por secao

| modulo | secao | fonte | tipo | data_revisao | confianca | key_finding | aplicabilidade |
|---|---|---|---|---|---|---|---|
| fundamentos | criterios de qualidade de prompt | https://platform.openai.com/docs/guides/prompt-engineering | official_doc | 2026-03-28 | high | Clareza de instrucao e formato explicito reduzem variancia | immediate |
| fundamentos | hierarquia de instrucoes | https://docs.anthropic.com/en/docs/build-with-claude/prompt-engineering/overview | official_doc | 2026-03-28 | high | Separacao de regra estavel e contexto variavel melhora controle | immediate |
| fundamentos | desenho de instrucoes | https://www.promptingguide.ai/ | benchmark | 2026-03-28 | medium | Padroes comparativos ajudam onboarding rapido | contextual |
| fundamentos | best practices de Agent Skills (frontmatter, description, progressive disclosure, voz) | https://docs.claude.com/en/docs/agents-and-tools/agent-skills/best-practices | official_doc | 2026-06-27 | high | name <=64 chars lowercase/hifen sem "anthropic"/"claude"; description <=1024 chars sem XML, 3a pessoa, what+when; SKILL.md <500 linhas; refs 1 nivel; ref >100 linhas com TOC; voz imperativa; "concise is key"; degrees of freedom; build evals first + baseline | immediate |
| avaliacao-e-promptops | eval-driven de skills + skill-creator (test/measure/refine) | https://claude.com/blog/improving-skill-creator-test-measure-and-refine-agent-skills | official_doc | 2026-06-27 | high | Criar >=3 evals antes de instrucoes; baseline com/sem skill em sessao limpa; medir trigger e output separadamente; testar Haiku/Sonnet/Opus | immediate |
| seguranca-e-risco | Agent Skills e conteudo nao confiavel / least privilege | https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills | official_doc | 2026-06-27 | high | Progressive disclosure; conteudo nao confiavel so em tool_result; skills herdam privilegio ambiente (shell/fs/secrets) -> escopo minimo | immediate |
| fundamentos | convencao de escrita de skills (corroboracao empirica) | https://github.com/tech-leads-club/agent-skills (skill (creation)/skill-architect + references/quality-checklist.md) | community_catalog | 2026-06-27 | medium | Corrobora a doc oficial em 78 SKILL.md: description "What+When+What NOT" com roteamento negativo; escada diretiva; trigger testing should/should-NOT | contextual |
| structured-outputs-e-tool-use | JSON schema e validacao | https://platform.openai.com/docs/guides/structured-outputs | official_doc | 2026-03-28 | high | Schema-first reduz falha de parsing | immediate |
| structured-outputs-e-tool-use | function calling e tools | https://docs.anthropic.com/en/docs/agents-and-tools/tool-use/overview | official_doc | 2026-03-28 | high | Tool call precisa de contratos estritos e observabilidade | immediate |
| structured-outputs-e-tool-use | design de API orientada a schema | https://json-schema.org/understanding-json-schema/ | standard | 2026-03-28 | high | Regras formais evitam ambiguidade semantica | immediate |
| rag-grounding-citations | design de RAG | https://www.pinecone.io/learn/retrieval-augmented-generation/ | benchmark | 2026-03-28 | medium | Separar retrieval/synthesis melhora qualidade de resposta | contextual |
| rag-grounding-citations | grounding e citations | https://platform.openai.com/docs/guides/retrieval | official_doc | 2026-03-28 | high | Citar fonte por trecho melhora auditabilidade | immediate |
| rag-grounding-citations | factuality e calibracao | https://arxiv.org/abs/2305.14251 | paper | 2026-03-28 | medium | Hallucination cai com verificacao de evidencia | experimental |
| seguranca-e-risco | prompt injection | https://owasp.org/www-project-top-10-for-large-language-model-applications/ | standard | 2026-03-28 | high | Prompt injection deve ser tratado como ataque de entrada | immediate |
| seguranca-e-risco | secure design para LLM apps | https://www.nist.gov/itl/ai-risk-management-framework | standard | 2026-03-28 | high | Controles por risco e governanca minimizam incidentes | immediate |
| seguranca-e-risco | safety guidance para modelos | https://ai.google.dev/gemini-api/docs/safety-guidance | official_doc | 2026-03-28 | high | Safety settings e policy por caso de uso precisam de tuning explicito | immediate |
| avaliacao-e-promptops | avaliacao sistematica | https://platform.openai.com/docs/guides/evals | official_doc | 2026-03-28 | high | Evals por regressao sao obrigatorias para release seguro | immediate |
| avaliacao-e-promptops | observabilidade de modelos | https://docs.langchain.com/docs/guides/evaluation | benchmark | 2026-03-28 | medium | Traces e scorecards ajudam detectar drift | contextual |
| avaliacao-e-promptops | governanca e risco de IA | https://ai.google/responsibility/responsible-ai-practices/ | official_doc | 2026-03-28 | high | Governanca precisa de ownership e ciclo de revisao definido | immediate |
| playbooks-por-caso-de-uso | agentes com ferramentas | https://docs.anthropic.com/en/docs/agents-and-tools/overview | official_doc | 2026-03-28 | high | Definir limites de autonomia evita acoes indevidas | immediate |
| playbooks-por-caso-de-uso | operacao de assistentes de coding | https://platform.openai.com/docs/guides/agents | official_doc | 2026-03-28 | high | Playbook com fallback reduz falhas em tarefas longas | immediate |
| playbooks-por-caso-de-uso | operacao orientada a runbook | https://sre.google/sre-book/service-level-objectives/ | standard | 2026-03-28 | high | Runbooks com SLO e criterios de escalacao aumentam previsibilidade | contextual |

## Conflitos entre fontes e decisoes

| modulo | conflito | decisao | mitigacao |
|---|---|---|---|
| rag-grounding-citations | Parte das fontes de benchmark aceita resposta sem citacao completa; docs oficiais reforcam grounding com fonte verificavel | Adotar exigencia de citacao para afirmacoes factuais | Marcar resposta sem fonte como "incerta" e exigir revisao |
| structured-outputs-e-tool-use | Frameworks toleram JSON "quase valido"; docs oficiais recomendam schema estrito | Adotar schema-first + validacao obrigatoria | Repair loop com no maximo 2 tentativas antes de erro controlado |
| seguranca-e-risco | Algumas fontes sugerem mitigacao apenas por prompt; OWASP/NIST exigem defesa em camadas | Adotar defense-in-depth | Aplicar validacao de input + policy de tool + filtro de output |

## Secoes com baixa confianca (revisitacao)

- `rag-grounding-citations` / benchmarking de rerankers (dependente de contexto de corpus)
- `avaliacao-e-promptops` / thresholds universais de score (variam por dominio)
