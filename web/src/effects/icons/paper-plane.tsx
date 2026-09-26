/** icons.paper-plane · 纸飞机发送 (Icons+PaperPlane.swift) */
import { motion } from "motion/react";
import { useRef, useState } from "react";
import { DemoHint, Palette, anim, clamp, spring, textStyle, useAutoplay, useHaptics, useTimeouts, type DemoProps } from "../../kit";
import { C, Glyph, L, S, SPRINGS, SYM, sym, track, useSince, type GlyphDef } from "./_icons-kit";

type P = { x: number; y: number };
const HEIGHT = 222;
const CHECK: GlyphDef = [{ d: "M4.2 12.8 9.6 18.2 19.8 6", mode: "stroke", sw: 2.8 }];

function curve(swoop: number) {
  const start = { x: 150, y: 170 };
  const control = { x: 150 - 150 * swoop, y: 50 + 50 * (1 - swoop) };
  const end = { x: 296, y: 12 };
  const point = (t: number): P => {
    const u = 1 - t;
    return { x: u * u * start.x + 2 * u * t * control.x + t * t * end.x, y: u * u * start.y + 2 * u * t * control.y + t * t * end.y };
  };
  const heading = (t: number) => {
    const u = 1 - t;
    const dx = 2 * u * (control.x - start.x) + 2 * t * (end.x - control.x);
    const dy = 2 * u * (control.y - start.y) + 2 * t * (end.y - control.y);
    return (Math.atan2(dy, dx) * 180) / Math.PI;
  };
  /** The curve trimmed to [a, b] as a path. */
  const segment = (a: number, b: number) => {
    const p0 = point(a);
    const p2 = point(b);
    const w0 = (1 - a) * (1 - b);
    const w1 = (1 - a) * b + a * (1 - b);
    const w2 = a * b;
    const c = { x: w0 * start.x + w1 * control.x + w2 * end.x, y: w0 * start.y + w1 * control.y + w2 * end.y };
    return `M${p0.x} ${p0.y}Q${c.x} ${c.y} ${p2.x} ${p2.y}`;
  };
  return { start, point, heading, segment };
}

export default function PaperPlane({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const { after } = useTimeouts();
  const [launches, setLaunches] = useState(0);
  const [sent, setSent] = useState(false);
  const token = useRef(0);
  const duration = ctx.n("duration");
  const c = curve(ctx.n("swoop"));
  const hold = 0.6;

  const t = useSince(launches, 0.14 + duration + hold + 0.5);
  const v = (initial: number, frames: Parameters<typeof track>[2]) => (t < 0 ? initial : track(t, initial, frames));
  const press = v(1, [C(0.9, 0.12), S(1, 0.4, SPRINGS.bouncy)]);
  const windup = v(0, [C(-12, 0.14), C(0, 0.16)]);
  const fly = v(0, [L(0, 0.14), C(1, duration), L(1, hold), L(0, 0.01)]);
  const opacity = v(1, [L(1, 0.14 + duration * 0.75), L(0, duration * 0.25), L(0, hold + 0.01), C(1, 0.3)]);
  const scale = v(1, [L(1, 0.14), C(0.7, duration), L(0.7, hold), L(0.2, 0.01), S(1, 0.45, SPRINGS.bouncy)]);

  const send = (scripted = false) => {
    setLaunches((n) => n + 1);
    token.current += 1;
    const mine = token.current;
    haptics.tap("medium");
    setSent(false);
    const away = 0.14 + ctx.n("duration") * 0.8;
    after(away, () => {
      if (mine !== token.current) return;
      setSent(true);
      if (!scripted) haptics.success();
    });
    after(away + 1.2, () => {
      if (mine === token.current) setSent(false);
    });
  };
  useAutoplay(ctx.isPreview, () => send(true), { every: Math.max(duration, 0.4) + 1.5 });

  const pos = c.point(fly);
  let bank = (c.heading(fly) + 45) % 360;
  if (bank > 180) bank -= 360;
  if (bank < -180) bank += 360;
  const angle = bank * Math.min(fly * 5, 1) + windup;
  const tint = clamp((fly - 0.1) / 0.2);
  const shadowOpacity = fly > 0.02 ? 0.2 + 0.15 * tint : 0;
  const plane = sym(28);

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 4 }}>
      <div onClick={() => send()} style={{ position: "relative", width: 300, height: HEIGHT, cursor: "pointer" }}>
        {ctx.b("trail") && fly > 0 && (
          <svg width={300} height={HEIGHT} style={{ position: "absolute", inset: 0, overflow: "visible", opacity }}>
            <path
              d={c.segment(Math.max(fly - 0.34, 0), fly)}
              fill="none"
              stroke="rgb(164 107 255 / 0.55)"
              strokeWidth={2.5}
              strokeLinecap="round"
              strokeDasharray="2 7"
            />
          </svg>
        )}
        <div
          style={{
            position: "absolute",
            left: c.start.x - 42,
            top: c.start.y - 42,
            width: 84,
            height: 84,
            borderRadius: "50%",
            background: Palette.primary,
            boxShadow: `inset 0 0 0 1px rgb(255 255 255 / 0.3), 0 8px 16px rgb(110 123 255 / 0.4)`,
            transform: `scale(${press})`,
            display: "grid",
            placeItems: "center",
            color: "#fff",
          }}
        >
          <motion.div initial={false} animate={{ scale: sent ? 1 : 0.3 }} transition={spring(0.35, 0.6)} style={{ opacity: sent ? 1 - opacity : 0 }}>
            <Glyph def={CHECK} size={sym(28)} />
          </motion.div>
        </div>
        <div
          style={{
            position: "absolute",
            left: pos.x - plane / 2,
            top: pos.y - plane / 2,
            transform: `rotate(${angle}deg) scale(${scale * press})`,
            opacity,
            filter: shadowOpacity > 0 ? `drop-shadow(0 4px 6px rgb(110 123 255 / ${shadowOpacity}))` : undefined,
          }}
        >
          <div style={{ color: "#fff" }}>
            <Glyph def={SYM.paperplaneFill} size={plane} />
          </div>
          <div style={{ position: "absolute", inset: 0, color: Palette.indigo, opacity: tint }}>
            <Glyph def={SYM.paperplaneFill} size={plane} />
          </div>
        </div>
      </div>
      <div style={{ display: "grid", ...textStyle.subheadline, fontWeight: 600 }}>
        {[false, true].map((state) => (
          <motion.span
            key={String(state)}
            initial={false}
            animate={{ opacity: sent === state ? 1 : 0 }}
            transition={anim.snappy}
            style={{ gridArea: "1 / 1", textAlign: "center", color: state ? Palette.green : Palette.secondaryLabel }}
          >
            {state ? ctx.t("Sent", "已发送") : ctx.t("Send", "发送")}
          </motion.span>
        ))}
      </div>
      <DemoHint ctx={ctx} en="Tap to send" zh="点击发送" style={{ paddingTop: 8 }} />
    </div>
  );
}
