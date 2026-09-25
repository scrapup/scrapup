# Template: Especificacao Funcional (spec.md) — Fase 1

## Contexto de Uso

Este template guia a criacao do artefato `spec.md`, a primeira fase do Spec-Driven Development.
O foco e exclusivamente na **intencao de negocio**: o que sera construido e por que.

Salvar como: `/docs/specs/<nome-da-feature>/spec.md`

## Restricoes da Fase 1

- **PROIBIDO** mencionar bancos de dados (MongoDB, MySQL), linguagens (Node.js, TypeScript) ou infraestrutura (RabbitMQ, Redis)
- **PROIBIDO** incluir diagramas C4, esquemas de banco ou nomes de bibliotecas
- **NUNCA** assuma regras de negocio criticas sem confirmacao do usuario
- Foco absoluto em **O Que** e **Porque**, nunca em **Como**

## Discovery Mode (Pre-Geracao)

Antes de preencher o template, verifique se possui respostas para:

1. Qual e o problema de negocio que origina esta funcionalidade?
2. Quem sao os atores (usuarios, sistemas) envolvidos?
3. Quais sao os limites inegociaveis (regras de negocio criticas)?
4. O que acontece quando os dados de entrada sao invalidos ou sistemas falham?
5. Existem SLAs de performance ou volumetria esperada?

Se faltarem respostas, liste 3-5 perguntas diretas ao usuario antes de gerar o artefato.

---

## Template

```markdown
# Especificacao Funcional: [Nome da Funcionalidade]

## 1. Visao Geral e Objetivo

- **O Problema:** [Qual e a dor atual do negocio ou do usuario?]
- **A Solucao (O Que):** [O que sera construido, de forma agnostica de tecnologia]
- **O Valor (Porque):** [Qual e o impacto esperado — ex: aumento de vendas, eliminacao de erros, reducao de tempo operacional]

## 2. Jornadas do Usuario (User Journeys)

Descreva o fluxo narrativo passo a passo para cada ator envolvido.

**Jornada Principal:**
1. [Ator] realiza [acao]
2. O sistema [reacao]
3. O sistema [proxima etapa]
4. [Resultado final esperado]

**Jornada Alternativa (se aplicavel):**
1. [Variacao do fluxo principal]

## 3. Regras de Negocio e Restricoes

Liste os limites inegociaveis. O que o sistema DEVE fazer e o que ele NAO PODE fazer.

| # | Regra | Tipo |
|---|---|---|
| RN-01 | [Descricao da regra] | Obrigatoria |
| RN-02 | [Descricao da regra] | Restritiva |
| RN-03 | [Descricao da regra] | Condicional |

## 4. Casos de Borda e Fluxos de Excecao (Zero Trust)

Defina o comportamento exato do sistema para cenarios de falha. Nunca assuma que dados externos sao confiaveis.

| Cenario | Comportamento Esperado | Severidade |
|---|---|---|
| Dados de entrada invalidos | [Ex: Rejeitar com erro de validacao] | Critica |
| Sistema externo indisponivel | [Ex: Retornar fallback ou enfileirar para retry] | Alta |
| Dados duplicados recebidos | [Ex: Idempotencia — ignorar duplicata] | Media |
| Timeout na operacao | [Ex: Falhar rapido, logar e notificar] | Alta |
| [Cenario especifico do dominio] | [Comportamento] | [Severidade] |

## 5. Criterios de Sucesso e SLAs

Como validamos que a entrega esta concluida e performatica?

**Criterios Funcionais:**
- [ ] [Ex: Todas as jornadas do usuario executam com sucesso]
- [ ] [Ex: Regras de negocio RN-01 a RN-03 validadas]

**SLAs de Performance:**
- Latencia: [Ex: < 400ms no P95]
- Throughput: [Ex: Suportar 50 req/s em pico]
- Disponibilidade: [Ex: 99.9% uptime]

**Criterios de Qualidade:**
- [ ] Cobertura de testes unitarios > [X]%
- [ ] Testes de integracao para todos os casos de borda

## 6. Glossario

Defina termos de dominio que possam ter interpretacao ambigua entre stakeholders.

| Termo | Definicao neste contexto |
|---|---|
| [Termo 1] | [Definicao precisa para este projeto] |
| [Termo 2] | [Definicao precisa para este projeto] |
```

---

## Exemplo de Uso

**Cenario:** Sistema de cotacao de planos de saude PME.

```markdown
# Especificacao Funcional: Motor de Cotacao PME

## 1. Visao Geral e Objetivo
- **O Problema:** Cotacoes PME sao calculadas manualmente, gerando erros e atrasos de ate 48h.
- **A Solucao:** Sistema automatizado que calcula o preco liquido considerando faixa etaria, produto e campanhas ativas.
- **O Valor:** Reducao do tempo de cotacao de 48h para menos de 1 segundo, eliminando erros manuais.

## 4. Casos de Borda (Zero Trust)
| Cenario | Comportamento Esperado | Severidade |
|---|---|---|
| CPF invalido | Rejeitar com erro de validacao | Critica |
| Nenhuma campanha ativa | Retornar desconto nulo, sem falhar a cotacao | Media |
| Tabela de precos indisponivel | Retornar erro 503 com retry-after header | Alta |
```
