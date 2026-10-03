# 05 - Avaliacao e PromptOps

## Quando usar

Use para medir qualidade de prompts em ciclo continuo, governar versoes e reduzir regressao de comportamento.

## Pre-requisitos

- Suite minima de evals (funcional, robustez, seguranca).
- Dataset de casos representativos por fluxo.
- Definicao de ownership e SLA de revisao.

## Boas praticas

1. **Versionar prompts como artefato de producao**  
   Quando usar: todos os fluxos criticos.  
   Trade-off: overhead de processo, rastreabilidade completa.
2. **Rodar evals por mudanca e por janela periodica**  
   Quando usar: alteracoes de modelo ou prompt.  
   Trade-off: custo operacional adicional, menor regressao.
3. **Registrar decisao de release por metrica e risco**  
   Quando usar: aprovar nova versao de prompt.  
   Trade-off: maior formalidade, melhor governanca.

## Anti-padroes

1. **Aprovar prompt por impressao subjetiva**  
   Impacto: drift de qualidade e discussoes sem base.  
   Mitigacao: exigir metrica comparativa e baseline.
2. **Nao registrar conflitos de evidencia**  
   Impacto: recomendacoes inconsistentes no tempo.  
   Mitigacao: registrar conflito, decisao e follow-up.
3. **Trocar modelo sem revalidar prompts criticos**  
   Impacto: regressao silenciosa de comportamento.  
   Mitigacao: gatilho automatico de regressao suite.

## Checklist

- [ ] Versionamento de prompt habilitado.
- [ ] Evals minimas definidas e executadas.
- [ ] Criterio de release documentado.
- [ ] Referencias mapeadas em `references.md`.

## Troubleshooting

| Sintoma | Causa provavel | Acao corretiva |
|---|---|---|
| Queda de qualidade apos deploy | Drift de modelo | Reexecutar baseline e ajustar prompt constraints |
| Resultado inconsistente por tenant | Dataset de eval pouco representativo | Expandir cenarios por segmento |
| Sem historico de decisao | Falta de changelog | Adotar template padrao de release |

## Referencias

Ver `references.md` (modulo: avaliacao-e-promptops).
