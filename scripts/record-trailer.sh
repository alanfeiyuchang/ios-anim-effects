#!/usr/bin/env bash
# Records the 75 s promotional trailer (`-ML_trailer YES`, MotionLab/Trailer/) on an iPhone Pro simulator,
# once per canvas aspect (`-ML_trailerAspect 9x16|3x4`), and renders it for Xiaohongshu at 60 fps.
# Works on your own Mac (see docs/TRAILER.md) and in CI (.github/workflows/trailer.yml).
#
# Usage: scripts/record-trailer.sh [options] [out-dir]
#   --copy <file>        Trailer copy JSON (TrailerCopy; edit with tools/trailer-editor.html).
#                        Default: trailer/copy.json if it exists, else the built-in defaults.
#   --aspects "<list>"   Aspects to record, space-separated: "9x16 3x4" (default), "9x16", "3x4".
#   --out <dir>          Output folder (default: out). A bare positional argument means the same.
#   --device "<name>"    Simulator to use, e.g. "iPhone 17 Pro" (default: newest iPhone Pro available).
#   --voiceover-only     Only (re)write voiceover.srt / voiceover.txt in <out>/<aspect>/ from the copy file
#                        (no Xcode needed; numbers from the trailer-resolved.json of an earlier take).
#   -h, --help           Show this help.
# Environment (still honoured): TRAILER_ASPECTS (same as --aspects), TRAILER_SECONDS (cut length, 75.4).
#
# Output, per aspect:
#   <out>/9x16/trailer.mp4            1080×1920, 60 fps, H.264 CRF 18, 75.4 s (full-screen video; recommended)
#   <out>/9x16/trailer-preview.mp4    540×960, 30 fps, CRF 28
#   <out>/9x16/frames/frame-01…15.png 15 evenly spaced keyframes (every 5 s, starting at 2.5 s)
#   <out>/9x16/voiceover.srt          voice-over subtitles, UTF-8, ≤ 18 characters per cue (import into 剪映)
#   <out>/9x16/voiceover.txt          the voice-over script, one line per entry (for recording or TTS)
#   <out>/9x16/trailer-resolved.json  the copy as the app showed it ({effects}… expanded) + catalog counts
#   <out>/3x4/…                       the same at 1080×1440 / 540×720
#
# Copy: after installing the app, the copy JSON is placed in the app's data container as
# Documents/trailer-copy.json before every launch (`xcrun simctl get_app_container <udid> <bundle> data`);
# the trailer reads it at start (missing keys fall back to the defaults). Without a copy file, any stale
# Documents/trailer-copy.json is removed so the defaults are used.
#
# Voice-over: the copy's `voiceover` lines ({start, end, text}, seconds of the cut) are never drawn. At start
# the app writes the resolved copy (placeholders such as {effects} expanded from the live catalog) to
# Documents/trailer-resolved.json; after each take the script copies it out and writes voiceover.srt (each
# sentence split into as few cues of ≤ 18 characters as possible — CJK 1, Latin ½ — timed in proportion to
# their length) and voiceover.txt.
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

usage() { sed -n '2,24p' "$0" | sed 's/^# \{0,1\}//'; }
die() { echo "错误 / error: $*" >&2; exit 1; }

OUT=""
COPY=""
COPY_SET=0
ASPECTS="${TRAILER_ASPECTS:-9x16 3x4}"
DEVICE=""
VOICEOVER_ONLY=0
while [ $# -gt 0 ]; do
  case "$1" in
    --copy) [ $# -ge 2 ] || die "--copy 需要一个文件路径"; COPY="$2"; COPY_SET=1; shift 2 ;;
    --copy=*) COPY="${1#*=}"; COPY_SET=1; shift ;;
    --aspects) [ $# -ge 2 ] || die "--aspects 需要一个列表，例如 \"9x16 3x4\""; ASPECTS="$2"; shift 2 ;;
    --aspects=*) ASPECTS="${1#*=}"; shift ;;
    --out) [ $# -ge 2 ] || die "--out 需要一个目录"; OUT="$2"; shift 2 ;;
    --out=*) OUT="${1#*=}"; shift ;;
    --device) [ $# -ge 2 ] || die "--device 需要模拟器名称，例如 \"iPhone 17 Pro\""; DEVICE="$2"; shift 2 ;;
    --device=*) DEVICE="${1#*=}"; shift ;;
    --voiceover-only) VOICEOVER_ONLY=1; shift ;;
    -h|--help) usage; exit 0 ;;
    -*) die "未知参数 $1（用 --help 查看用法）" ;;
    *) [ -z "$OUT" ] || die "多余的参数 $1"; OUT="$1"; shift ;;
  esac
done
OUT="${OUT:-out}"
ASPECTS="$(printf '%s' "$ASPECTS" | tr ',' ' ' | xargs)"
for ASPECT in $ASPECTS; do
  case "$ASPECT" in 9x16|3x4) ;; *) die "未知画幅 '$ASPECT'（只能是 9x16 或 3x4）" ;; esac
done
[ -n "$ASPECTS" ] || die "--aspects 为空"

# Absolute paths for what the caller named relative to their shell, then work from the repo root.
abs_path() { case "$1" in /*) printf '%s\n' "$1" ;; *) printf '%s\n' "$PWD/$1" ;; esac; }
OUT="$(abs_path "$OUT")"
[ -z "$COPY" ] || COPY="$(abs_path "$COPY")"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# --- Copy (on-screen text) ----------------------------------------------------------------------------
if [ "$COPY_SET" -eq 0 ] && [ -f "$ROOT/trailer/copy.json" ]; then
  COPY="$ROOT/trailer/copy.json"
fi
if [ -n "$COPY" ]; then
  [ -f "$COPY" ] || die "找不到文案文件 $COPY"
  python3 -c 'import json,sys; json.load(open(sys.argv[1], encoding="utf-8"))' "$COPY" 2>/dev/null \
    || die "文案文件不是合法的 JSON：$COPY（可用 tools/trailer-editor.html 导入检查后重新导出）"
  echo "Copy: $COPY"
else
  echo "Copy: built-in defaults (no trailer/copy.json)"
fi

BUNDLE_ID="com.motionlexicon.MotionLab"
DURATION="${TRAILER_SECONDS:-75.4}"
LEAD_IN=2.5
mkdir -p "$OUT"

# --- Voice-over subtitles ---------------------------------------------------------------------------
# One keyframe every 5 s (15 for the 75.4 s cut).
KEYFRAMES=$(python3 -c "print(max(1, round($DURATION / 5)))")

# voiceover_files <dir> [resolved json]: writes <dir>/voiceover.srt and <dir>/voiceover.txt. Lines come from the
# resolved copy the app wrote (placeholders already expanded), or — with PREFER_COPY=1, or when there is no
# resolved copy — from the copy file, expanded with the resolved copy's counts (else Documents/catalog.json).
voiceover_files() {
  OUTDIR="$1" RESOLVED="${2:-}" COPY="$COPY" CATALOG="${CATALOG:-}" PREFER_COPY="${PREFER_COPY:-0}" DURATION="$DURATION" \
    python3 - <<'PY'
import json, os, re, sys

LIMIT = 18.0  # subtitle line width: CJK characters count 1, ASCII 1/2


def width(text):
    return sum(0.5 if ord(ch) < 128 else 1.0 for ch in text)


def read_json(path):
    with open(path, encoding="utf-8-sig") as handle:
        return json.load(handle)


def counts_and_lines():
    """Voice-over lines with placeholders expanded, from the app's resolved copy or the copy file."""
    resolved = os.environ.get("RESOLVED") or ""
    copy = os.environ.get("COPY") or ""
    catalog = os.environ.get("CATALOG") or ""
    prefer_copy = os.environ.get("PREFER_COPY") == "1"
    counts, lines = {}, None
    if resolved and os.path.exists(resolved):
        data = read_json(resolved)
        counts = {key: int(value) for key, value in data.get("counts", {}).items()}
        if not prefer_copy:
            lines = data.get("copy", {}).get("voiceover")
    if lines is None:
        if copy and os.path.exists(copy):
            lines = read_json(copy).get("voiceover")
        if lines is None:
            sys.stderr.write("warning: no voice-over lines found (copy file without \"voiceover\")\n")
            return []
        if not counts and catalog and os.path.exists(catalog):
            data = read_json(catalog)
            counts = {"effects": len(data.get("effects", [])), "categories": len(data.get("categories", [])),
                      "families": len(data.get("families", []))}
        if not counts:
            sys.stderr.write("warning: catalog counts unknown; {effects}/{categories}/{families} left as they are\n")
    result = []
    for line in lines if isinstance(lines, list) else []:
        if not isinstance(line, dict):
            continue
        text = str(line.get("text", ""))
        for key, value in counts.items():
            text = text.replace("{" + key + "}", str(value))
        try:
            start = float(line.get("start", 0))
            end = float(line.get("end", start))
        except (TypeError, ValueError):
            continue
        result.append((start, end, text))
    return result


# Clause breaks: CJK punctuation, dashes, ellipses, and ASCII , . ; : ! ? unless inside a number (0.55).
PUNCT = "(?:[，。！？；：、!?;:—…]|[.,](?!\\d))"
TRAILING = "，。；：、,.;:—… "


def clauses(text):
    """Pieces that each end after their run of punctuation (the punctuation stays with its clause)."""
    pattern = "(?:(?!%s).)+(?:%s)*|(?:%s)+" % (PUNCT, PUNCT, PUNCT)
    return [piece for piece in re.findall(pattern, text) if piece.strip()]


def is_word_char(ch):
    return ch.isascii() and (ch.isalnum() or ch == ".")


def hard_split(text):
    """Splits an over-long clause at the widest prefix that fits, never inside a Latin word or number."""
    parts = []
    while width(text) > LIMIT:
        cut, total = 0, 0.0
        for index, ch in enumerate(text):
            total += 0.5 if ord(ch) < 128 else 1.0
            if total > LIMIT:
                break
            cut = index + 1
        probe = cut
        while 0 < probe < len(text) and is_word_char(text[probe - 1]) and is_word_char(text[probe]):
            probe -= 1
        if probe > 0:
            cut = probe
        cut = max(cut, 1)
        parts.append(text[:cut])
        text = text[cut:].lstrip()
    if text:
        parts.append(text)
    return parts


def sentences(text):
    """Splits after 。！？； (and ASCII ! ? ;) so a subtitle never straddles two sentences."""
    parts = re.findall(r"[^。！？；!?;]+[。！？；!?;]*|[。！？；!?;]+", text)
    return [part for part in parts if part.strip()]


def chunks(text):
    result = []
    for sentence in sentences(text.strip()):
        result.extend(sentence_chunks(sentence))
    return result


def sentence_chunks(text):
    """Fewest subtitle lines of at most LIMIT, with the clauses spread as evenly as possible."""
    pieces = []
    for clause in clauses(text.strip()):
        pieces.extend(hard_split(clause) if width(clause) > LIMIT else [clause])
    if not pieces:
        return []
    widths = [width(piece) for piece in pieces]
    count = len(pieces)

    def span(i, j):
        return sum(widths[i:j])

    # Greedy line count (the minimum), then the partition into that many lines with the smallest widest line.
    lines, current = 1, 0.0
    for w in widths:
        if current and current + w > LIMIT:
            lines += 1
            current = w
        else:
            current += w
    infinity = float("inf")
    best = [[infinity] * (count + 1) for _ in range(lines + 1)]
    cut = [[0] * (count + 1) for _ in range(lines + 1)]
    best[0][0] = 0.0
    for k in range(1, lines + 1):
        for j in range(1, count + 1):
            for i in range(k - 1, j):
                size = span(i, j)
                if size > LIMIT or best[k - 1][i] == infinity:
                    continue
                value = max(best[k - 1][i], size)
                if value < best[k][j]:
                    best[k][j] = value
                    cut[k][j] = i
    if best[lines][count] == infinity:
        return pieces
    bounds, j = [], count
    for k in range(lines, 0, -1):
        i = cut[k][j]
        bounds.append((i, j))
        j = i
    return ["".join(pieces[i:j]).strip() for i, j in reversed(bounds)]


def clean(chunk):
    """Subtitle style: no trailing commas or periods; inner ，。；： become spaces (？！ and quotes stay)."""
    text = chunk.strip().rstrip(TRAILING)
    text = re.sub("[，。；：]", " ", text)
    text = re.sub(r"\s{2,}", " ", text)
    return text.strip()


def stamp(seconds):
    millis = int(round(max(seconds, 0) * 1000))
    hours, rest = divmod(millis, 3600000)
    minutes, rest = divmod(rest, 60000)
    secs, millis = divmod(rest, 1000)
    return "%02d:%02d:%02d,%03d" % (hours, minutes, secs, millis)


duration = float(os.environ.get("DURATION") or 75.4)
cues, script = [], []
for start, end, text in sorted(counts_and_lines(), key=lambda item: item[0]):
    text = text.strip()
    start = max(start, 0.0)
    end = min(max(end, start), duration)
    if not text or end <= start:
        continue
    script.append(text)
    pieces = chunks(text)
    weights = [max(width(piece), 0.5) for piece in pieces]
    total = sum(weights)
    cursor = start
    for piece, weight in zip(pieces, weights):
        span = (end - start) * weight / total
        caption = clean(piece)
        if caption:
            cues.append((cursor, cursor + span, caption))
        cursor += span

directory = os.environ["OUTDIR"]
with open(os.path.join(directory, "voiceover.srt"), "w", encoding="utf-8", newline="\n") as handle:
    for index, (begin, finish, caption) in enumerate(cues, 1):
        # A hair of air between cues, so players never show two at once.
        shown_until = finish - 0.02 if finish - begin > 0.1 else finish
        handle.write("%d\n%s --> %s\n%s\n\n" % (index, stamp(begin), stamp(shown_until), caption))
with open(os.path.join(directory, "voiceover.txt"), "w", encoding="utf-8", newline="\n") as handle:
    handle.write("\n".join(script) + ("\n" if script else ""))
print("Voice-over: %d lines -> %d subtitles (%s)" % (len(script), len(cues), os.path.join(directory, "voiceover.srt")))
PY
}

# write_voiceover <dir>: after a take, copies Documents/trailer-resolved.json out of the app and writes the
# voice-over files from it.
write_voiceover() {
  local DIR="$1" DATA
  DATA=$(xcrun simctl get_app_container "$UDID" "$BUNDLE_ID" data 2>/dev/null || true)
  if [ -n "$DATA" ] && [ -s "$DATA/Documents/trailer-resolved.json" ]; then
    cp "$DATA/Documents/trailer-resolved.json" "$DIR/trailer-resolved.json"
    voiceover_files "$DIR" "$DIR/trailer-resolved.json" || echo "warning: voiceover.srt not written" >&2
  else
    echo "warning: the app did not write Documents/trailer-resolved.json; voice-over built from the copy file" >&2
    rm -f "$DIR/trailer-resolved.json"
    CATALOG="${DATA:+$DATA/Documents/catalog.json}" voiceover_files "$DIR" || echo "warning: voiceover.srt not written" >&2
  fi
}

# --- Voice-over only ---------------------------------------------------------------------------------
if [ "$VOICEOVER_ONLY" -eq 1 ]; then
  command -v python3 >/dev/null 2>&1 || die "缺少 python3（macOS 自带；或 brew install python）"
  [ -n "$COPY" ] || die "--voiceover-only 需要文案文件（trailer/copy.json 或 --copy <文件>）"
  for ASPECT in $ASPECTS; do
    DIR="$OUT/$ASPECT"
    mkdir -p "$DIR"
    if [ -s "$DIR/trailer-resolved.json" ]; then
      PREFER_COPY=1 voiceover_files "$DIR" "$DIR/trailer-resolved.json"
    else
      voiceover_files "$DIR"
    fi
  done
  exit 0
fi

# --- Prerequisites ------------------------------------------------------------------------------------
MISSING=0
need() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "缺少 / missing: $1 — $2" >&2
    MISSING=1
  fi
}
need xcodebuild "请安装 Xcode 26（或 16）并运行一次；然后执行 sudo xcode-select -s /Applications/Xcode.app"
need xcrun "请安装 Xcode 与命令行工具：xcode-select --install"
need ffmpeg "请安装：brew install ffmpeg（没有 Homebrew？见 https://brew.sh）"
need ffprobe "随 ffmpeg 一起安装：brew install ffmpeg"
need python3 "macOS 自带；或 brew install python"
need perl "macOS 自带"
[ "$MISSING" -eq 0 ] || exit 1
if ! xcrun simctl help >/dev/null 2>&1; then
  die "xcrun simctl 不可用：请在 Xcode › Settings › Components 安装 iOS 模拟器，并确认 xcode-select -p 指向 Xcode.app（而不是 CommandLineTools）"
fi
[ -d MotionLab.xcodeproj ] || die "找不到 MotionLab.xcodeproj（脚本应位于仓库的 scripts/ 目录）"

# Runs a command with a time limit (macOS has no GNU timeout); a hung simctl/ffmpeg call must not stall CI.
limit() { local secs="$1"; shift; perl -e 'alarm shift; exec @ARGV' "$secs" "$@"; }

# --- Simulator ----------------------------------------------------------------------------------------
# Default: the newest iPhone Pro (not Max) on the newest iOS runtime; --device picks one by name
# (on the newest runtime that has it).
UDID=$(xcrun simctl list devices available -j | DEVICE="$DEVICE" python3 -c '
import json, os, re, sys
devices = json.load(sys.stdin)["devices"]
wanted = os.environ.get("DEVICE", "").strip()
def runtime_version(key):
    m = re.search(r"iOS-(\d+)(?:-(\d+))?", key)
    return (int(m.group(1)), int(m.group(2) or 0)) if m else (0, 0)
def model(name):
    m = re.search(r"iPhone (\d+)", name)
    return int(m.group(1)) if m else 0
phones = [(runtime_version(rt), d) for rt, ds in devices.items() if "iOS" in rt for d in ds if d["name"].startswith("iPhone")]
if wanted:
    pool = [p for p in phones if p[1]["name"].lower() == wanted.lower()]
else:
    pool = [p for p in phones if "Pro" in p[1]["name"] and "Max" not in p[1]["name"]] or phones
if not pool:
    names = sorted({d["name"] for _, d in phones})
    sys.stderr.write("可用的 iPhone 模拟器 / available: " + (", ".join(names) or "（无 / none）") + "\n")
    sys.exit(1)
pool.sort(key=lambda p: (p[0], model(p[1]["name"])))
print(pool[-1][1]["udid"])') || {
  if [ -n "$DEVICE" ]; then
    die "找不到模拟器 \"$DEVICE\"。用上面列出的名称之一，或在 Xcode › Window › Devices and Simulators 新建"
  fi
  die "没有可用的 iPhone 模拟器：请在 Xcode › Settings › Components 安装 iOS 运行时"
}
echo "Simulator: $(xcrun simctl list devices | grep "$UDID" | sed 's/^ *//' | head -n 1)"
xcrun simctl boot "$UDID" 2>/dev/null || true
limit 300 xcrun simctl bootstatus "$UDID" -b
xcrun simctl status_bar "$UDID" override --time "9:41" --batteryState charged --batteryLevel 100 || true
xcrun simctl ui "$UDID" appearance dark || true

# --- Build & install ----------------------------------------------------------------------------------
# Release: the trailer is a continuous 60 fps take, so it gets the optimised build.
echo "Building (Release)… the first build can take several minutes; log: $ROOT/build.log"
xcodebuild -project MotionLab.xcodeproj -scheme MotionLab -configuration Release -sdk iphonesimulator \
  -destination "id=$UDID" -derivedDataPath build CODE_SIGNING_ALLOWED=NO build > build.log 2>&1 \
  || { grep -E "error:" build.log | sort -u; die "构建失败，详见 $ROOT/build.log"; }
xcrun simctl install "$UDID" build/Build/Products/Release-iphonesimulator/MotionLab.app

# Puts the copy JSON into the app's Documents (or removes a stale one), right before a launch.
install_copy() {
  local DATA
  DATA=$(xcrun simctl get_app_container "$UDID" "$BUNDLE_ID" data) || die "取不到 App 数据容器（App 是否已安装？）"
  mkdir -p "$DATA/Documents"
  # Written by the app at start; removed first so a take can never hand back a stale one.
  rm -f "$DATA/Documents/trailer-resolved.json"
  if [ -n "$COPY" ]; then
    cp "$COPY" "$DATA/Documents/trailer-copy.json"
  else
    rm -f "$DATA/Documents/trailer-copy.json"
  fi
  # The repository page shown in the open-source beat (a screenshot of github.com, mobile layout, dark).
  if [ -f "$ROOT/trailer/github.jpg" ]; then
    cp "$ROOT/trailer/github.jpg" "$DATA/Documents/trailer-github.jpg"
  else
    rm -f "$DATA/Documents/trailer-github.jpg"
  fi
}

# -ML_freshState: no persisted "Recently Viewed" row, so the embedded Browse screen is the same every take.
BASE_ARGS=(-ML_trailer YES -ML_noIntro YES -ML_freshState YES -app.language zh -app.appearance 2)

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
FIRST_ASPECT="${ASPECTS%% *}"
install_copy
limit 180 xcrun simctl launch "$UDID" "$BUNDLE_ID" "${BASE_ARGS[@]}" -ML_trailerAspect "$FIRST_ASPECT" >/dev/null || true
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
  install_copy
  xcrun simctl io "$UDID" recordVideo --codec=h264 --force "$RAW" >/dev/null 2>&1 &
  local REC=$!
  sleep 2
  # --terminate-running-process guarantees a fresh process, so the trailer clock starts at this launch.
  limit 120 xcrun simctl launch --terminate-running-process "$UDID" "$BUNDLE_ID" "${BASE_ARGS[@]}" -ML_trailerAspect "$ASPECT" >/dev/null
  echo "Recording $ASPECT for ${RECORD_SECONDS}s…"
  sleep "$RECORD_SECONDS"
  kill -INT "$REC" 2>/dev/null || true
  local WAITED=0
  while kill -0 "$REC" 2>/dev/null && [ "$WAITED" -lt 40 ]; do sleep 0.5; WAITED=$((WAITED + 1)); done
  if kill -0 "$REC" 2>/dev/null; then
    kill -9 "$REC" 2>/dev/null || true
    die "recorder hung ($ASPECT)"
  fi
  wait "$REC" 2>/dev/null || true
  stop_app
  [ -s "$RAW" ] || die "empty recording ($ASPECT)"

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
    limit 60 ffmpeg -hide_banner -loglevel error -y -ss 5 -i "$RAW" -frames:v 1 -vf "crop=$CROP" "$DIR/debug-first-frame.png" || true
    die "white slate not found in the $ASPECT recording; the trailer did not start with this launch (see $DIR/debug-first-frame.png; docs/TRAILER.md › 常见问题)"
  fi
  echo "Trailer ($ASPECT) starts at ${START}s in the raw recording"

  limit 1500 ffmpeg -hide_banner -loglevel error -y -ss "$START" -i "$RAW" -t "$DURATION" -an \
    -vf "crop=$CROP,scale=$OW:$OH:flags=lanczos,fps=60,format=yuv420p" \
    -c:v libx264 -preset slow -crf 18 -movflags +faststart "$DIR/trailer.mp4"

  limit 450 ffmpeg -hide_banner -loglevel error -y -i "$DIR/trailer.mp4" -an \
    -vf "scale=$PW:$PH:flags=lanczos,fps=30,format=yuv420p" \
    -c:v libx264 -preset medium -crf 28 -movflags +faststart "$DIR/trailer-preview.mp4"

  local i T
  for i in $(seq 1 "$KEYFRAMES"); do
    T=$(python3 -c "print(($i - 0.5) * $DURATION / $KEYFRAMES)")
    limit 60 ffmpeg -hide_banner -loglevel error -y -ss "$T" -i "$DIR/trailer.mp4" -frames:v 1 \
      "$DIR/frames/frame-$(printf '%02d' "$i").png" || true
  done

  write_voiceover "$DIR"

  rm -f "$RAW"
  ffprobe -v error -show_entries format=duration:stream=width,height,r_frame_rate -of default=nw=1 "$DIR/trailer.mp4"
  ls -la "$DIR" "$DIR/frames"
}

for ASPECT in $ASPECTS; do
  case "$ASPECT" in
    9x16) record_aspect 9x16 16 9 1080 1920 540 960 ;;
    3x4)  record_aspect 3x4 4 3 1080 1440 540 720 ;;
  esac
  sleep 5
done

echo
echo "完成 / Done. 输出 / Output:"
for ASPECT in $ASPECTS; do
  echo "  $OUT/$ASPECT/trailer.mp4           (成片 / final)"
  echo "  $OUT/$ASPECT/trailer-preview.mp4   (预览 / preview)"
  echo "  $OUT/$ASPECT/frames/               ($KEYFRAMES 张关键帧 / keyframes)"
  echo "  $OUT/$ASPECT/voiceover.srt         (旁白字幕，可导入剪映 / voice-over subtitles)"
  echo "  $OUT/$ASPECT/voiceover.txt         (旁白稿 / voice-over script)"
done

# Show the folder when a person ran this on their Mac (never in CI).
if [ -z "${CI:-}" ] && [ -t 1 ] && [ "$(uname -s)" = "Darwin" ] && command -v open >/dev/null 2>&1; then
  open "$OUT" || true
fi
