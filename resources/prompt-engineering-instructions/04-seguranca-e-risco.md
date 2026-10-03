# 04 - Seguranca e Risco

## Quando usar

Use em qualquer fluxo com entrada externa, acesso a ferramentas, manipulacao de dados sensiveis ou operacoes com impacto.

## Pre-requisitos

- Politica de dados sensiveis definida (PII, secrets, regulatorio).
- Lista de ameacas prioritarias (prompt injection, jailbreak, exfiltracao).
- Camadas de defesa definidas (input, contexto, tool permissions, output).

## Boas praticas

1. **Aplicar validacao defensiva em todas as entradas**  
   Quando usar: sempre.  
   Trade-off: maior custo de implementacao, risco menor de abuso.
2. **Isolar permissao de ferramentas por capacidade minima**  
   Quando usar: agentes com tool-use.  
   Trade-off: configuracao mais trabalhosa, menor superficie de ataque.
3. **Bloquear output com sinais de vazamento**  
   Quando usar: respostas com dados de cliente ou secretos.  
   Trade-off: possivel falso positivo, reducao de incidente critico.

## Anti-padroes

1. **Confiar em instrucoes recebidas no proprio prompt de utilizador**  
   Impacto: prompt injection e execucao indevida.  
   Mitigacao: separar policy de sistema e ignorar override nao autorizado.
2. **Permitir ferramenta de alto impacto sem guardrails**  
   Impacto: alteracao indevida de estado externo.  
   Mitigacao: exigir confirmacao explicita e policy por acao.
3. **Registrar segredo em logs/traces**  
   Impacto: vazamento de dados sensiveis.  
   Mitigacao: masking e redaction obrigatorios.

## Checklist

- [ ] Ameacas priorizadas por severidade.
- [ ] Guardrails por ferramenta definidos.
- [ ] Politica de redaction aplicada.
- [ ] Referencias mapeadas em `references.md`.

## Troubleshooting

| Sintoma | Causa provavel | Acao corretiva |
|---|---|---|
| Modelo executa acao sem autorizacao | Falta de policy de autorizacao | Implementar allowlist de acao e step-up confirmation |
| Saida inclui token/chave | Falha de sanitizacao | Adicionar detector de segredo e bloquear resposta |
| Prompt ignora regra de seguranca | Hierarquia de instrucoes ambigua | Fixar policy inegociavel no system layer |

## Referencias

Ver `references.md` (modulo: seguranca-e-risco).
