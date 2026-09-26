/** showcase.weather-widget · 山顶天气组件 (Sport+WeatherWidget.swift) */
import { AnimatePresence, LayoutGroup, motion } from "motion/react";
import { useRef, useState } from "react";
import { DemoHint, NumericText, anim, fonts, spring, useAutoplay, useHaptics, useTimeouts, white, type DemoProps } from "../../kit";
import { Signature, SignatureRim, SignatureStage, signatureCard, signatureNumber } from "./signature";
import { CanvasLayer, MountainGlyph, SportEyebrowRow, SportPress, sportHash } from "./_a-sport";

const HOURS = [
  { label: ["Now", "现在"], temp: -6, kind: 0 },
  { label: ["11:00", "11:00"], temp: -3, kind: 1 },
  { label: ["12:00", "12:00"], temp: 1, kind: 2 },
  { label: ["13:00", "13:00"], temp: 3, kind: 2 },
  { label: ["14:00", "14:00"], temp: -1, kind: 1 },
];
const LOW = -6;
const HIGH = 3;
const BAR_W = 168;
const NAMES = [
  ["Light snow", "小雪"],
  ["Partly cloudy", "多云间晴"],
  ["Bluebird sky", "晴朗无云"],
];
/** Palette layers: for clouds the first colour is the cloud, the second the snow / sun. */
const COLORS: [string, string][] = [
  ["#FFFFFF", "#8FD3FF"],
  ["#FFFFFF", Signature.accent],
  [Signature.accent, Signature.accentSoft],
];
const SHADOWS = ["rgb(143 211 255 / 0.5)", "rgb(255 138 31 / 0.5)", "rgb(255 180 92 / 0.5)"];

export default function WeatherWidget({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const { after } = useTimeouts();
  const [selected, setSelected] = useState(0);
  const selectedRef = useRef(0);
  const [fadingKind, setFadingKind] = useState<number | null>(null);
  const fadeID = useRef(0);
  const hour = HOURS[selected];
  const zh = ctx.lang === "zh";
  const display = (c: number) => (ctx.i("unit") === 1 ? Math.round((c * 9) / 5 + 32) : c);

  const select = (index: number) => {
    if (index === selectedRef.current) return;
    haptics.selection();
    const outgoing = HOURS[selectedRef.current].kind;
    if (HOURS[index].kind !== outgoing) {
      setFadingKind(outgoing);
      const id = ++fadeID.current;
      after(0.65, () => id === fadeID.current && setFadingKind(null));
    }
    selectedRef.current = index;
    setSelected(index);
  };

  useAutoplay(ctx.isPreview, () => select((selectedRef.current + 1) % HOURS.length), { every: 1.6, delay: 0.6 });

  const t = spring(ctx.n("response"), ctx.n("damping"));
  const fraction = (hour.temp - LOW) / (HIGH - LOW);
  const [c1, c2] = COLORS[hour.kind];
  const density = ctx.i("density");

  return (
    <SignatureStage>
      <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center" }}>
        <div style={{ flex: 1 }} />
        <div style={{ ...signatureCard(), padding: 18, width: 292, display: "flex", flexDirection: "column", gap: 14 }}>
          <div style={{ position: "absolute", inset: 0, borderRadius: 26, overflow: "hidden" }}>
            {[0, 1, 2].map((kind) => (
              <motion.div
                key={kind}
                initial={false}
                animate={{ opacity: hour.kind === kind ? 1 : 0 }}
                transition={anim.easeInOut(0.6)}
                style={{ position: "absolute", inset: 0 }}
              >
                <CanvasLayer
                  fps={ctx.isPreview ? 30 : undefined}
                  running={hour.kind === kind || fadingKind === kind}
                  draw={(g, time, w, h) => (kind === 0 ? drawSnow(g, w, h, time, density) : kind === 1 ? drawClouds(g, w, h, time) : drawSun(g, w, h, time))}
                />
              </motion.div>
            ))}
          </div>
          <SportEyebrowRow title={ctx.t("Summit weather", "山顶天气")} icon={<MountainGlyph size={10} />} trailing="Nordkette" style={{ position: "relative" }} />
          <div style={{ position: "relative", display: "flex", alignItems: "center" }}>
            <div style={{ display: "flex", flexDirection: "column", gap: 2 }}>
              <span style={{ ...signatureNumber(52), color: "#fff", lineHeight: "62px" }}>
                <NumericText value={hour.temp} text={`${display(hour.temp)}°`} />
              </span>
              <div style={{ position: "relative", height: 16 }}>
                <AnimatePresence initial={false}>
                  <motion.span
                    key={hour.kind}
                    initial={{ opacity: 0 }}
                    animate={{ opacity: 1 }}
                    exit={{ opacity: 0 }}
                    transition={t}
                    style={{ position: "absolute", left: 0, top: 0, whiteSpace: "nowrap", fontFamily: fonts.rounded, fontSize: 13, fontWeight: 600, color: Signature.textSecondary, lineHeight: "16px" }}
                  >
                    {NAMES[hour.kind][zh ? 1 : 0]}
                  </motion.span>
                </AnimatePresence>
              </div>
            </div>
            <span style={{ flex: 1 }} />
            <div style={{ width: 70, height: 60, display: "grid", placeItems: "center" }}>
              <AnimatePresence mode="popLayout" initial={false}>
                <motion.span
                  key={hour.kind}
                  initial={{ scale: 0.4, opacity: 0, filter: "blur(4px)" }}
                  animate={{ scale: 1, opacity: 1, filter: "blur(0px)" }}
                  exit={{ scale: 0.4, opacity: 0, filter: "blur(4px)" }}
                  transition={anim.snappyD(0.35)}
                  style={{ display: "grid", filter: `drop-shadow(0 0 10px ${SHADOWS[hour.kind]})` }}
                >
                  <WeatherGlyph kind={hour.kind} size={58} c1={c1} c2={c2} />
                </motion.span>
              </AnimatePresence>
            </div>
          </div>
          <div
            style={{
              position: "relative",
              display: "flex",
              alignItems: "center",
              gap: 10,
              fontFamily: fonts.rounded,
              fontSize: 11,
              fontWeight: 600,
              fontVariantNumeric: "tabular-nums",
              color: Signature.textSecondary,
            }}
          >
            <span>{display(LOW)}°</span>
            <div style={{ position: "relative", width: BAR_W, height: 12, flexShrink: 0 }}>
              <div
                style={{
                  position: "absolute",
                  left: 0,
                  right: 0,
                  top: 3.5,
                  height: 5,
                  borderRadius: 3,
                  opacity: 0.8,
                  background: `linear-gradient(90deg, #8FD3FF, ${Signature.accentSoft}, ${Signature.accent})`,
                }}
              />
              <motion.div
                initial={false}
                animate={{ x: fraction * (BAR_W - 12) }}
                transition={spring(ctx.n("response"), 0.6)}
                style={{ position: "absolute", left: 0, top: 0, width: 12, height: 12, borderRadius: "50%", background: "#fff", boxShadow: "0 1px 3px rgb(0 0 0 / 0.5)" }}
              />
            </div>
            <span>{display(HIGH)}°</span>
          </div>
          <LayoutGroup id={`weather-${ctx.isPreview ? "p" : "d"}`}>
            <div style={{ position: "relative", display: "flex", gap: 4 }}>
              {HOURS.map((item, index) => {
                const isSel = index === selected;
                const ink = isSel ? Signature.ink : "#fff";
                return (
                  <SportPress key={index} scale={0.94} dim={0} radius={16} onClick={() => select(index)} style={{ flex: 1, minWidth: 0 }}>
                    <div style={{ position: "relative", height: 68, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 6 }}>
                      {isSel ? (
                        <motion.div
                          layoutId="hour"
                          transition={t}
                          style={{ position: "absolute", inset: 0, borderRadius: 16, background: Signature.accentGradient, boxShadow: "0 3px 8px rgb(255 138 31 / 0.5)" }}
                        />
                      ) : (
                        <div style={{ position: "absolute", inset: 0, borderRadius: 16, background: white(0.04) }} />
                      )}
                      <span style={{ position: "relative", fontFamily: fonts.rounded, fontSize: 10, fontWeight: 700, lineHeight: "12px", color: isSel ? "rgb(11 11 13 / 0.7)" : Signature.textSecondary }}>
                        {item.label[zh ? 1 : 0]}
                      </span>
                      <span style={{ position: "relative", display: "grid" }}>
                        <WeatherGlyph kind={item.kind} size={18} c1={ink} c2={ink} />
                      </span>
                      <span style={{ position: "relative", fontFamily: fonts.rounded, fontSize: 12, fontWeight: 600, fontVariantNumeric: "tabular-nums", lineHeight: "14px", color: ink }}>
                        {display(item.temp)}°
                      </span>
                    </div>
                  </SportPress>
                );
              })}
            </div>
          </LayoutGroup>
          <SignatureRim />
        </div>
        <div style={{ flex: 1 }} />
        <DemoHint ctx={ctx} en="Tap an hour" zh="点击某个时段" style={{ paddingBottom: 14 }} />
      </div>
    </SignatureStage>
  );
}

const CLOUD = "M13 35 H34.5 A8 8 0 0 0 36 19.2 A11 11 0 0 0 15 16.8 A9.2 9.2 0 0 0 13 35 Z";

/** `cloud.snow.fill` / `cloud.sun.fill` / `sun.max.fill` with palette colours (c1 = cloud or sun, c2 = snow / sun / rays). */
function WeatherGlyph({ kind, size, c1, c2 }: { kind: number; size: number; c1: string; c2: string }) {
  const rays = (cx: number, cy: number, r0: number, r1: number, w: number, color: string) =>
    Array.from({ length: 8 }, (_, i) => {
      const a = (i / 8) * Math.PI * 2;
      return (
        <line key={i} x1={cx + Math.cos(a) * r0} y1={cy + Math.sin(a) * r0} x2={cx + Math.cos(a) * r1} y2={cy + Math.sin(a) * r1} stroke={color} strokeWidth={w} strokeLinecap="round" />
      );
    });
  return (
    <svg width={size} height={(size * 40) / 48} viewBox="0 0 48 40">
      {kind === 0 && (
        <>
          <path d={CLOUD} transform="translate(0 -6)" fill={c1} />
          {[
            [16, 35],
            [24, 37.5],
            [32, 35],
          ].map(([x, y], i) => (
            <circle key={i} cx={x} cy={y} r={2.2} fill={c2} />
          ))}
        </>
      )}
      {kind === 1 && (
        <>
          <circle cx={32} cy={13} r={6.5} fill={c2} />
          {rays(32, 13, 9.5, 12.5, 2.2, c2)}
          <path d={CLOUD} transform="translate(-4 1)" fill={c1} />
        </>
      )}
      {kind === 2 && (
        <>
          <circle cx={24} cy={20} r={8.5} fill={c1} />
          {rays(24, 20, 12.5, 17.5, 3, c2)}
        </>
      )}
    </svg>
  );
}

function drawSnow(g: CanvasRenderingContext2D, w: number, h: number, t: number, count: number) {
  const grad = g.createRadialGradient(w * 0.85, 0, 0, w * 0.85, 0, w * 0.9);
  grad.addColorStop(0, "rgb(143 211 255 / 0.14)");
  grad.addColorStop(1, "rgb(143 211 255 / 0)");
  g.fillStyle = grad;
  g.fillRect(0, 0, w, h);
  const span = h + 12;
  for (let i = 0; i < Math.max(count, 0); i++) {
    const s = i * 1.37;
    const speed = 12 + sportHash(s) * 24;
    const y = ((t * speed + sportHash(s + 3.1) * span) % span) - 6;
    const x = sportHash(s + 7.7) * w + Math.sin(t * 0.7 + s) * 6;
    const r = 0.7 + sportHash(s + 5.3) * 1.6;
    g.fillStyle = white(0.15 + sportHash(s + 9.9) * 0.4);
    g.beginPath();
    g.arc(x, y, r, 0, Math.PI * 2);
    g.fill();
  }
}

function drawClouds(g: CanvasRenderingContext2D, w: number, h: number, t: number) {
  g.filter = "blur(18px)";
  for (let i = 0; i < 3; i++) {
    const cw = w * (0.7 + 0.12 * i);
    const drift = Math.sin(t * 0.12 + i * 2.1) * 30;
    const x = w * (0.15 + 0.32 * i) - cw / 2 + drift;
    const y = h * (0.02 + 0.14 * i);
    const ch = cw * 0.36;
    g.fillStyle = white(0.07);
    g.beginPath();
    g.ellipse(x + cw / 2, y + ch / 2, cw / 2, ch / 2, 0, 0, Math.PI * 2);
    g.fill();
  }
  g.filter = "none";
}

function drawSun(g: CanvasRenderingContext2D, w: number, h: number, t: number) {
  const cx = w * 0.84;
  const cy = h * 0.2;
  const pulse = 1 + 0.06 * Math.sin(t * 1.6);
  const grad = g.createRadialGradient(cx, cy, 0, cx, cy, w * 0.75 * pulse);
  grad.addColorStop(0, "rgb(255 138 31 / 0.3)");
  grad.addColorStop(0.5, "rgb(255 138 31 / 0.06)");
  grad.addColorStop(1, "rgb(255 138 31 / 0)");
  g.fillStyle = grad;
  g.fillRect(0, 0, w, h);
  g.strokeStyle = "rgb(255 180 92 / 0.12)";
  g.lineWidth = 2;
  g.lineCap = "round";
  g.beginPath();
  for (let i = 0; i < 12; i++) {
    const a = (i / 12) * 2 * Math.PI + t * 0.15;
    const outer = 104 + 18 * Math.sin(t + i);
    g.moveTo(cx + Math.cos(a) * 44, cy + Math.sin(a) * 44);
    g.lineTo(cx + Math.cos(a) * outer, cy + Math.sin(a) * outer);
  }
  g.stroke();
}
