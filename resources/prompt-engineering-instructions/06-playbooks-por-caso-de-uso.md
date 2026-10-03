# 06 - Playbooks por Caso de Uso

## Quando usar

Use este modulo para transformar principios em execucao pratica por cenario recorrente.

## Pre-requisitos

- Modulos 01 a 05 revisados.
- Objetivo do caso de uso e KPI definidos.
- Ferramentas permitidas para o caso de uso.

## Boas praticas

1. **Definir playbook com entradas, passos e saida esperada**  
   Quando usar: fluxos operacionais recorrentes.  
   Trade-off: menos flexibilidade ad-hoc, maior previsibilidade.
2. **Incluir criterio de fallback e escalation por playbook**  
   Quando usar: operacoes com impacto externo.  
   Trade-off: maior disciplina de execucao, menos incidentes.
3. **Testar playbook com cenarios limite**  
   Quando usar: antes de publicar para o time.  
   Trade-off: custo de teste, reducao de surpresa em producao.

## Anti-padroes

1. **Playbook generico sem contexto de dominio**  
   Impacto: baixa aplicabilidade real.  
   Mitigacao: incluir exemplos concretos e constraints por dominio.
2. **Nao explicitar limite de autonomia do agente**  
   Impacto: acao indevida sem confirmacao humana.  
   Mitigacao: definir "must ask" e "must not do" por fluxo.
3. **Nao mapear risco operacional por etapa**  
   Impacto: falha de mitigacao em pontos criticos.  
   Mitigacao: anexar risco e controle por passo.

## Checklist

- [ ] Playbooks possuem input, processo e output.
- [ ] Limites de autonomia definidos.
- [ ] Fallback/escalation definidos.
- [ ] Referencias mapeadas em `references.md`.

## Troubleshooting

| Sintoma | Causa provavel | Acao corretiva |
|---|---|---|
| Time nao segue o playbook | Playbook longo e ambiguo | Reduzir para passos objetivos e checklists curtos |
| Alta taxa de excecao manual | Entrada mal padronizada | Adicionar normalizacao de input no inicio |
| Falhas repetidas no mesmo passo | Controle insuficiente | Inserir validacao adicional e alerta precoce |

## Referencias

Ver `references.md` (modulo: playbooks-por-caso-de-uso).
