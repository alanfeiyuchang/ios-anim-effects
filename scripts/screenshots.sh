#!/usr/bin/env bash
# Builds the app, boots an iPhone simulator and captures screenshots of every screen and every effect.
# Usage: scripts/screenshots.sh [output-dir]
set -euo pipefail
OUT="${1:-screenshots}"
BUNDLE_ID="com.motionlexicon.MotionLab"
mkdir -p "$OUT/home" "$OUT/category" "$OUT/effect"

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
xcrun simctl install "$UDID" build/Build/Products/Debug-iphonesimulator/MotionLab.app

# Warm-up launch: let first-boot system banners (e.g. "Ready for Apple Intelligence") appear and expire
# before any screenshot is taken.
xcrun simctl launch "$UDID" "$BUNDLE_ID" >/dev/null || true
sleep 45

shoot() { # name, wait, args...
  local name="$1" wait="$2"; shift 2
  xcrun simctl terminate "$UDID" "$BUNDLE_ID" >/dev/null 2>&1 || true
  xcrun simctl launch "$UDID" "$BUNDLE_ID" -ML_noIntro YES "$@" >/dev/null
  sleep "$wait"
  xcrun simctl io "$UDID" screenshot --type=png "$OUT/$name.png" >/dev/null 2>&1
  sips -s format jpeg -s formatOptions 55 -Z 1000 "$OUT/$name.png" --out "$OUT/$name.jpg" >/dev/null && rm "$OUT/$name.png"
}

shoot home/browse-zh-light 4 -app.language zh -app.appearance 1
shoot home/browse-en-dark 4 -app.language en -app.appearance 2
shoot home/search-zh 3 -app.language zh -app.appearance 1 -ML_tab 1
shoot home/favorites-zh 3 -app.language zh -app.appearance 1 -ML_tab 2
shoot home/settings-zh 3 -app.language zh -app.appearance 1 -ML_tab 3
shoot home/settings-en-dark 3 -app.language en -app.appearance 2 -ML_tab 3

for c in $(grep -oE '^    case [a-z]+$' MotionLab/Core/Effect.swift | awk '{print $2}' | head -n 15); do
  shoot "category/$c" 4 -app.language zh -app.appearance 1 -ML_route "category:$c"
done

for id in $(grep -rhoE 'id: "[a-z]+\.[a-z0-9-]+"' MotionLab/Effects | sed -E 's/id: "(.*)"/\1/' | sort -u); do
  shoot "effect/$id" 3 -app.language zh -app.appearance 1 -ML_route "effect:$id"
  if [[ "${PROMPTS:-0}" == "1" ]]; then
    shoot "effect/$id--prompt-en" 2 -app.language en -app.appearance 2 -ML_route "effect:$id" -ML_anchor prompt
  fi
done
echo "Captured $(find "$OUT" -name '*.jpg' | wc -l) screenshots"
