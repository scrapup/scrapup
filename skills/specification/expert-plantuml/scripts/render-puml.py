#!/usr/bin/env python3
"""render-puml.py — conta elementos de um .puml, decide o PLANTUML_LIMIT_SIZE e renderiza o PNG.

Regras herdadas da skill expert-plantuml (SKILL.md):
  - Sempre renderizar com -DPLANTUML_LIMIT_SIZE (nunca sem); o limite padrao do PlantUML
    e 4096px e corta diagramas grandes silenciosamente.
  - Diagramas simples (< 30 elementos) -> 16384.
  - Diagramas muito grandes (> 100 elementos) -> 32768.
  - O codigo .puml e a fonte da verdade; o PNG e derivado.

Uso:
  render-puml.py <entrada.puml> [saida.png] [--limit N] [--check] [--quiet]

  <entrada.puml>  Caminho do arquivo PlantUML de entrada.
  [saida.png]     Caminho do PNG de saida (dir criado se necessario). Se omitido,
                  gera ao lado do .puml com o mesmo nome e extensao .png.
  --limit N       Forca o PLANTUML_LIMIT_SIZE (ignora a contagem de elementos).
  --check         Valida a sintaxe (plantuml -checkonly) antes de renderizar.
  --quiet         Suprime o relatorio de contagem; imprime apenas o caminho do PNG.

Saida (stdout): relatorio de contagem + caminho do PNG gerado.
Codigos de saida: 0 sucesso; 2 erro de uso/arquivo; 3 plantuml ausente; 4 falha de render.
"""

import argparse
import os
import re
import shutil
import subprocess
import sys

# Limiares de contagem -> PLANTUML_LIMIT_SIZE (px). Fonte: SKILL.md, secao "Limite de tamanho".
THRESHOLD_LARGE = 100   # > 100 elementos => diagrama muito grande
LIMIT_DEFAULT = 16384   # diagramas simples / medios
LIMIT_LARGE = 32768     # diagramas muito grandes

# Palavras-chave que declaram um elemento estrutural (UML + C4-PlantUML).
# Casadas no inicio da linha (apos indentacao), seguidas de delimitador.
DECL_KEYWORDS = [
    # UML estrutural / nós
    "participant", "actor", "boundary", "control", "entity", "collections",
    "queue", "database", "class", "interface", "enum", "abstract", "annotation",
    "object", "component", "node", "cloud", "frame", "folder", "rectangle",
    "package", "namespace", "artifact", "card", "usecase", "state", "agent",
    "stack", "storage", "person", "hexagon", "circle", "file",
    # C4-PlantUML (macros como chamadas: Person(...), Container(...), etc.)
    "Person", "Person_Ext", "System", "System_Ext", "SystemDb", "SystemDb_Ext",
    "SystemQueue", "SystemQueue_Ext", "Container", "ContainerDb", "ContainerQueue",
    "Container_Ext", "ContainerDb_Ext", "Component", "ComponentDb", "ComponentQueue",
    "Component_Ext", "Boundary", "Enterprise_Boundary", "System_Boundary",
    "Container_Boundary", "Node", "Deployment_Node",
]

# Macros de relacionamento C4 (contam como elemento/aresta).
REL_MACROS = [
    "Rel", "Rel_Up", "Rel_Down", "Rel_Left", "Rel_Right",
    "Rel_U", "Rel_D", "Rel_L", "Rel_R",
    "Rel_Back", "Rel_Neighbor", "Rel_Back_Neighbor", "BiRel",
    "BiRel_Up", "BiRel_Down", "BiRel_Left", "BiRel_Right",
]

# Setas/links UML (sequence, classe, componente, estado, atividade).
ARROW_RE = re.compile(r"(<\|--|--\|>|\*--|o--|\.\.>|<\.\.|-->|<--|\.\.|->|<-|==>|<==)")

# Blocos de controle (sequence/activity) que adicionam complexidade visual.
BLOCK_RE = re.compile(r"^\s*(alt|opt|loop|par|break|critical|group|ref|box|if|else|elseif|fork|split|repeat|while|partition|rectangle)\b", re.IGNORECASE)

DECL_RE = re.compile(
    r"^\s*(?:" + "|".join(re.escape(k) for k in DECL_KEYWORDS) + r")\b"
)
REL_RE = re.compile(
    r"^\s*(?:" + "|".join(re.escape(k) for k in REL_MACROS) + r")\s*\("
)
ACTIVITY_RE = re.compile(r"^\s*:.*[;|]\s*$")  # :acao; em diagramas de atividade


def strip_noise(text):
    """Remove comentarios e diretivas que nao sao elementos de diagrama."""
    out = []
    in_block_comment = False
    for raw in text.splitlines():
        line = raw
        if in_block_comment:
            if "'/" in line or line.strip().endswith("'/"):
                in_block_comment = False
            continue
        s = line.strip()
        if s.startswith("/'"):
            if "'/" not in s:
                in_block_comment = True
            continue
        if s.startswith("'"):          # comentario de linha
            continue
        if s.startswith("!") or s.startswith("@"):  # diretivas/preprocessor e @start/@end
            continue
        if not s:
            continue
        out.append(line)
    return out


def count_elements(text):
    """Conta elementos do diagrama e devolve (total, breakdown)."""
    lines = strip_noise(text)
    counts = {"declaracoes": 0, "relacoes_c4": 0, "setas": 0, "blocos": 0, "atividades": 0}
    for line in lines:
        if DECL_RE.match(line):
            counts["declaracoes"] += 1
        elif REL_RE.match(line):
            counts["relacoes_c4"] += 1
        elif ACTIVITY_RE.match(line):
            counts["atividades"] += 1
        elif ARROW_RE.search(line):
            counts["setas"] += 1
        elif BLOCK_RE.match(line):
            counts["blocos"] += 1
    total = sum(counts.values())
    return total, counts


def decide_limit(total):
    return LIMIT_LARGE if total > THRESHOLD_LARGE else LIMIT_DEFAULT


def run_plantuml(args, stdin_data=None, stdout_file=None):
    kwargs = {"stderr": subprocess.PIPE}
    if stdin_data is not None:
        kwargs["stdin"] = subprocess.PIPE
    if stdout_file is not None:
        kwargs["stdout"] = stdout_file
    proc = subprocess.Popen(["plantuml", *args], **kwargs)
    _, err = proc.communicate(input=stdin_data)
    return proc.returncode, (err.decode("utf-8", "replace") if err else "")


def main():
    parser = argparse.ArgumentParser(add_help=True, description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("input", help="caminho do .puml de entrada")
    parser.add_argument("output", nargs="?", default=None,
                        help="caminho do .png de saida (default: mesmo nome/pasta do .puml com .png)")
    parser.add_argument("--limit", type=int, default=None, help="forca o PLANTUML_LIMIT_SIZE")
    parser.add_argument("--check", action="store_true", help="valida sintaxe antes de renderizar")
    parser.add_argument("--quiet", action="store_true", help="imprime apenas o caminho do PNG")
    a = parser.parse_args()

    def err(msg, code):
        print(f"erro: {msg}", file=sys.stderr)
        sys.exit(code)

    if not shutil.which("plantuml"):
        err("CLI 'plantuml' nao encontrado no PATH.", 3)
    if not os.path.isfile(a.input):
        err(f"arquivo de entrada nao existe: {a.input}", 2)

    if a.output is None:
        a.output = os.path.splitext(a.input)[0] + ".png"

    with open(a.input, "r", encoding="utf-8", errors="replace") as f:
        source = f.read()

    total, counts = count_elements(source)
    limit = a.limit if a.limit is not None else decide_limit(total)

    out_dir = os.path.dirname(os.path.abspath(a.output))
    os.makedirs(out_dir, exist_ok=True)

    if a.check:
        rc, cerr = run_plantuml(["-checkonly", a.input])
        if rc != 0:
            err(f"sintaxe invalida (plantuml -checkonly):\n{cerr.strip()}", 4)

    # Render via -pipe: controla o caminho exato do PNG (stdout -> arquivo).
    render_args = [f"-DPLANTUML_LIMIT_SIZE={limit}", "-tpng", "-pipe"]
    with open(a.output, "wb") as out_fh:
        rc, rerr = run_plantuml(render_args, stdin_data=source.encode("utf-8"), stdout_file=out_fh)

    if rc != 0 or not os.path.isfile(a.output) or os.path.getsize(a.output) == 0:
        if os.path.isfile(a.output) and os.path.getsize(a.output) == 0:
            os.remove(a.output)
        err(f"falha ao renderizar (rc={rc}):\n{rerr.strip()}", 4)

    if a.quiet:
        print(os.path.abspath(a.output))
        return

    origem = "forcado (--limit)" if a.limit is not None else (
        "diagrama muito grande (>100)" if total > THRESHOLD_LARGE else "diagrama simples/medio (<=100)")
    print("== Contagem de elementos ==")
    print(f"  declaracoes (nos/atores/classes/C4): {counts['declaracoes']}")
    print(f"  relacoes C4 (Rel/BiRel):             {counts['relacoes_c4']}")
    print(f"  setas/links UML:                     {counts['setas']}")
    print(f"  blocos de controle:                  {counts['blocos']}")
    print(f"  acoes de atividade:                  {counts['atividades']}")
    print(f"  TOTAL:                               {total}")
    print(f"== PLANTUML_LIMIT_SIZE = {limit}  ({origem}) ==")
    print(f"PNG gerado: {os.path.abspath(a.output)}")
    if rerr.strip():
        print(f"[plantuml stderr]\n{rerr.strip()}", file=sys.stderr)


if __name__ == "__main__":
    main()
