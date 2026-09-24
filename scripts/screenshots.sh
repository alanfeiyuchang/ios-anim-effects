#!/usr/bin/env bash
# Builds the app, boots an iPhone simulator and captures a representative set of screenshots.
#
# The shot list is derived from the live catalog (the app exports catalog.json with -ML_exportCatalog),
# so it can never go stale:
#   home/      Browse, Search, Favorites, Settings, All Families (zh light + en dark)
#   category/  every category page (zh light), a few in en dark, one in "All Effects" mode
#   family/    every family page (zh light), a few in Compare mode (zh light + en dark)
#   effect/    the first variation of every family (zh light), one effect per category in en dark,
#              and a few prompt cards (en dark)
# EFFECTS=all also captures every effect's detail page (long: ~45 min more).
#
# Every launch passes -ML_freshState YES, so recents from earlier shots never show up (a recent
# preview of a demo that owns a NavigationStack used to break every later route: blank pages with
# SwiftUI's yellow "missing destination" warning). Shots that still come out blank (tiny JPEG) or
# identical to the previous one are retried once with a longer wait.
#
# SHOTS_FILTER=<regex> keeps only shots whose name matches (e.g. "^effect/" for a quick detail-page run).
# Shots that stay blank after the retry get a 3 s `sample` of the app's main thread in <out>/diag/
# (first 6 only), so a hang shows its stack instead of a white page.
#
# Usage: [EFFECTS=all] [SHOTS_FILTER=regex] scripts/screenshots.sh [output-dir]
set -euo pipefail
OUT="${1:-screenshots}"
BUNDLE_ID="com.motionlexicon.MotionLab"
MODE="${EFFECTS:-sample}"
mkdir -p "$OUT"

UDID=$(xcrun simctl list devices available -j | python3 -c '
import json,sys
d=json.load(sys.stdin)["devices"]
c=[x for rt,xs in d.items() if "iOS" in rt for x in xs if x["name"].startswith("iPhone") and "Pro" in x["name"] and "Max" not in x["name"]]
c=c or [x for rt,xs in d.items() if "iOS" in rt for x in xs if x["name"].startswith("iPhone")]
print(c[-1]["udid"])')
echo "Simulator: $UDID"
xcrun simctl boot "$UDID" || true
xcrun simctl bootstatus "$UDID" -b
xcrun simctl status_bar "$UDID" override --time "9:41" --batteryState charged --batteryLevel 100 --cellularBars 4 --wifiBars 3 || true

xcodebuild -project MotionLab.xcodeproj -scheme MotionLab -sdk iphonesimulator \
  -destination "id=$UDID" -derivedDataPath build CODE_SIGNING_ALLOWED=NO build > build.log 2>&1 \
  || { grep -E "error:" build.log | sort -u; exit 1; }
xcrun simctl uninstall "$UDID" "$BUNDLE_ID" >/dev/null 2>&1 || true
xcrun simctl install "$UDID" build/Build/Products/Debug-iphonesimulator/MotionLab.app

# Warm-up launch that also exports the catalog and audits every still thumbnail (-ML_auditStills). The wait
# lets first-boot system banners (e.g. "Ready for Apple Intelligence") appear and expire before any screenshot.
xcrun simctl launch "$UDID" "$BUNDLE_ID" -ML_exportCatalog YES -ML_auditStills YES -ML_noIntro YES -ML_freshState YES >/dev/null || true
sleep 45
CATALOG="$(xcrun simctl get_app_container "$UDID" "$BUNDLE_ID" data)/Documents/catalog.json"
if [[ ! -s "$CATALOG" ]]; then
  echo "error: the app did not export catalog.json; cannot derive the screenshot list" >&2
  exit 1
fi
cp "$CATALOG" "$OUT/catalog.json"

# Still audit: Data & Charts thumbnails that render as empty axes (e.g. a demo that zeroes its seeded data in
# onAppear, which ImageRenderer runs) are listed as warnings. STRICT_STILLS=1 turns them into a failure.
STILLS="$(dirname "$CATALOG")/still-audit.json"
for _ in $(seq 1 60); do [[ -s "$STILLS" ]] && break; sleep 2; done
if [[ -s "$STILLS" ]]; then
  cp "$STILLS" "$OUT/still-audit.json"
  FLAGGED=$(python3 -c 'import json,sys; f=json.load(open(sys.argv[1]))["flagged"]; print("\n".join(f))' "$STILLS")
  if [[ -n "$FLAGGED" ]]; then
    echo "warning: chart stills that look empty (ink below threshold):" >&2
    echo "$FLAGGED" | sed 's/^/  /' >&2
    [[ "${STRICT_STILLS:-0}" == "1" ]] && exit 1
  else
    echo "Still audit: every chart still shows data."
  fi
else
  echo "warning: the app did not write still-audit.json; still audit skipped" >&2
fi

# Shot plan: one line per shot, "<name>\t<wait seconds>\t<launch arguments>".
PLAN="$OUT/plan.tsv"
python3 - "$CATALOG" "$MODE" > "$PLAN" <<'PY'
import json, sys

catalog = json.load(open(sys.argv[1]))
mode = sys.argv[2]
ZH = "-app.language zh -app.appearance 1"
EN = "-app.language en -app.appearance 2"

categories = [c["id"] for c in catalog["categories"]]
families = catalog["families"]
effects = catalog["effects"]
members = {}
for effect in effects:
    members.setdefault(effect["family"], []).append(effect["id"])
by_category = {}
for family in families:
    if members.get(family["id"]):
        by_category.setdefault(family["category"], []).append(family["id"])

def shot(name, wait, args):
    print(f"{name}\t{wait}\t{args}")

def effect_wait(effect_id):
    # The first Metal shader compile is slow.
    return 6 if effect_id.startswith("shader.") else 5

# Home screens
shot("home/browse-zh-light", 4, ZH)
shot("home/browse-en-dark", 4, EN)
shot("home/search-zh-light", 3, f"{ZH} -ML_tab 1")
shot("home/search-en-dark", 3, f"{EN} -ML_tab 1")
shot("home/favorites-zh-light", 3, f"{ZH} -ML_tab 2")
shot("home/settings-zh-light", 3, f"{ZH} -ML_tab 3")
shot("home/settings-en-dark", 3, f"{EN} -ML_tab 3")
shot("home/all-families-zh-light", 5, f"{ZH} -ML_route families")
shot("home/all-families-en-dark", 5, f"{EN} -ML_route families")

# Categories: every one in zh light (families mode), every third in en dark, one in "All Effects" mode.
for index, category in enumerate(categories):
    shot(f"category/{category}", 5, f"{ZH} -app.categoryMode families -ML_route category:{category}")
    if index % 3 == 0:
        shot(f"category/{category}--en-dark", 5, f"{EN} -app.categoryMode families -ML_route category:{category}")
if categories:
    shot(f"category/{categories[1 if len(categories) > 1 else 0]}--all-effects", 5,
         f"{ZH} -app.categoryMode all -ML_route category:{categories[1 if len(categories) > 1 else 0]}")

# Families: every one in grid mode; the first multi-variation family of every third category in Compare mode.
for family in families:
    if members.get(family["id"]):
        shot(f"family/{family['id']}", 4, f"{ZH} -app.familyMode grid -ML_route family:{family['id']}")
for index, category in enumerate(categories):
    if index % 3 != 0:
        continue
    multi = [f for f in by_category.get(category, []) if len(members[f]) > 2]
    if multi:
        fid = multi[0]
        shot(f"family/{fid}--compare", 5, f"{ZH} -app.familyMode compare -ML_route family:{fid}")
        shot(f"family/{fid}--compare-en-dark", 5, f"{EN} -app.familyMode compare -ML_route family:{fid}")

# Effects
if mode == "all":
    picked = [e["id"] for e in effects]
else:
    picked = [members[f["id"]][0] for f in families if members.get(f["id"])]
for effect_id in picked:
    shot(f"effect/{effect_id}", effect_wait(effect_id), f"{ZH} -ML_route effect:{effect_id}")
for category in categories:
    ids = [e["id"] for e in effects if e["category"] == category]
    if ids:
        last = ids[-1]
        shot(f"effect/{last}--en-dark", effect_wait(last), f"{EN} -ML_route effect:{last}")
for category in categories[:3]:
    ids = [e["id"] for e in effects if e["category"] == category]
    if ids:
        # The page jumps to the prompt card ~1.3 s after launch, then the card reveals itself.
        shot(f"effect/{ids[0]}--prompt-en-dark", 5, f"{EN} -ML_route effect:{ids[0]} -ML_anchor prompt")
PY
if [[ -n "${SHOTS_FILTER:-}" ]]; then
  grep -E "^[^\t]*(${SHOTS_FILTER})" "$PLAN" > "$PLAN.filtered" || true
  mv "$PLAN.filtered" "$PLAN"
fi
TOTAL=$(wc -l < "$PLAN" | tr -d ' ')
echo "Planned $TOTAL screenshots ($MODE effects)"

PREVIOUS_SUM=""
capture() { # name, wait, args...
  local name="$1" wait="$2"; shift 2
  xcrun simctl terminate "$UDID" "$BUNDLE_ID" >/dev/null 2>&1 || true
  xcrun simctl launch "$UDID" "$BUNDLE_ID" -ML_noIntro YES -ML_freshState YES "$@" >/dev/null < /dev/null
  sleep "$wait"
  xcrun simctl io "$UDID" screenshot --type=png "$OUT/$name.png" >/dev/null 2>&1 < /dev/null
  sips -s format jpeg -s formatOptions 55 -Z 1000 "$OUT/$name.png" --out "$OUT/$name.jpg" >/dev/null && rm "$OUT/$name.png"
}

suspicious() { # name → 0 when the shot looks blank or repeats the previous one
  local file="$OUT/$1.jpg" size sum
  [[ -f "$file" ]] || return 0
  size=$(stat -f%z "$file")
  sum=$(md5 -q "$file")
  (( size < 20000 )) && return 0  # blank pages are ~15 KB at this quality, real ones > 30 KB
  [[ -n "$PREVIOUS_SUM" && "$sum" == "$PREVIOUS_SUM" ]] && return 0
  return 1
}

DIAGNOSED=0
diagnose() { # name → main-thread sample + a later screenshot of a page that stayed blank
  (( DIAGNOSED < 6 )) || return 0
  DIAGNOSED=$((DIAGNOSED + 1))
  local base="$OUT/diag/${1//\//_}" pid
  mkdir -p "$OUT/diag"
  pid=$(pgrep -f "MotionLab.app/MotionLab" | head -n 1 || true)
  if [[ -n "$pid" ]]; then
    sample "$pid" 3 -file "$base.sample.txt" >/dev/null 2>&1 || true
  else
    echo "app process not running (crashed?)" > "$base.sample.txt"
  fi
  sleep 10
  xcrun simctl io "$UDID" screenshot --type=png "$base.later.png" >/dev/null 2>&1 < /dev/null || true
  sips -s format jpeg -s formatOptions 55 -Z 1000 "$base.later.png" --out "$base.later.jpg" >/dev/null 2>&1 && rm -f "$base.later.png"
  xcrun simctl spawn "$UDID" log show --last 40s --style compact --predicate 'process == "MotionLab"' 2>/dev/null | tail -n 80 > "$base.log.txt" || true
}

COUNT=0
RETRIED=0
FLAGGED=()
# The plan is read on fd 3 so simctl can never swallow its lines from stdin.
while IFS=$'\t' read -r name wait args <&3; do
  [[ -n "$name" ]] || continue
  mkdir -p "$OUT/$(dirname "$name")"
  # shellcheck disable=SC2086  # args are space-separated launch arguments without spaces
  capture "$name" "$wait" $args
  if suspicious "$name"; then
    RETRIED=$((RETRIED + 1))
    capture "$name" "$((wait + 3))" $args
    if suspicious "$name"; then
      FLAGGED+=("$name")
      diagnose "$name"
    fi
  fi
  PREVIOUS_SUM=$(md5 -q "$OUT/$name.jpg" 2>/dev/null || echo "")
  COUNT=$((COUNT + 1))
  if (( COUNT % 25 == 0 )); then echo "  $COUNT/$TOTAL"; fi
done 3< "$PLAN"
xcrun simctl terminate "$UDID" "$BUNDLE_ID" >/dev/null 2>&1 || true

echo "Captured $(find "$OUT" -name '*.jpg' | wc -l | tr -d ' ') screenshots ($RETRIED retried)"
if (( ${#FLAGGED[@]} > 0 )); then
  echo "warning: ${#FLAGGED[@]} screenshots still look blank or duplicated:" >&2
  printf '  %s\n' "${FLAGGED[@]}" >&2
fi
