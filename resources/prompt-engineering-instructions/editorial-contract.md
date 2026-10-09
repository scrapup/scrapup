# Contrato Editorial por Modulo

## Regras obrigatorias

1. Titulo do modulo com objetivo mensuravel e escopo explicito.
2. Minimo de 3 boas praticas por modulo, cada uma com:
   - quando usar,
   - trade-off,
   - risco de uso incorreto.
3. Minimo de 3 anti-padroes por modulo, cada um com:
   - impacto,
   - mitigacao objetiva,
   - verificacao.
4. Checklist operacional objetivo (itens verificaveis).
5. Secao de troubleshooting com sintomas e acao corretiva.
6. Referencias rastreaveis por secao em `references.md`.

## Padrao de linguagem

- Foco em acoes observaveis e criterio de decisao.
- Evitar recomendacao generica sem contexto de uso.
- Usar termos consistentes entre modulos.

## Padrao de exemplos

- Incluir pelo menos 1 exemplo positivo e 1 contraexemplo quando aplicavel.
- Exemplo deve declarar contexto minimo, restricoes e resultado esperado.

## Validacao de consistencia terminologica

| Termo canonico | Variacoes aceitas | Observacao |
|---|---|---|
| Prompt Engineering | prompt engineering | manter conceito como pratica de instrucoes |
| Context Engineering | context engineering | usar para abordagem sistemica alem do prompt |
| Tool use | tool-use, function calling | preferir "tool use" em texto corrido |
| Quality gate | gate de qualidade | usar termo em ingles no cabecalho e PT no corpo |
