/** showcase.finance-card · 资产卡片 (Life+FinanceCard.swift) */
import { animate, motion, useMotionValue, useMotionValueEvent } from "motion/react";
import { ArrowDownRight, ArrowUpRight, CreditCard, Nfc, RefreshCw } from "lucide-react";
import { useEffect, useRef, useState } from "react";
import { DemoHint, NumericText, Palette, anim, delayed, fonts, spring, useAutoplay, useHaptics, white, type DemoProps } from "../../kit";
import { Signature, SignatureRim, SignatureStage, signatureCard, signatureEyebrow, signatureNumber } from "./signature";
import { SportEyebrowRow, SportLiveDot } from "./_a-sport";

const RANGES = [
  { en: "1D", zh: "1天", change: 1.2 },
  { en: "1W", zh: "1周", change: 3.8 },
  { en: "1M", zh: "1月", change: -2.1 },
  { en: "1Y", zh: "1年", change: 18.6 },
];
const SW = 264;
const SH = 64;
const CARD_W = 300;
const CARD_H = 236;
const TRACK_W = CARD_W - 36;
const CHIP_W = (TRACK_W - 6 - 12) / 4;

/** Deterministic 0…1 series: a trend plus hashed wiggle, ending where the trend points. */
function series(r: number) {
  const trend = RANGES[r].change / 20;
  return Array.from({ length: 32 }, (_, i) => {
    const t = i / 31;
    const n = Math.sin((i + r * 40) * 12.9898 + 78.233) * 43758.5453;
    const wiggle = (n - Math.floor(n) - 0.5) * 0.22;
    const wave = Math.sin(t * Math.PI * (2.5 + r)) * 0.08;
    return 0.5 + trend * (t - 0.5) * 1.6 + wiggle * (0.4 + 0.6 * t) + wave;
  });
}

type P = { x: number; y: number };
/** Midpoint-quadratic smoothed line as a dense polyline with cumulative length (for trimming). */
function geometry(r: number) {
  const values = series(r);
  const lo = Math.min(...values);
  const hi = Math.max(...values);
  const span = Math.max(hi - lo, 0.0001);
  const pts = values.map((v, i) => ({ x: (SW * i) / (values.length - 1), y: SH * (0.1 + 0.8 * (1 - (v - lo) / span)) }));
  const poly: P[] = [pts[0]];
  let cur = pts[0];
  for (let i = 1; i < pts.length; i++) {
    const c = pts[i - 1];
    const mid = { x: (c.x + pts[i].x) / 2, y: (c.y + pts[i].y) / 2 };
    for (let k = 1; k <= 8; k++) {
      const t = k / 8;
      const u = 1 - t;
      poly.push({ x: u * u * cur.x + 2 * u * t * c.x + t * t * mid.x, y: u * u * cur.y + 2 * u * t * c.y + t * t * mid.y });
    }
    cur = mid;
  }
  poly.push(pts[pts.length - 1]);
  const cum = [0];
  for (let i = 1; i < poly.length; i++) cum.push(cum[i - 1] + Math.hypot(poly[i].x - poly[i - 1].x, poly[i].y - poly[i - 1].y));
  return { poly, cum, total: cum[cum.length - 1] };
}
const GEOS = RANGES.map((_, r) => geometry(r));

function trim(r: number, f: number) {
  const { poly, cum, total } = GEOS[r];
  const L = Math.min(Math.max(f, 0.001), 1) * total;
  let i = 1;
  while (i < poly.length - 1 && cum[i] < L) i++;
  const seg = cum[i] - cum[i - 1] || 1;
  const k = Math.min(Math.max((L - cum[i - 1]) / seg, 0), 1);
  const tip = { x: poly[i - 1].x + (poly[i].x - poly[i - 1].x) * k, y: poly[i - 1].y + (poly[i].y - poly[i - 1].y) * k };
  let d = `M${poly[0].x},${poly[0].y}`;
  for (let j = 1; j < i; j++) d += ` L${poly[j].x.toFixed(2)},${poly[j].y.toFixed(2)}`;
  return { d: d + ` L${tip.x},${tip.y}`, tip };
}
const areaPath = (r: number) => {
  const { poly } = GEOS[r];
  return `M${poly[0].x},${poly[0].y} ` + poly.slice(1).map((p) => `L${p.x.toFixed(2)},${p.y.toFixed(2)}`).join(" ") + ` L${SW},${SH} L0,${SH} Z`;
};

export default function FinanceCard({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const zh = ctx.lang === "zh";
  const base = zh ? 176240.18 : 24815.42;
  const [range, setRange] = useState(1);
  const rangeRef = useRef(1);
  const [balance, setBalance] = useState(base);
  useEffect(() => setBalance(base), [base]);
  const drawnMV = useMotionValue(0);
  const [drawn, setDrawn] = useState(0);
  useMotionValueEvent(drawnMV, "change", setDrawn);
  const angleMV = useMotionValue(0);
  const [angle, setAngle] = useState(0);
  useMotionValueEvent(angleMV, "change", setAngle);
  const angleTarget = useRef(0);
  const step = useRef(0);

  const redraw = () => {
    drawnMV.stop();
    drawnMV.set(0);
    animate(drawnMV, 1, delayed(anim.easeOut(ctx.n("draw")), 0.05));
  };
  useEffect(() => {
    redraw();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const interval = Math.max(ctx.n("interval"), 0.5);
  useEffect(() => {
    const id = window.setInterval(() => {
      const n = Math.sin((Date.now() / 1000) * 7.3) * 43758.5453;
      const jitter = (n - Math.floor(n) - 0.4) * (zh ? 60 : 9);
      setBalance((b) => Math.max(0, b + Math.round(jitter * 100) / 100));
    }, interval * 1000);
    return () => clearInterval(id);
  }, [interval, zh]);

  const select = (r: number) => {
    if (r === rangeRef.current) return;
    haptics.selection();
    rangeRef.current = r;
    setRange(r);
    redraw();
  };
  const flip = () => {
    haptics.tap("medium");
    angleTarget.current += 180;
    animate(angleMV, angleTarget.current, spring(ctx.n("flip"), 0.78));
  };

  useAutoplay(
    ctx.isPreview,
    () => {
      const s = step.current % 4;
      if (s === 3 || (s === 0 && Math.round(angleTarget.current / 180) % 2 === 1)) flip();
      else select((rangeRef.current + 1) % 4);
      step.current += 1;
    },
    { every: 1.8, delay: 1.0, intro: false },
  );

  const wrapped = ((angle % 360) + 360) % 360;
  const showsBack = wrapped > 90 && wrapped < 270;
  const change = RANGES[range].change;
  const up = change >= 0;
  const tint = up ? Signature.accent : Palette.coral;
  const tintRGB = up ? "255 138 31" : "255 122 92";
  const { d, tip } = trim(range, drawn);
  const money = (zh ? "¥" : "$") + balance.toLocaleString("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 });

  return (
    <SignatureStage>
      <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center" }}>
        <div style={{ flex: 1 }} />
        <div
          onClick={flip}
          style={{ position: "relative", width: CARD_W, height: CARD_H, flexShrink: 0, cursor: "pointer", transform: `perspective(${CARD_W / 0.45}px) rotateY(${angle}deg)` }}
        >
          {/* front */}
          <div style={{ ...signatureCard(), position: "absolute", inset: 0, padding: 18, display: "flex", flexDirection: "column", gap: 10, opacity: showsBack ? 0 : 1 }}>
            <div style={{ display: "flex", alignItems: "center" }}>
              <SportEyebrowRow title={ctx.t("Total balance", "总资产")} icon={<CreditCard size={11} fill="currentColor" stroke={Signature.card} strokeWidth={1.5} />} />
              <span style={{ color: Signature.textSecondary, display: "grid" }}>
                <RefreshCw size={11} strokeWidth={3} />
              </span>
            </div>
            <div style={{ display: "flex", alignItems: "baseline", gap: 10 }}>
              <span style={{ ...signatureNumber(30), color: "#fff", lineHeight: "36px", whiteSpace: "nowrap" }}>
                <NumericText value={balance} text={money} />
              </span>
              <motion.span
                initial={false}
                animate={{ backgroundColor: up ? Signature.lime : Palette.coral }}
                transition={anim.easeInOut(0.3)}
                style={{ display: "inline-flex", alignItems: "center", gap: 3, padding: "3px 7px", borderRadius: 99, color: "#000", fontFamily: fonts.rounded, fontSize: 11, fontWeight: 700, fontVariantNumeric: "tabular-nums", lineHeight: "13px", alignSelf: "center" }}
              >
                {up ? <ArrowUpRight size={10} strokeWidth={3.4} /> : <ArrowDownRight size={10} strokeWidth={3.4} />}
                <NumericText value={change} text={Math.abs(change).toFixed(1)} />
                <span>%</span>
              </motion.span>
            </div>
            <div style={{ position: "relative", width: SW, height: SH }}>
              <svg width={SW} height={SH} style={{ position: "absolute", inset: 0, overflow: "visible" }}>
                <defs>
                  <linearGradient id="finance-fill" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="0" stopColor={tint} stopOpacity={0.35} />
                    <stop offset="1" stopColor={tint} stopOpacity={0} />
                  </linearGradient>
                  <clipPath id="finance-clip">
                    <rect x={0} y={-10} width={SW * drawn} height={SH + 20} />
                  </clipPath>
                </defs>
                <path d={areaPath(range)} fill="url(#finance-fill)" clipPath="url(#finance-clip)" />
              </svg>
              <svg width={SW} height={SH} style={{ position: "absolute", inset: 0, overflow: "visible", filter: `drop-shadow(0 0 5px rgb(${tintRGB} / 0.6))` }}>
                <path d={d} fill="none" stroke={tint} strokeWidth={2.2} strokeLinecap="round" strokeLinejoin="round" />
              </svg>
              <div style={{ position: "absolute", left: tip.x - 10.5, top: tip.y - 10.5, opacity: Math.min(Math.max(drawn * 12, 0), 1) }}>
                <SportLiveDot color={tint} size={7} preview={ctx.isPreview} />
              </div>
            </div>
            <div style={{ position: "relative", display: "flex", gap: 4, padding: 3, borderRadius: 99, background: white(0.06) }} onClick={(e) => e.stopPropagation()}>
              <motion.div
                initial={false}
                animate={{ x: range * (CHIP_W + 4) }}
                transition={spring(0.4, 0.8)}
                style={{ position: "absolute", left: 3, top: 3, width: CHIP_W, height: 28, borderRadius: 99, background: Signature.lime }}
              />
              {RANGES.map((r, i) => (
                <button
                  key={i}
                  type="button"
                  onClick={() => select(i)}
                  style={{ position: "relative", flex: 1, height: 28, fontFamily: fonts.rounded, fontSize: 12, fontWeight: 600, color: i === range ? "#000" : Signature.textSecondary, transition: "color 0.3s" }}
                >
                  {zh ? r.zh : r.en}
                </button>
              ))}
            </div>
            <SignatureRim />
          </div>
          {/* back */}
          <div style={{ position: "absolute", inset: 0, transform: "rotateY(180deg)", opacity: showsBack ? 1 : 0, pointerEvents: showsBack ? "auto" : "none" }}>
            <div style={{ ...signatureCard(), position: "absolute", inset: 0 }}>
              <div style={{ position: "absolute", inset: 0, borderRadius: 26, overflow: "hidden", display: "flex", flexDirection: "column" }}>
                <div style={{ height: 40, marginTop: 26, background: Signature.accentGradient, flexShrink: 0 }} />
                <div style={{ padding: "26px 20px 0", fontFamily: fonts.mono, fontSize: 17, fontWeight: 600, color: "#fff", lineHeight: "21px" }}>•••• •••• •••• 4821</div>
                <div style={{ padding: "18px 20px 0", display: "flex", alignItems: "center", gap: 22 }}>
                  {[
                    [zh ? "有效期" : "Expires", "08/29"],
                    ["CVV", "•••"],
                  ].map(([t, v]) => (
                    <div key={t} style={{ display: "flex", flexDirection: "column", gap: 2 }}>
                      <span style={signatureEyebrow()}>{t}</span>
                      <span style={{ fontFamily: fonts.mono, fontSize: 14, fontWeight: 600, color: "#fff", lineHeight: "17px" }}>{v}</span>
                    </div>
                  ))}
                  <span style={{ flex: 1 }} />
                  <span style={{ color: Signature.textSecondary, display: "grid" }}>
                    <Nfc size={20} strokeWidth={2.2} />
                  </span>
                </div>
                <span style={{ flex: 1 }} />
                <span style={{ ...signatureEyebrow(), textAlign: "center", paddingBottom: 16 }}>{zh ? "点击翻回正面" : "Tap to flip back"}</span>
              </div>
              <SignatureRim />
            </div>
          </div>
        </div>
        <div style={{ flex: 1 }} />
        <DemoHint ctx={ctx} en="Pick a range · tap the card to flip" zh="选择时间范围 · 点击卡片翻面" style={{ paddingBottom: 14 }} />
      </div>
    </SignatureStage>
  );
}
