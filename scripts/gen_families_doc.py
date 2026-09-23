#!/usr/bin/env python3
"""Regenerates the per-family tables in docs/FAMILIES.md from MotionLab/Families/*Families.swift.

Usage: python3 scripts/gen_families_doc.py
Rewrites each category section's "File: …" line counts and table, and the catalog totals line.
Variations are listed in membership order.
"""
import re
import pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
DOC = ROOT / "docs" / "FAMILIES.md"
FAMILY_RE = re.compile(
    r'EffectFamily\(\s*id:\s*"([^"]+)",\s*category:\s*\.\w+,\s*name:\s*L\("((?:[^"\\]|\\.)*)",\s*"((?:[^"\\]|\\.)*)"\)',
    re.S,
)
MEMBER_RE = re.compile(r'^\s*"([a-z]+\.[a-z0-9-]+)":\s*"([a-z]+\.[a-z0-9-]+)",', re.M)


def load(path):
    text = path.read_text()
    families = [(m[0], m[1], m[2]) for m in FAMILY_RE.findall(text)]
    members = {}
    for effect, family in MEMBER_RE.findall(text):
        members.setdefault(family, []).append(effect)
    return families, members


def table(families, members):
    rows = ["| Family id | Name · 名称 | Count | Variations (effect ids) |", "|---|---|---:|---|"]
    for fid, en, zh in families:
        ids = members.get(fid, [])
        rows.append(f"| `{fid}` | {en} · {zh} | {len(ids)} | " + ", ".join(f"`{i}`" for i in ids) + " |")
    return rows


def main():
    lines = DOC.read_text().split("\n")
    out, i = [], 0
    total_effects = total_families = 0
    while i < len(lines):
        line = lines[i]
        m = re.match(r"File: `MotionLab/Families/(\w+Families)\.swift`(.*?)· \d+ families · \d+ effects$", line)
        if not m:
            out.append(line)
            i += 1
            continue
        families, members = load(ROOT / "MotionLab" / "Families" / f"{m.group(1)}.swift")
        count = sum(len(members.get(f[0], [])) for f in families)
        total_effects += count
        total_families += len(families)
        out.append(f"File: `MotionLab/Families/{m.group(1)}.swift`{m.group(2)}· {len(families)} families · {count} effects")
        i += 1
        while i < len(lines) and not lines[i].startswith("|"):
            out.append(lines[i])
            i += 1
        while i < len(lines) and lines[i].startswith("|"):
            i += 1
        out.extend(table(families, members))
    text = "\n".join(out)
    text = re.sub(
        r"Current catalog: \*\*\d+ effects\*\* in \*\*\d+ families\*\*",
        f"Current catalog: **{total_effects} effects** in **{total_families} families**",
        text,
    )
    DOC.write_text(text)
    print(f"{total_effects} effects, {total_families} families")


if __name__ == "__main__":
    main()
