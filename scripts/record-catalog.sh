#!/usr/bin/env bash
# Records a short looping video + poster of every effect (zh and en) for the documentation site.
# Usage: scripts/record-catalog.sh <out-dir> <shard-index> <shard-count>
# Output: <out-dir>/media/<id>.<lang>.mp4, <out-dir>/media/<id>.<lang>.jpg, and (shard 0) <out-dir>/catalog.json
set -euo pipefail
OUT="${1:-catalog-out}"
SHARD="${2:-0}"
SHARDS="${3:-1}"
BUNDLE_ID="com.motionlexicon.MotionLab"
CLIP_SECONDS="${CLIP_SECONDS:-4}"
mkdir -p "$OUT/media" "$OUT/raw"

UDID=$(xcrun simctl list devices available -j | python3 -c '
import json,sys
d=json.load(sys.stdin)["devices"]
c=[x for rt,xs in d.items() if "iOS" in rt for x in xs if x["name"].startswith("iPhone") and "Pro" in x["name"] and "Max" not in x["name"]]
c=c or [x for rt,xs in d.items() if "iOS" in rt for x in xs if x["name"].startswith("iPhone")]
print(c[-1]["udid"])')
echo "Simulator: $UDID (shard $SHARD/$SHARDS)"
xcrun simctl boot "$UDID" || true
xcrun simctl bootstatus "$UDID" -b
xcrun simctl status_bar "$UDID" override --time "9:41" --batteryState charged --batteryLevel 100 || true

xcodebuild -project MotionLab.xcodeproj -scheme MotionLab -sdk iphonesimulator \
  -destination "id=$UDID" -derivedDataPath build CODE_SIGNING_ALLOWED=NO build > build.log 2>&1 \
  || { grep -E "error:" build.log | sort -u; exit 1; }
xcrun simctl install "$UDID" build/Build/Products/Debug-iphonesimulator/MotionLab.app

# Export the catalog (every shard needs the id list; shard 0 publishes it).
xcrun simctl launch "$UDID" "$BUNDLE_ID" -ML_exportCatalog YES -ML_noIntro YES >/dev/null
sleep 6
CONTAINER=$(xcrun simctl get_app_container "$UDID" "$BUNDLE_ID" data)
cp "$CONTAINER/Documents/catalog.json" "$OUT/catalog.json"
xcrun simctl terminate "$UDID" "$BUNDLE_ID" >/dev/null 2>&1 || true
# Let first-boot system banners expire before recording.
sleep 30

IDS=$(python3 -c "
import json
ids=[e['id'] for e in json.load(open('$OUT/catalog.json'))['effects']]
print('\n'.join(i for n,i in enumerate(ids) if n % $SHARDS == $SHARD))")

# Runs a command with a time limit (macOS has no GNU timeout); a hung simctl call must not stall the shard.
limit() { local secs="$1"; shift; perl -e 'alarm shift; exec @ARGV' "$secs" "$@"; }

record() { # id lang
  local id="$1" lang="$2" raw="$OUT/raw/$1.$2.mov"
  limit 20 xcrun simctl terminate "$UDID" "$BUNDLE_ID" >/dev/null 2>&1 || true
  if ! limit 30 xcrun simctl launch "$UDID" "$BUNDLE_ID" -ML_stage "$id" -ML_noIntro YES -app.language "$lang" -app.appearance 2 >/dev/null; then
    echo "skip $id.$lang: launch failed or timed out"; return 0
  fi
  sleep 1.2
  xcrun simctl io "$UDID" recordVideo --codec=h264 --force "$raw" >/dev/null 2>&1 &
  local rec=$!
  sleep "$CLIP_SECONDS"
  kill -INT "$rec" 2>/dev/null || true
  # Give the recorder up to 10 s to finalize the file, then kill it.
  local waited=0
  while kill -0 "$rec" 2>/dev/null && [ "$waited" -lt 20 ]; do sleep 0.5; waited=$((waited + 1)); done
  if kill -0 "$rec" 2>/dev/null; then
    kill -9 "$rec" 2>/dev/null || true
    echo "skip $id.$lang: recorder hung"; rm -f "$raw"; return 0
  fi
  wait "$rec" 2>/dev/null || true
  [ -s "$raw" ] || { echo "skip $id.$lang: empty recording"; return 0; }
  # Square crop from the vertical center, 480 px, 30 fps, small h264 that loops cleanly on the web.
  limit 60 ffmpeg -loglevel error -y -i "$raw" -an \
    -vf "crop=iw:iw:0:(ih-iw)/2,scale=480:480:flags=lanczos,fps=30,format=yuv420p" \
    -c:v libx264 -preset veryfast -crf 30 -movflags +faststart "$OUT/media/$id.$lang.mp4" || return 0
  limit 30 ffmpeg -loglevel error -y -ss 2 -i "$OUT/media/$id.$lang.mp4" -frames:v 1 -q:v 5 "$OUT/media/$id.$lang.jpg" || true
  rm -f "$raw"
}

COUNT=0
for id in $IDS; do
  record "$id" zh
  record "$id" en
  COUNT=$((COUNT + 1))
done
echo "Recorded $COUNT effects × 2 languages in shard $SHARD"
