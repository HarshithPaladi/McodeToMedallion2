#!/usr/bin/env python3
"""
Extract every Power Query (M) query from a Power BI / Fabric semantic model,
one file per query, named after the query:  <OUT>/<QueryName>.m

Model-agnostic. Point it at any model, in either on-disk form:
  * TMDL  - a <Name>.SemanticModel/definition/ folder (PBIP, Fabric Git sync)
  * TMSL  - a model.bim / *.bim JSON file

Usage:
    python extract_mcode.py <model-path> [-o m_extract]

<model-path> may be the .SemanticModel folder, its definition/ folder, a .bim
file, or any folder that contains one of those.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

_EXPR = re.compile(r"^([ \t]*)expression[ \t]+('(?:[^']|'')*'|\"(?:[^\"\\]|\\.)*\"|[^\s=]+)[ \t]*=(.*)$")
_PART = re.compile(r"^([ \t]*)partition[ \t]+('(?:[^']|'')*'|\"(?:[^\"\\]|\\.)*\"|[^\s=]+)[ \t]*=[ \t]*(\w+)[ \t]*$")
_TABLE = re.compile(r"^[ \t]*table[ \t]+('(?:[^']|'')*'|\"(?:[^\"\\]|\\.)*\"|\S+)")
_SRC = re.compile(r"^([ \t]*)source[ \t]*(=?)[ \t]*(.*)$")
_BAD = re.compile(r'[\\/:*?"<>|\r\n\t]+')


def _indent(s: str) -> int:
    return len(s) - len(s.lstrip(" \t"))


def _unquote(tok: str) -> str:
    tok = tok.strip()
    if len(tok) >= 2 and tok[0] == tok[-1] == "'":
        return tok[1:-1].replace("''", "'")
    if len(tok) >= 2 and tok[0] == tok[-1] == '"':
        return tok[1:-1]
    return tok


def _dedent(block: list) -> str:
    widths = [_indent(l) for l in block if l.strip()]
    cut = min(widths) if widths else 0
    return "\n".join(l[cut:] if len(l) >= cut else l for l in block).strip("\n")


def _collect(lines: list, start: int, header_indent: int):
    """Collect an indented or ```-fenced value block beginning at lines[start]."""
    i, n = start, len(lines)
    while i < n and not lines[i].strip():
        i += 1
    if i >= n:
        return "", i
    if lines[i].strip().startswith("```"):
        buf, i = [], i + 1
        while i < n and lines[i].strip() != "```":
            buf.append(lines[i])
            i += 1
        return _dedent(buf), i + 1
    body_indent = _indent(lines[i])
    if body_indent <= header_indent:
        return "", i
    buf = []
    while i < n and (not lines[i].strip() or _indent(lines[i]) >= body_indent):
        buf.append(lines[i])
        i += 1
    return _dedent(buf), i


def from_tmdl(defn: Path) -> dict:
    out: dict = {}

    for fname in ("expressions.tmdl", "model.tmdl"):
        fp = defn / fname
        if not fp.exists():
            continue
        lines = fp.read_text(encoding="utf-8").split("\n")
        i, n = 0, len(lines)
        while i < n:
            m = _EXPR.match(lines[i])
            if not m:
                i += 1
                continue
            name, rest, hi = _unquote(m.group(2)), m.group(3).strip(), len(m.group(1))
            if rest.startswith("```"):
                body, consumed = _collect([rest] + lines[i + 1:], 0, hi)
                i += consumed
            elif rest:
                body = re.sub(r"\s+meta\s*\[[^\]]*\]\s*$", "", rest)
                i += 1
            else:
                body, i = _collect(lines, i + 1, hi)
            out[name] = body

    tdir = defn / "tables"
    if tdir.is_dir():
        for tf in sorted(tdir.glob("*.tmdl")):
            lines = tf.read_text(encoding="utf-8").split("\n")
            table = _unquote(_TABLE.match(lines[0]).group(1)) if lines and _TABLE.match(lines[0]) else tf.stem
            parts = [(k, pm) for k, ln in enumerate(lines) for pm in [_PART.match(ln)] if pm]
            m_parts = [(k, pm) for k, pm in parts if pm.group(3) == "m"]
            for k, pm in m_parts:
                pindent, pname = len(pm.group(1)), _unquote(pm.group(2))
                body = ""
                j = k + 1
                while j < len(lines):
                    if lines[j].strip() and _indent(lines[j]) <= pindent:
                        break
                    s = _SRC.match(lines[j])
                    if s:
                        si, val = len(s.group(1)), s.group(3).strip()
                        if s.group(2) == "=" and val and not val.startswith("```"):
                            body = val
                        else:
                            body, _ = _collect(lines, j + 1, si)
                        break
                    j += 1
                key = table if len(m_parts) == 1 else "{}.{}".format(table, pname)
                out[key] = body
    return out


def from_tmsl(bim: Path) -> dict:
    doc = json.loads(bim.read_text(encoding="utf-8"))
    model = doc.get("model")
    if model is None:
        for key in ("create", "createOrReplace", "database"):
            node = doc.get(key)
            if isinstance(node, dict):
                model = node.get("database", node).get("model")
                if model:
                    break
    model = model or doc

    def text(v):
        return "\n".join(map(str, v)) if isinstance(v, list) else ("" if v is None else str(v))

    out: dict = {}
    for e in model.get("expressions", []) or []:
        if e.get("kind", "m") == "m":
            out[e.get("name", "?")] = text(e.get("expression"))
    for t in model.get("tables", []) or []:
        tname = t.get("name", "?")
        mps = [p for p in (t.get("partitions", []) or []) if (p.get("source", {}) or {}).get("type", "m") == "m"]
        for p in mps:
            key = tname if len(mps) == 1 else "{}.{}".format(tname, p.get("name"))
            out[key] = text((p.get("source", {}) or {}).get("expression"))
    return out


def locate(path: Path):
    if path.is_file():
        return ("tmsl", path)
    if (path / "definition").is_dir():
        return ("tmdl", path / "definition")
    if path.name == "definition" and path.is_dir():
        return ("tmdl", path)
    for d in sorted(path.rglob("definition")):
        if d.is_dir() and any((d / f).exists() for f in ("model.tmdl", "database.tmdl")):
            return ("tmdl", d)
    bims = sorted(path.rglob("*.bim"))
    if bims:
        return ("tmsl", bims[0])
    return (None, None)


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("model", help="path to a semantic model (folder or .bim)")
    ap.add_argument("-o", "--out", default="m_extract", help="output directory (default: m_extract)")
    a = ap.parse_args(argv)

    kind, src = locate(Path(a.model))
    if not kind:
        print("no semantic model found under", a.model, file=sys.stderr)
        return 2

    queries = from_tmdl(src) if kind == "tmdl" else from_tmsl(src)
    queries = {k: v for k, v in queries.items() if v and v.strip()}
    if not queries:
        print("no M queries found in", src, file=sys.stderr)
        return 1

    out = Path(a.out)
    out.mkdir(parents=True, exist_ok=True)
    for name, code in sorted(queries.items()):
        fname = _BAD.sub("_", name).strip() or "_"
        (out / (fname + ".m")).write_text(code if code.endswith("\n") else code + "\n", encoding="utf-8")
        print(fname + ".m")
    print("\n{} quer{} -> {}/".format(len(queries), "y" if len(queries) == 1 else "ies", out))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
