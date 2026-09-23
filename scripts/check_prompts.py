#!/usr/bin/env python3
"""Checks every effect prompt against the length budget in docs/EFFECT_GUIDE.md.

English: 70–150 words. Chinese: 110–240 characters, counting every non-whitespace character.
Usage: python3 scripts/check_prompts.py [path-filter]   (exit code 1 when anything is out of budget)
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
PROMPT_RE = re.compile(r'prompt:\s*L\(\s*"((?:[^"\\]|\\.)*)"\s*,\s*"((?:[^"\\]|\\.)*)"\s*\)', re.S)
ID_RE = re.compile(r'id:\s*"([a-z]+\.[a-z0-9-]+)"')


def main():
    only = sys.argv[1] if len(sys.argv) > 1 else ""
    bad = 0
    total = 0
    for path in sorted((ROOT / "MotionLab" / "Effects").rglob("*.swift")):
        if only and only not in str(path):
            continue
        text = path.read_text()
        for match in PROMPT_RE.finditer(text):
            total += 1
            ids = ID_RE.findall(text[: match.start()])
            effect_id = ids[-1] if ids else "?"
            en_words = len(match.group(1).split())
            zh_chars = len(re.sub(r"\s", "", match.group(2)))
            if not 70 <= en_words <= 150 or not 110 <= zh_chars <= 240:
                bad += 1
                print(f"{effect_id}: en {en_words} words, zh {zh_chars} chars  ({path.relative_to(ROOT)})")
    print(f"{total} prompts checked, {bad} out of budget")
    sys.exit(1 if bad else 0)


if __name__ == "__main__":
    main()
