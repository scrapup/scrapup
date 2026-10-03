# 02 - Structured Outputs e Tool Use

## Quando usar

Use em fluxos que exigem output tipado (JSON/schema) e interacao com ferramentas externas (APIs, DB, MCP).

## Pre-requisitos

- Schema de output definido com campos obrigatorios e validacoes.
- Politica de retry/timeouts para chamadas de ferramenta.
- Mapeamento de erros esperado por tipo de falha.

## Boas praticas

1. **Schema-first para output estruturado**  
   Quando usar: qualquer fluxo com automacao downstream.  
   Trade-off: restricao maior do modelo, mas reduz parsing fragil.
2. **Separar decisao de "chamar ferramenta" do payload final**  
   Quando usar: tool-use com multiplas etapas.  
   Trade-off: mais etapas de orquestracao, menos chamadas incorretas.
3. **Validar output no boundary e aplicar repair loop curto**  
   Quando usar: respostas com risco de quebra de contrato.  
   Trade-off: aumento de latencia, melhoria de confiabilidade.

## Anti-padroes

1. **Aceitar JSON parcial sem validacao**  
   Impacto: erro silencioso em producao.  
   Mitigacao: rejeitar payload invalido e pedir regeneracao estruturada.
2. **Tool selection sem politica explicita**  
   Impacto: chamadas redundantes e custo elevado.  
   Mitigacao: definir criterio de elegibilidade por ferramenta.
3. **Repassar erro bruto da ferramenta para o utilizador**  
   Impacto: baixa UX e vazamento de detalhe interno.  
   Mitigacao: mapear erro tecnico para erro de dominio.

## Checklist

- [ ] Schema de output publicado e validado.
- [ ] Politica de tool selection definida.
- [ ] Error mapping implementado.
- [ ] Referencias mapeadas em `references.md`.

## Troubleshooting

| Sintoma | Causa provavel | Acao corretiva |
|---|---|---|
| Campo faltando no JSON | Schema permissivo ou ausente | Tornar campo obrigatorio e validar no boundary |
| Tool loop infinito | Critico de parada nao definido | Limitar tentativas e registrar estado da iteracao |
| Custo elevado de tokens | Prompts com instrucoes duplicadas | Extrair instrucoes estaveis para system template |

## Referencias

Ver `references.md` (modulo: structured-outputs-e-tool-use).
