# scrapup

🌐 [English](./README.md) | [日本語](./README.ja.md) | **Português**

> Do *scrap* informacional à entrega forjada — software construído por um **Unified Process assistido por IA**.

**scrapup** é um ecossistema de *skills*, *agents* e *commands* para o [Claude Code](https://claude.com/claude-code) que operacionaliza o ciclo **documentar → validar → entregar** com rigor de engenharia. O nome carrega a tese do projeto: elevar (*up*) matéria-prima (*scrap*) até software entregue, por meio de um **Unified Process (UP)** modernizado e assistido por agentes — em que o desenvolvedor deixa de ser **executor** para ser **arquiteto e validador**, enquanto os agentes conduzem os fluxos de engenharia.

## Por que existe

O trabalho conduzido por IA tende a produzir resultados rápidos e frágeis. O scrapup impõe um contrato ao longo do caminho:

- **Contrato rastreável (SDD):** toda feature deriva de uma spec versionada, não de um prompt solto.
- **Validação multi-lente:** revisão por múltiplas perspectivas (qualidade, segurança, arquitetura, observabilidade…) antes de concluir.
- **Entrega com evidência:** nada é "feito" sem verificação observável.
- **Ferramental aberto:** integração com o ecossistema aberto, sem stack proprietário fechado.

## Abordagem

O scrapup mantém os **pilares do Unified Process** como uma constituição imutável e moderniza apenas *quem* faz o trabalho:

- **Os pilares permanecem** — orientado a casos de uso, centrado na arquitetura, iterativo e incremental, orientado a risco.
- **Os agentes conduzem os fluxos de engenharia** — Requirements → Analysis → Design → Implementation → Test.
- **O humano mantém dois papéis** — **Architect** (dono da arquitetura e do baseline executável) e **Validator** (adjudica a revisão multi-lente e sela cada marco de fase: LCO → LCA → IOC → Product Release).

Como a execução se torna barata e automatizada, a alavancagem migra para os **pontos de controle** — arquitetura, marcos e ordenação por risco — exatamente onde o arquiteto/validador atua.

## Status

**Beta — primeiro release público.** O scrapup está configurado como um plugin instalável do Claude Code; o ecossistema está sendo consolidado aqui a partir de trabalho anterior, e o catálogo de artefatos cresce de forma incremental. Publicado até agora: a skill `communication` (`skills/foundations/communication`) — a doutrina de registro e forma de toda saída para cada stakeholder do Unified Process.

## Instalação

> Requer o [Claude Code](https://claude.com/claude-code).

```bash
/plugin marketplace add scrapup/scrapup
/plugin install scrapup
# Reinicie a sessão para descobrir skills, agents, commands e MCP servers
```

Desenvolvimento local:

```bash
git clone git@github.com:scrapup/scrapup.git
claude --plugin-dir ./scrapup
```

## Licença

[MIT](LICENSE) © 2026 scrapup

## Autor

Marco Antonio Luqueti Faustino.
