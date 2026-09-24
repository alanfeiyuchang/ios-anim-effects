#!/usr/bin/env bash
# Records the 60 s promotional trailer (`-ML_trailer YES`, MotionLab/Trailer/) on an iPhone Pro simulator
# and renders it for Xiaohongshu (3:4, 1080×1440, 60 fps).
#
# Usage: scripts/record-trailer.sh [out-dir]        (default: out)
# Output: <out>/trailer.mp4            1080×1440, 60 fps, H.264 CRF 18, ~60 s
#         <out>/trailer-preview.mp4    540×720, 30 fps, CRF 28
#         <out>/frames/frame-01…12.png 12 evenly spaced keyframes (every 5 s, starting at 2.5 s)
#
# Timing: the app shows a pure-white slate for 2.5 s (TrailerCanvas.leadIn) before t = 0. The recorder is
# started before the app is launched; afterwards ffmpeg finds where the white ends (negate + blackdetect)
# and cuts the 60 s from exactly there, so launch latency never shifts the cut.
#
# Crop math: TrailerView draws a 390×520 pt canvas (3:4) scaled to the full screen width W pt and centred
# vertically on #0B0B0D. Its height is 520·W/390 = 4W/3 pt and its top is (H − 4W/3)/2 pt. The recording is
# the screen in pixels (iw = W·scale, ih = H·scale), so in pixels:
#     crop_w = iw,  crop_h = 4·iw/3,  crop_x = 0,  crop_y = (ih − 4·iw/3)/2
# e.g. iPhone 16/17 Pro (402×874 pt @3x = 1206×2622 px): crop=1206:1608:0:507.
# crop_w/crop_h are rounded to even numbers for yuv420p; the canvas edges are #0B0B0D-dark, so the ≤1 px
# chroma alignment ffmpeg may apply to crop_y is invisible.
set -euo pipefail
OUT="${1:-out}"
BUNDLE_ID="com.motionlexicon.MotionLab"
DURATION="${TRAILER_SECONDS:-60}"
LEAD_IN=2.5
mkdir -p "$OUT/frames"
rm -f "$OUT"/frames/*.png
RAW="$OUT/trailer-raw.mov"

# Runs a command with a time limit (macOS has no GNU timeout); a hung simctl/ffmpeg call must not stall CI.
limit() { local secs="$1"; shift; perl -e 'alarm shift; exec @ARGV' "$secs" "$@"; }

UDID=$(xcrun simctl list devices available -j | python3 -c '
import json,sys
d=json.load(sys.stdin)["devices"]
c=[x for rt,xs in d.items() if "iOS" in rt for x in xs if x["name"].startswith("iPhone") and "Pro" in x["name"] and "Max" not in x["name"]]
c=c or [x for rt,xs in d.items() if "iOS" in rt for x in xs if x["name"].startswith("iPhone")]
print(c[-1]["udid"])')
echo "Simulator: $UDID"
xcrun simctl boot "$UDID" || true
limit 300 xcrun simctl bootstatus "$UDID" -b
xcrun simctl status_bar "$UDID" override --time "9:41" --batteryState charged --batteryLevel 100 || true
xcrun simctl ui "$UDID" appearance dark || true

# Release: the trailer is a continuous 60 fps take, so it gets the optimised build.
xcodebuild -project MotionLab.xcodeproj -scheme MotionLab -configuration Release -sdk iphonesimulator \
  -destination "id=$UDID" -derivedDataPath build CODE_SIGNING_ALLOWED=NO build > build.log 2>&1 \
  || { grep -E "error:" build.log | sort -u; exit 1; }
xcrun simctl install "$UDID" build/Build/Products/Release-iphonesimulator/MotionLab.app

LAUNCH_ARGS=(-ML_trailer YES -ML_noIntro YES -app.language zh -app.appearance 2)

# Warm-up run: first launch compiles shaders and fills caches; let first-boot banners expire meanwhile.
# The first launch after install can be slow, so it gets a generous limit.
limit 180 xcrun simctl launch "$UDID" "$BUNDLE_ID" "${LAUNCH_ARGS[@]}" >/dev/null || true
sleep 20
# Make sure the warm-up instance is really gone: a surviving instance would simply be brought to the
# front by the next launch and the recording would start mid-trailer (or on the end card).
for i in 1 2 3 4 5; do
  limit 30 xcrun simctl terminate "$UDID" "$BUNDLE_ID" >/dev/null 2>&1 || true
  sleep 2
  if ! xcrun simctl spawn "$UDID" launchctl list 2>/dev/null | grep -q "UIKitApplication:$BUNDLE_ID"; then break; fi
  echo "warm-up instance still running, retrying terminate ($i)"
done
sleep 8

# Record: start the recorder, launch, let slate + trailer play, stop.
RECORD_SECONDS=$(python3 -c "print(int($LEAD_IN + $DURATION + 7))")
xcrun simctl io "$UDID" recordVideo --codec=h264 --force "$RAW" >/dev/null 2>&1 &
REC=$!
sleep 2
# --terminate-running-process guarantees a fresh process, so the trailer clock starts at this launch.
limit 120 xcrun simctl launch --terminate-running-process "$UDID" "$BUNDLE_ID" "${LAUNCH_ARGS[@]}" >/dev/null
sleep "$RECORD_SECONDS"
kill -INT "$REC" 2>/dev/null || true
WAITED=0
while kill -0 "$REC" 2>/dev/null && [ "$WAITED" -lt 40 ]; do sleep 0.5; WAITED=$((WAITED + 1)); done
if kill -0 "$REC" 2>/dev/null; then
  kill -9 "$REC" 2>/dev/null || true
  echo "error: recorder hung"; exit 1
fi
wait "$REC" 2>/dev/null || true
limit 20 xcrun simctl terminate "$UDID" "$BUNDLE_ID" >/dev/null 2>&1 || true
[ -s "$RAW" ] || { echo "error: empty recording"; exit 1; }

# Crop rectangle from the recorded pixel size (see the header).
IFS=x read -r IW IH < <(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=p=0:s=x "$RAW")
CROP=$(python3 -c "
iw, ih = $IW, $IH
w = iw - iw % 2
h = int(round(iw * 4 / 3 / 2)) * 2
y = (ih - h) // 2
print(f'{w}:{h}:0:{y}')")
echo "Recorded ${IW}x${IH}; crop=$CROP"

# Trailer start = end of the first white stretch that lasts at least 1 s (the slate).
DETECT=$(limit 180 ffmpeg -hide_banner -nostats -i "$RAW" -an \
  -vf "crop=$CROP,scale=270:360,negate,blackdetect=d=1.0:pix_th=0.10:pic_th=0.90" -f null - 2>&1 || true)
START=$(printf '%s\n' "$DETECT" | python3 -c "
import re,sys
ends=[float(m.group(1)) for m in re.finditer(r'black_end:([0-9.]+)', sys.stdin.read())]
print(ends[0] if ends else '')")
if [ -z "$START" ]; then
  # Without the slate the take didn't start at this launch (e.g. a stale instance); a guessed cut would
  # silently publish a wrong video, so fail instead.
  echo "error: white slate not found in the recording; the trailer did not start with this launch"
  limit 60 ffmpeg -hide_banner -loglevel error -y -ss 5 -i "$RAW" -frames:v 1 -vf "crop=$CROP" "$OUT/debug-first-frame.png" || true
  exit 1
else
  echo "Trailer starts at ${START}s in the raw recording"
fi

limit 900 ffmpeg -hide_banner -loglevel error -y -ss "$START" -i "$RAW" -t "$DURATION" -an \
  -vf "crop=$CROP,scale=1080:1440:flags=lanczos,fps=60,format=yuv420p" \
  -c:v libx264 -preset slow -crf 18 -movflags +faststart "$OUT/trailer.mp4"

limit 300 ffmpeg -hide_banner -loglevel error -y -i "$OUT/trailer.mp4" -an \
  -vf "scale=540:720:flags=lanczos,fps=30,format=yuv420p" \
  -c:v libx264 -preset medium -crf 28 -movflags +faststart "$OUT/trailer-preview.mp4"

for i in $(seq 1 12); do
  T=$(python3 -c "print(($i - 0.5) * $DURATION / 12)")
  limit 60 ffmpeg -hide_banner -loglevel error -y -ss "$T" -i "$OUT/trailer.mp4" -frames:v 1 \
    "$OUT/frames/frame-$(printf '%02d' "$i").png" || true
done

rm -f "$RAW"
ffprobe -v error -show_entries format=duration:stream=width,height,r_frame_rate -of default=nw=1 "$OUT/trailer.mp4"
ls -la "$OUT" "$OUT/frames"
