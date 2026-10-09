# 03 - RAG, Grounding e Citations

## Quando usar

Use quando a resposta depender de base documental externa ou interna e precisar de verificabilidade por citacao.

## Pre-requisitos

- Corpus versionado e indexado.
- Regra de janela de contexto por consulta.
- Formato de citacao por secao/paragrafo.

## Boas praticas

1. **Separar retrieval de synthesis**  
   Quando usar: pipelines com busca + resposta final.  
   Trade-off: arquitetura mais complexa, menor risco de perda de contexto.
2. **Impor criterio de relevancia minimo para chunks**  
   Quando usar: bases extensas com ruido.  
   Trade-off: risco de recall menor, ganho de precisao.
3. **Exigir citacao verificavel para afirmacoes factuais**  
   Quando usar: respostas tecnico-regulatorias ou auditoria.  
   Trade-off: respostas mais longas, rastreabilidade maior.

## Anti-padroes

1. **Top-k fixo sem calibracao por tipo de pergunta**  
   Impacto: excesso de ruido ou contexto insuficiente.  
   Mitigacao: ajustar k por classe de consulta.
2. **Misturar evidencia de baixa confianca com oficial sem marcador**  
   Impacto: decisao editorial confusa.  
   Mitigacao: classificar confianca e priorizar fonte oficial.
3. **Responder sem apontar origem**  
   Impacto: baixa auditabilidade e risco de regressao.  
   Mitigacao: anexar fonte por bloco de recomendacao.

## Checklist

- [ ] Pipeline retrieval/synthesis documentado.
- [ ] Regra de citacao ativa para secao critica.
- [ ] Niveis de confianca definidos.
- [ ] Referencias mapeadas em `references.md`.

## Troubleshooting

| Sintoma | Causa provavel | Acao corretiva |
|---|---|---|
| Resposta ignora fonte relevante | Ranking fraco | Ajustar query rewriting e score threshold |
| Citacao incorreta | Mapeamento chunk->fonte quebrado | Persistir metadados de origem no indice |
| Hallucination com citacao inexistente | Prompt sem regra de abstencao | Adicionar "sem evidencia, nao afirmar" |

## Referencias

Ver `references.md` (modulo: rag-grounding-citations).
