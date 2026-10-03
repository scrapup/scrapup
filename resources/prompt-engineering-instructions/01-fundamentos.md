# 01 - Fundamentos

## Quando usar

Use este modulo para estabelecer baseline de qualidade antes de criar prompts de producao, playbooks de operacao, ou rotinas de avaliacao.

## Pre-requisitos

- Objetivo da tarefa definido em uma frase mensuravel.
- Perfil de entrada/saida conhecido (formato, limites e criterio de aceite).
- Contexto minimo disponivel (fonte de verdade, constraints, regras de negocio).

## Boas praticas

1. **Definir contrato de saida antes do texto do prompt**  
   Quando usar: sempre que a resposta puder ser validada automaticamente.  
   Trade-off: maior esforco inicial de especificacao, menor retrabalho posterior.
2. **Separar instrucoes estaveis de contexto variavel**  
   Quando usar: fluxos repetitivos com dados diferentes por request.  
   Trade-off: exige disciplina de versionamento de templates.
3. **Explicitar criterio de "done" no proprio prompt**  
   Quando usar: tarefas analiticas (classificacao, resumo, extracao).  
   Trade-off: prompts mais longos, respostas mais consistentes.

## Anti-padroes

1. **Objetivo vago ("faça o melhor possivel")**  
   Impacto: saida inconsistente entre execucoes.  
   Mitigacao: transformar objetivo em condicoes observaveis de sucesso.
2. **Misturar regra de negocio com exemplo contraditorio**  
   Impacto: o modelo prioriza exemplos errados e ignora regra principal.  
   Mitigacao: manter exemplos alinhados ao contrato final.
3. **Prompt monolitico sem secoes**  
   Impacto: manutencao cara e baixa legibilidade.  
   Mitigacao: usar secoes fixas (objetivo, contexto, regras, saida, criterios).

## Checklist

- [ ] Objetivo mensuravel definido.
- [ ] Contrato de saida definido.
- [ ] Criterios de aceite incluidos no prompt.
- [ ] Referencias mapeadas em `references.md`.

## Troubleshooting

| Sintoma | Causa provavel | Acao corretiva |
|---|---|---|
| Respostas mudam muito entre execucoes | Prompt sem criterio de aceite explicito | Adicionar checks de consistencia e exemplo positivo/negativo |
| Saida incompleta | Contexto insuficiente ou ambiguo | Incluir fonte de verdade e limites do escopo |
| Hallucination de fatos | Falta de grounding | Inserir regra de citacao e fallback de incerteza |

## Referencias

Ver `references.md` (modulo: fundamentos).
