/** showcase.best-line · 最佳路线 (Sport+BestLine.swift) */
import { animate, motion, useMotionValue, useMotionValueEvent } from "motion/react";
import { ArrowDownRight, Route } from "lucide-react";
import { useEffect, useRef, useState } from "react";
import { DemoHint, anim, clamp, fonts, spring, useAutoplay, useHaptics, usePan, white, type DemoProps } from "../../kit";
import { Signature, SignatureRim, SignatureStage, signatureCard, signatureNumber } from "./signature";
import { SportEyebrowRow } from "./_a-sport";

const W = 252;
const H = 132;
const TOP = 2256;
const BOTTOM = 860;
const DISTANCE = 1.4;

type P = { x: number; y: number };
const bez = (a: P, b: P, c: P, d: P, t: number): P => {
  const u = 1 - t;
  return {
    x: u * u * u * a.x + 3 * u * u * t * b.x + 3 * u * t * t * c.x + t * t * t * d.x,
    y: u * u * u * a.y + 3 * u * u * t * b.y + 3 * u * t * t * c.y + t * t * t * d.y,
  };
};
const q = (x: number, y: number): P => ({ x: W * x, y: H * y });
const SEGMENTS: [P, P, P, P][] = [
  [q(0.04, 0.1), q(0.22, 0.04), q(0.1, 0.4), q(0.36, 0.42)],
  [q(0.36, 0.42), q(0.58, 0.44), q(0.42, 0.68), q(0.62, 0.6)],
  [q(0.62, 0.6), q(0.82, 0.52), q(0.72, 0.9), q(0.96, 0.92)],
];
const FULL_D = `M${SEGMENTS[0][0].x},${SEGMENTS[0][0].y} ` + SEGMENTS.map(([, b, c, d]) => `C${b.x},${b.y} ${c.x},${c.y} ${d.x},${d.y}`).join(" ");

/** Dense polyline with cumulative arc length, for `trimmedPath(from: 0, to: f)`. */
const POLY: P[] = [];
SEGMENTS.forEach((s, k) => {
  for (let i = k === 0 ? 0 : 1; i <= 200; i++) POLY.push(bez(s[0], s[1], s[2], s[3], i / 200));
});
const CUM: number[] = [0];
for (let i = 1; i < POLY.length; i++) CUM.push(CUM[i - 1] + Math.hypot(POLY[i].x - POLY[i - 1].x, POLY[i].y - POLY[i - 1].y));
const TOTAL = CUM[CUM.length - 1];

function locate(f: number): { i: number; p: P } {
  const L = clamp(f) * TOTAL;
  let lo = 0;
  let hi = CUM.length - 1;
  while (lo < hi - 1) {
    const mid = (lo + hi) >> 1;
    if (CUM[mid] <= L) lo = mid;
    else hi = mid;
  }
  const seg = CUM[hi] - CUM[lo] || 1;
  const r = clamp((L - CUM[lo]) / seg);
  return { i: lo, p: { x: POLY[lo].x + (POLY[hi].x - POLY[lo].x) * r, y: POLY[lo].y + (POLY[hi].y - POLY[lo].y) * r } };
}
const pointAt = (f: number) => locate(Math.max(f, 0.001)).p;
function trimmed(f: number): string {
  if (f <= 0) return "";
  const { i, p } = locate(f);
  let d = `M${POLY[0].x},${POLY[0].y}`;
  for (let k = 1; k <= i; k++) d += ` L${POLY[k].x.toFixed(2)},${POLY[k].y.toFixed(2)}`;
  return d + ` L${p.x},${p.y}`;
}

const SAMPLES = Array.from({ length: 161 }, (_, i) => ({ f: i / 160, x: pointAt(i / 160).x }));
function fractionNearestX(x: number) {
  let best = { f: 0, d: Infinity };
  for (const s of SAMPLES) {
    const d = Math.abs(s.x - x);
    if (d < best.d) best = { f: s.f, d };
  }
  return best.f;
}
const PROFILE = Array.from({ length: 61 }, (_, i) => clamp((pointAt(i / 60).y / H - 0.1) / 0.82));
const PW = W;
const PH = 26;
const PROFILE_D =
  `M0,${PH} ` + PROFILE.map((v, i) => `L${(PW * i) / 60},${PH * (0.1 + 0.85 * v)}`).join(" ") + ` L${PW},${PH} Z`;

/** `RidgeShape(seed: 3, baseline: 0.62, amplitude: 0.34)` in the route's frame. */
const RIDGE = (() => {
  const pts = [`0,${H}`];
  for (let i = 0; i <= 9; i++) {
    const n = Math.sin(3 * 12.9898 + i * 78.233) * 43758.5453;
    const j = n - Math.floor(n);
    const y = 0.62 - 0.34 * (i % 2 === 0 ? j * 0.5 : 0.6 + j * 0.4);
    pts.push(`${(W * i) / 9},${H * y}`);
  }
  pts.push(`${W},${H}`);
  return pts.join(" ");
})();

export default function BestLine({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const progressMV = useMotionValue(0);
  const ghostMV = useMotionValue(0);
  const [progress, setProgress] = useState(0);
  const [ghost, setGhost] = useState(0);
  useMotionValueEvent(progressMV, "change", setProgress);
  useMotionValueEvent(ghostMV, "change", setGhost);
  const [runID, setRunID] = useState(0);
  const scrubEpoch = useRef(0);
  const [pressed, setPressed] = useState(false);
  const dragged = useRef(false);

  const duration = ctx.n("duration");
  useEffect(() => {
    const silent = runID === 0;
    const epoch = scrubEpoch.current;
    let cancelled = false;
    progressMV.stop();
    ghostMV.stop();
    progressMV.set(0);
    ghostMV.set(0);
    const t1 = window.setTimeout(() => {
      if (cancelled) return;
      animate(progressMV, 1, anim.easeInOut(duration));
      animate(ghostMV, 1, anim.easeInOut(duration * Math.max(ctx.n("ghost"), 1)));
    }, 200);
    const t2 = window.setTimeout(() => {
      if (!cancelled && !silent && epoch === scrubEpoch.current) haptics.success();
    }, 200 + duration * 1000);
    return () => {
      cancelled = true;
      clearTimeout(t1);
      clearTimeout(t2);
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [runID]);

  useAutoplay(ctx.isPreview, () => setRunID((r) => r + 1), { every: duration + 1.8, delay: duration + 1.8, intro: false });

  const pan = usePan(
    {
      onStart: () => {
        dragged.current = true;
        setPressed(false);
      },
      onChange: ({ location }) => {
        scrubEpoch.current += 1;
        const x = clamp(location.x - 20, 0, W);
        const target = fractionNearestX(x);
        animate(progressMV, target, spring(0.3, 0.75));
        animate(ghostMV, target, spring(0.6, 0.8));
      },
    },
    6,
  );

  const p = clamp(progress);
  const head = pointAt(p);
  const ghostHead = pointAt(ghost);
  const fall = clamp((head.y / H - 0.1) / 0.82);
  const elevation = Math.trunc(TOP - (TOP - BOTTOM) * fall);
  const cursorX = PW * p;

  return (
    <SignatureStage>
      <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center" }}>
        <div style={{ flex: 1 }} />
        <motion.div animate={{ scale: pressed ? 0.98 : 1, filter: `brightness(${pressed ? 0.96 : 1})` }} transition={spring(0.3, 0.7)} style={{ borderRadius: 26 }}>
          <div
            {...pan}
            onPointerDown={(e) => {
              dragged.current = false;
              setPressed(true);
              pan.onPointerDown(e);
            }}
            onPointerUp={(e) => {
              setPressed(false);
              pan.onPointerUp(e);
            }}
            onPointerCancel={(e) => {
              setPressed(false);
              pan.onPointerCancel(e);
            }}
            onClick={() => {
              if (dragged.current) return;
              setRunID((r) => r + 1);
            }}
            style={{ ...signatureCard(), padding: 20, width: 292, display: "flex", flexDirection: "column", gap: 12, touchAction: "none", cursor: "pointer" }}
          >
            <SportEyebrowRow title={ctx.t("Best line", "最佳路线")} icon={<Route size={11} strokeWidth={2.6} />} trailing="Nordkette" />
            <div style={{ position: "relative", width: W, height: H }}>
              <svg width={W} height={H} style={{ position: "absolute", inset: 0, overflow: "visible" }}>
                <defs>
                  <linearGradient id="best-ridge" gradientUnits="userSpaceOnUse" x1="0" y1="0" x2="0" y2={H}>
                    <stop offset="0" stopColor="#fff" stopOpacity={0.06} />
                    <stop offset="1" stopColor="#fff" stopOpacity={0} />
                  </linearGradient>
                  <linearGradient id="best-trail" gradientUnits="userSpaceOnUse" x1="0" y1="0" x2={W} y2={H}>
                    <stop offset="0" stopColor={Signature.accentSoft} />
                    <stop offset="0.5" stopColor={Signature.accent} />
                    <stop offset="1" stopColor={Signature.accentHot} />
                  </linearGradient>
                </defs>
                <polygon points={RIDGE} fill="url(#best-ridge)" />
                <path d={FULL_D} fill="none" stroke={white(0.14)} strokeWidth={1.5} strokeLinecap="round" strokeDasharray="2 6" />
              </svg>
              <svg width={W} height={H} style={{ position: "absolute", inset: 0, overflow: "visible", filter: "drop-shadow(0 0 8px rgb(255 138 31 / 0.7))" }}>
                <path d={trimmed(p)} fill="none" stroke="url(#best-trail)" strokeWidth={ctx.n("width")} strokeLinecap="round" strokeLinejoin="round" />
              </svg>
              <Ghost at={ghostHead} />
              <div style={{ position: "absolute", left: head.x - 11, top: head.y - 11, width: 22, height: 22, display: "grid", placeItems: "center" }}>
                <div style={{ position: "absolute", inset: 0, borderRadius: "50%", background: "rgb(255 138 31 / 0.3)" }} />
                <div style={{ position: "relative", width: 10, height: 10, borderRadius: "50%", background: "#fff", boxShadow: `0 0 6px ${Signature.accent}` }} />
              </div>
              {ctx.b("elevation") && (
                <div style={{ position: "absolute", left: clamp(head.x, 34, W - 34), top: Math.max(head.y - 24, 10), width: 0, height: 0 }}>
                  <div
                    style={{
                      position: "absolute",
                      transform: "translate(-50%, -50%)",
                      whiteSpace: "nowrap",
                      fontFamily: fonts.rounded,
                      fontSize: 10,
                      fontWeight: 700,
                      fontVariantNumeric: "tabular-nums",
                      lineHeight: "12px",
                      color: "#000",
                      padding: "3px 7px",
                      borderRadius: 999,
                      background: "#fff",
                      boxShadow: "0 2px 5px rgb(0 0 0 / 0.35)",
                    }}
                  >
                    {elevation.toLocaleString("en-US")} m
                  </div>
                </div>
              )}
            </div>
            <div style={{ position: "relative", width: PW, height: PH }}>
              <svg width={PW} height={PH} style={{ position: "absolute", inset: 0 }}>
                <defs>
                  <linearGradient id="best-profile" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="0" stopColor={Signature.accent} stopOpacity={0.55} />
                    <stop offset="1" stopColor={Signature.accent} stopOpacity={0.08} />
                  </linearGradient>
                  <clipPath id="best-profile-clip">
                    <rect x={0} y={0} width={cursorX} height={PH} />
                  </clipPath>
                </defs>
                <path d={PROFILE_D} fill={white(0.07)} />
                <path d={PROFILE_D} fill="url(#best-profile)" clipPath="url(#best-profile-clip)" />
              </svg>
              <div style={{ position: "absolute", left: cursorX, top: 0, width: 1, height: PH, background: white(0.8) }} />
            </div>
            <div style={{ display: "flex", alignItems: "baseline", gap: 4 }}>
              <span style={{ ...signatureNumber(34), color: "#fff", lineHeight: "41px" }}>{(DISTANCE * p).toFixed(1)}</span>
              <span style={{ fontFamily: fonts.rounded, fontSize: 13, fontWeight: 600, color: Signature.textSecondary }}>km</span>
              <span style={{ flex: 1 }} />
              <span style={{ color: Signature.accent, display: "inline-grid", alignSelf: "center", marginTop: 8 }}>
                <ArrowDownRight size={12} strokeWidth={3} />
              </span>
              <span style={{ fontFamily: fonts.rounded, fontSize: 13, fontWeight: 600, fontVariantNumeric: "tabular-nums", color: white(0.8) }}>
                {(TOP - elevation).toLocaleString("en-US")} m
              </span>
              <span style={{ fontFamily: fonts.rounded, fontSize: 11, fontWeight: 500, color: Signature.textSecondary }}>{ctx.t("drop", "落差")}</span>
            </div>
            <SignatureRim />
          </div>
        </motion.div>
        <div style={{ flex: 1 }} />
        <DemoHint ctx={ctx} en="Tap to replay, drag to scrub" zh="点击重播，拖动查看" style={{ paddingBottom: 16 }} />
      </div>
    </SignatureStage>
  );
}

function Ghost({ at }: { at: P }) {
  return (
    <div style={{ position: "absolute", left: at.x - 7, top: at.y - 7, width: 14, height: 14, pointerEvents: "none" }}>
      <svg width={14} height={14} style={{ position: "absolute", inset: 0 }}>
        <circle cx={7} cy={7} r={6.25} fill="none" stroke={white(0.55)} strokeWidth={1.5} strokeDasharray="2 2" />
      </svg>
      <span
        style={{
          position: "absolute",
          left: "50%",
          top: 7 + 12,
          transform: "translate(-50%, -50%)",
          fontFamily: fonts.rounded,
          fontSize: 7,
          fontWeight: 800,
          lineHeight: "9px",
          color: white(0.7),
        }}
      >
        PB
      </span>
    </div>
  );
}
