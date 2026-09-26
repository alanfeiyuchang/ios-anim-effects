/** icons.download · 下载 → 完成 (Icons+Download.swift) */
import { animate, motion, useMotionValue, useMotionValueEvent, useTransform, type MotionValue } from "motion/react";
import { useRef, useState } from "react";
import { DemoHint, Palette, alpha, demoCard, spring, textStyle, useAutoplay, useHaptics, useTimeouts, type DemoProps } from "../../kit";
import { BOUNCE_DURATION, Glyph, Replace, bounceAt, rrect, sym, useSince, type GlyphDef } from "./_icons-kit";

type State = "idle" | "downloading" | "done";

const DOC_ZIPPER: GlyphDef = [
  { d: "M6.2 2h7.6L19.5 7.7V20a2 2 0 0 1-2 2H6.2a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2ZM13.6 2.2V6.4a1.4 1.4 0 0 0 1.4 1.4h4.3", mode: "stroke", sw: 1.8 },
  { d: "M9.3 3.2h2M10.6 5.2h2M9.3 7.2h2M10.6 9.2h2M9.3 11.2h2", mode: "stroke", sw: 1.6 },
  { d: rrect(9.1, 13, 3.8, 5.2, 1.2), mode: "fill", sw: 0.6 },
];
const ARROW_DOWN: GlyphDef = [{ d: "M12 3.5v16.5M5.2 13.4 12 20.2l6.8-6.8", mode: "stroke", sw: 2.6 }];
const STOP_FILL: GlyphDef = [{ d: rrect(4.5, 4.5, 15, 15, 2.8), mode: "solid" }];
const CHECKMARK: GlyphDef = [{ d: "M4.2 12.8 9.6 18.2 19.8 6", mode: "stroke", sw: 2.7 }];

export default function Download({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const { after, clearAll } = useTimeouts();
  const [state, setState] = useState<State>("idle");
  const [doneCount, setDoneCount] = useState(0);
  const [percent, setPercent] = useState(0);
  const trim = useMotionValue(0);
  const run = useRef(0);
  const stateRef = useRef<State>("idle");
  stateRef.current = state;
  useMotionValueEvent(trim, "change", (v) => setPercent(Math.round(v * 100)));

  const start = (silent: boolean) => {
    run.current += 1;
    const current = run.current;
    const duration = ctx.n("duration");
    setState("downloading");
    if (!silent) haptics.tap("light");
    trim.set(0);
    after(0.08, () => {
      if (current !== run.current) return;
      animate(trim, 1, { type: "tween", duration, ease: [0.42, 0, 0.58, 1] }).then(() => {
        if (current !== run.current) return;
        setState("done");
        animate(trim, 0, spring(0.4, 0.6));
        setDoneCount((n) => n + 1);
        if (!silent) haptics.success();
      });
    });
  };

  const tap = (silent = false) => {
    if (stateRef.current === "idle") {
      start(silent);
    } else {
      run.current += 1;
      clearAll();
      setState("idle");
      stateRef.current = "idle";
      animate(trim, 0, spring(0.45, 0.8));
    }
  };

  useAutoplay(
    ctx.isPreview,
    () => {
      if (stateRef.current === "done") {
        tap(true);
        after(0.5, () => tap(true));
      } else tap(true);
    },
    { every: ctx.n("duration") + 1.4, delay: 0.3 },
  );

  const zh = ctx.lang === "zh";
  let caption;
  if (state === "idle") caption = <span style={{ ...textStyle.subheadline, color: Palette.secondaryLabel }}>248 MB</span>;
  else if (state === "downloading")
    caption = ctx.b("percent") ? (
      <span style={{ ...textStyle.subheadline, fontWeight: 600, color: Palette.blue, fontVariantNumeric: "tabular-nums" }}>{percent}%</span>
    ) : (
      <span style={{ ...textStyle.subheadline, color: Palette.secondaryLabel }}>{zh ? "下载中…" : "Downloading…"}</span>
    );
  else caption = <span style={{ ...textStyle.subheadline, fontWeight: 600, color: Palette.green }}>{zh ? "已完成 · 打开" : "Ready · Open"}</span>;

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 18 }}>
      <div style={{ ...demoCard(22), width: 300, padding: 16, display: "flex", alignItems: "center", gap: 14 }}>
        <div style={{ width: 48, height: 48, borderRadius: 12, background: alpha(Palette.blue, 0.12), display: "grid", placeItems: "center", color: Palette.blue, flexShrink: 0 }}>
          <Glyph def={DOC_ZIPPER} size={sym(24)} />
        </div>
        <div style={{ display: "flex", flexDirection: "column", gap: 3 }}>
          <span style={{ ...textStyle.headline }}>{zh ? "设计素材.zip" : "Design-Assets.zip"}</span>
          {caption}
        </div>
        <div style={{ flex: 1 }} />
        <DownloadButton state={state} trim={trim} lineWidth={ctx.n("ring")} doneCount={doneCount} onTap={() => tap()} />
      </div>
      <DemoHint ctx={ctx} en="Tap the button" zh="点击按钮" />
    </div>
  );
}

function DownloadButton({
  state,
  trim,
  lineWidth,
  doneCount,
  onTap,
}: {
  state: State;
  trim: MotionValue<number>;
  lineWidth: number;
  doneCount: number;
  onTap: () => void;
}) {
  const t = useSince(doneCount, BOUNCE_DURATION);
  const visible = useTransform(trim, (v) => (v > 0.01 ? 1 : 0));
  const b = bounceAt(t);
  const def = state === "idle" ? ARROW_DOWN : state === "downloading" ? STOP_FILL : CHECKMARK;
  const size = state === "downloading" ? sym(14) : sym(20);
  return (
    <button type="button" onClick={onTap} style={{ position: "relative", width: 52, height: 52, flexShrink: 0 }}>
      <motion.div
        initial={false}
        animate={{ backgroundColor: state === "done" ? Palette.green : alpha(Palette.blue, 0.12) }}
        transition={spring(0.4, 0.6)}
        style={{ position: "absolute", inset: 0, borderRadius: "50%" }}
      />
      <svg width={52} height={52} viewBox="0 0 52 52" style={{ position: "absolute", inset: 0, overflow: "visible" }}>
        <defs>
          <linearGradient id="download-ocean" x1="0" y1="0" x2="1" y2="1">
            <stop offset="0" stopColor={Palette.sky} />
            <stop offset="1" stopColor={Palette.blue} />
          </linearGradient>
        </defs>
        <circle cx={26} cy={26} r={26} fill="none" stroke={alpha(Palette.blue, state === "downloading" ? 0.18 : 0)} strokeWidth={lineWidth} style={{ transition: "stroke 0.3s" }} />
        <motion.circle
          cx={26}
          cy={26}
          r={26}
          fill="none"
          stroke="url(#download-ocean)"
          strokeWidth={lineWidth}
          strokeLinecap="round"
          transform="rotate(-90 26 26)"
          style={{ pathLength: trim, opacity: visible }}
        />
      </svg>
      <div style={{ position: "absolute", inset: 0, display: "grid", placeItems: "center" }}>
        <div style={{ transform: `translateY(${b.y * 20}px) scale(${b.scale})` }}>
          <Replace k={state}>
            <div style={{ color: state === "done" ? "#fff" : Palette.blue, transition: "color 0.3s" }}>
              <Glyph def={def} size={size} />
            </div>
          </Replace>
        </div>
      </div>
    </button>
  );
}
