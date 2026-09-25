#!/usr/bin/env bash
# Records the 60 s promotional trailer (`-ML_trailer YES`, MotionLab/Trailer/) on an iPhone Pro simulator,
# once per canvas aspect (`-ML_trailerAspect 9x16|3x4`), and renders it for Xiaohongshu at 60 fps.
#
# Usage: scripts/record-trailer.sh [out-dir]        (default: out)
#        TRAILER_ASPECTS="9x16" scripts/record-trailer.sh   (record a subset; default "9x16 3x4")
# Output, per aspect:
#   <out>/9x16/trailer.mp4            1080×1920, 60 fps, H.264 CRF 18, ~60 s (full-screen video; recommended)
#   <out>/9x16/trailer-preview.mp4    540×960, 30 fps, CRF 28
#   <out>/9x16/frames/frame-01…12.png 12 evenly spaced keyframes (every 5 s, starting at 2.5 s)
#   <out>/3x4/…                       the same at 1080×1440 / 540×720
#
# Timing: the app shows a pure-white slate for 2.5 s (TrailerCanvas.leadIn) before t = 0. The recorder is
# started before the app is launched; afterwards ffmpeg finds where the white ends (negate + blackdetect)
# and cuts the 60 s from exactly there, so launch latency never shifts the cut. Each aspect is its own
# launch with --terminate-running-process, so each take starts with a fresh process (and a fresh slate).
#
# Crop math: TrailerView draws a canvas 390 pt wide and 390·R pt tall (R = 16/9 for 9x16, 4/3 for 3x4),
# scaled to the full screen width W pt and centred vertically on #0B0B0D. Its height is R·W pt and its
# top is (H − R·W)/2 pt. The recording is the screen in pixels (iw = W·scale, ih = H·scale), so in pixels:
#     crop_w = iw,  crop_h = R·iw,  crop_x = 0,  crop_y = (ih − R·iw)/2
# e.g. iPhone 16/17 Pro (402×874 pt @3x = 1206×2622 px):
#     9x16: crop=1206:2144:0:239   (1206·16/9 = 2144)      → scaled to 1080×1920
#     3x4:  crop=1206:1608:0:507   (1206·4/3  = 1608)      → scaled to 1080×1440
# crop_w/crop_h are rounded to even numbers for yuv420p; the canvas edges are #0B0B0D-dark, so the ≤1 px
# chroma alignment ffmpeg may apply to crop_y is invisible.
set -euo pipefail
OUT="${1:-out}"
BUNDLE_ID="com.motionlexicon.MotionLab"
DURATION="${TRAILER_SECONDS:-60}"
ASPECTS="${TRAILER_ASPECTS:-9x16 3x4}"
LEAD_IN=2.5
mkdir -p "$OUT"

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

BASE_ARGS=(-ML_trailer YES -ML_noIntro YES -app.language zh -app.appearance 2)

# Makes sure no instance is running: a surviving instance would simply be brought to the front by the
# next launch and the recording would start mid-trailer (or on the end card).
stop_app() {
  for i in 1 2 3 4 5; do
    limit 30 xcrun simctl terminate "$UDID" "$BUNDLE_ID" >/dev/null 2>&1 || true
    sleep 2
    if ! xcrun simctl spawn "$UDID" launchctl list 2>/dev/null | grep -q "UIKitApplication:$BUNDLE_ID"; then return 0; fi
    echo "instance still running, retrying terminate ($i)"
  done
}

# Warm-up run: first launch compiles shaders and fills caches; let first-boot banners expire meanwhile.
# The first launch after install can be slow, so it gets a generous limit.
limit 180 xcrun simctl launch "$UDID" "$BUNDLE_ID" "${BASE_ARGS[@]}" -ML_trailerAspect 9x16 >/dev/null || true
sleep 20
stop_app
sleep 8

# record_aspect <aspect> <ratio num> <ratio den> <out w> <out h> <preview w> <preview h>
record_aspect() {
  local ASPECT="$1" RN="$2" RD="$3" OW="$4" OH="$5" PW="$6" PH="$7"
  local DIR="$OUT/$ASPECT"
  local RAW="$DIR/trailer-raw.mov"
  echo "=== $ASPECT: canvas 390×$(python3 -c "print(round(390 * $RN / $RD, 2))") pt → ${OW}×${OH}"
  mkdir -p "$DIR/frames"
  rm -f "$DIR"/frames/*.png "$DIR/debug-first-frame.png"

  # Record: start the recorder, launch, let slate + trailer play, stop.
  local RECORD_SECONDS
  RECORD_SECONDS=$(python3 -c "print(int($LEAD_IN + $DURATION + 7))")
  xcrun simctl io "$UDID" recordVideo --codec=h264 --force "$RAW" >/dev/null 2>&1 &
  local REC=$!
  sleep 2
  # --terminate-running-process guarantees a fresh process, so the trailer clock starts at this launch.
  limit 120 xcrun simctl launch --terminate-running-process "$UDID" "$BUNDLE_ID" "${BASE_ARGS[@]}" -ML_trailerAspect "$ASPECT" >/dev/null
  sleep "$RECORD_SECONDS"
  kill -INT "$REC" 2>/dev/null || true
  local WAITED=0
  while kill -0 "$REC" 2>/dev/null && [ "$WAITED" -lt 40 ]; do sleep 0.5; WAITED=$((WAITED + 1)); done
  if kill -0 "$REC" 2>/dev/null; then
    kill -9 "$REC" 2>/dev/null || true
    echo "error: recorder hung ($ASPECT)"; exit 1
  fi
  wait "$REC" 2>/dev/null || true
  stop_app
  [ -s "$RAW" ] || { echo "error: empty recording ($ASPECT)"; exit 1; }

  # Crop rectangle from the recorded pixel size (see the header).
  local IW IH CROP
  IFS=x read -r IW IH < <(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=p=0:s=x "$RAW")
  CROP=$(python3 -c "
iw, ih = $IW, $IH
w = iw - iw % 2
h = int(round(iw * $RN / $RD / 2)) * 2
y = (ih - h) // 2
assert 0 <= y, 'canvas taller than the screen'
print(f'{w}:{h}:0:{y}')")
  echo "Recorded ${IW}x${IH}; crop=$CROP"

  # Trailer start = end of the first white stretch that lasts at least 1 s (the slate).
  local DETECT START
  DETECT=$(limit 180 ffmpeg -hide_banner -nostats -i "$RAW" -an \
    -vf "crop=$CROP,scale=$((PW / 2)):$((PH / 2)),negate,blackdetect=d=1.0:pix_th=0.10:pic_th=0.90" -f null - 2>&1 || true)
  START=$(printf '%s\n' "$DETECT" | python3 -c "
import re,sys
ends=[float(m.group(1)) for m in re.finditer(r'black_end:([0-9.]+)', sys.stdin.read())]
print(ends[0] if ends else '')")
  if [ -z "$START" ]; then
    # Without the slate the take didn't start at this launch (e.g. a stale instance); a guessed cut would
    # silently publish a wrong video, so fail instead.
    echo "error: white slate not found in the $ASPECT recording; the trailer did not start with this launch"
    limit 60 ffmpeg -hide_banner -loglevel error -y -ss 5 -i "$RAW" -frames:v 1 -vf "crop=$CROP" "$DIR/debug-first-frame.png" || true
    exit 1
  fi
  echo "Trailer ($ASPECT) starts at ${START}s in the raw recording"

  limit 900 ffmpeg -hide_banner -loglevel error -y -ss "$START" -i "$RAW" -t "$DURATION" -an \
    -vf "crop=$CROP,scale=$OW:$OH:flags=lanczos,fps=60,format=yuv420p" \
    -c:v libx264 -preset slow -crf 18 -movflags +faststart "$DIR/trailer.mp4"

  limit 300 ffmpeg -hide_banner -loglevel error -y -i "$DIR/trailer.mp4" -an \
    -vf "scale=$PW:$PH:flags=lanczos,fps=30,format=yuv420p" \
    -c:v libx264 -preset medium -crf 28 -movflags +faststart "$DIR/trailer-preview.mp4"

  local i T
  for i in $(seq 1 12); do
    T=$(python3 -c "print(($i - 0.5) * $DURATION / 12)")
    limit 60 ffmpeg -hide_banner -loglevel error -y -ss "$T" -i "$DIR/trailer.mp4" -frames:v 1 \
      "$DIR/frames/frame-$(printf '%02d' "$i").png" || true
  done

  rm -f "$RAW"
  ffprobe -v error -show_entries format=duration:stream=width,height,r_frame_rate -of default=nw=1 "$DIR/trailer.mp4"
  ls -la "$DIR" "$DIR/frames"
}

for ASPECT in $ASPECTS; do
  case "$ASPECT" in
    9x16) record_aspect 9x16 16 9 1080 1920 540 960 ;;
    3x4)  record_aspect 3x4 4 3 1080 1440 540 720 ;;
    *)    echo "error: unknown aspect '$ASPECT' (use 9x16 or 3x4)"; exit 1 ;;
  esac
  sleep 5
done
