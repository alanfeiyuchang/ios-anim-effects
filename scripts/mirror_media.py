#!/usr/bin/env python3
"""Downloads the effect recordings already published on the docs site, so the site can be rebuilt
(new web demos, new page code) without re-recording every effect in the simulator.

Usage: scripts/mirror_media.py catalog.json media/ [base-url]
Fetches media/<id>.<lang>.mp4 and .jpg for every effect in the catalog (missing files are skipped;
the page falls back to posters or placeholders).
"""
import concurrent.futures
import json
import os
import sys
import urllib.error
import urllib.request

BASE = "https://alanfeiyuchang.github.io/motionary-ios-animations/media"


def fetch(url, path):
    if os.path.exists(path) and os.path.getsize(path) > 0:
        return "cached"
    try:
        with urllib.request.urlopen(url, timeout=60) as response:
            data = response.read()
    except urllib.error.HTTPError as error:
        return f"missing ({error.code})"
    except (urllib.error.URLError, TimeoutError) as error:
        return f"failed ({error})"
    with open(path, "wb") as f:
        f.write(data)
    return "ok"


def main():
    if len(sys.argv) not in (3, 4):
        print(__doc__)
        sys.exit(2)
    catalog_path, media_dir = sys.argv[1:3]
    base = sys.argv[3] if len(sys.argv) == 4 else BASE
    with open(catalog_path, encoding="utf-8") as f:
        catalog = json.load(f)
    os.makedirs(media_dir, exist_ok=True)
    jobs = []
    for effect in catalog["effects"]:
        for lang in ("zh", "en"):
            for ext in (".mp4", ".jpg"):
                name = f"{effect['id']}.{lang}{ext}"
                jobs.append((f"{base}/{name}", os.path.join(media_dir, name)))
    counts = {}
    with concurrent.futures.ThreadPoolExecutor(max_workers=16) as pool:
        for status in pool.map(lambda job: fetch(*job), jobs):
            key = status.split(" ")[0]
            counts[key] = counts.get(key, 0) + 1
    print(f"Media mirror: {len(jobs)} files — " + ", ".join(f"{k} {v}" for k, v in sorted(counts.items())))


if __name__ == "__main__":
    main()
