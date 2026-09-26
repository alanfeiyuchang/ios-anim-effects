/** text.seven-segment · 七段数码管 (Text+SevenSegment.swift) */
import { Timer } from "lucide-react";
import { useEffect, useRef } from "react";
import { DemoHint, Palette, alpha, black, useClock, useHaptics, white, type DemoProps } from "../../kit";

/** Segment order a, b, c, d, e, f, g (top, top-right, bottom-right, bottom, bottom-left, top-left, middle). */
const MASKS = [
  [1, 1, 1, 1, 1, 1, 0],
  [0, 1, 1, 0, 0, 0, 0],
  [1, 1, 0, 1, 1, 0, 1],
  [1, 1, 1, 1, 0, 0, 1],
  [0, 1, 1, 0, 0, 1, 1],
  [1, 0, 1, 1, 0, 1, 1],
  [1, 0, 1, 1, 1, 1, 1],
  [1, 1, 1, 0, 0, 0, 0],
  [1, 1, 1, 1, 1, 1, 1],
  [1, 1, 1, 1, 0, 1, 1],
];
const W = 44;
const H = 82;
const T = 8;
const secs = () => performance.now() / 1000;

export default function SevenSegment({ ctx }: DemoProps) {
  const haptics = useHaptics();
  useClock(true, 30);
  const clock = useRef({ start: secs(), countBase: 0, countStart: secs() });
  const speed = ctx.n("speed");
  const lastSpeed = useRef(speed);
  useEffect(() => {
    const now = secs();
    clock.current.countBase += (now - clock.current.countStart) * lastSpeed.current;
    clock.current.countStart = now;
    lastSpeed.current = speed;
  }, [speed]);

  const tint = [Palette.amber, Palette.mint, Palette.red][ctx.i("tint")] ?? Palette.amber;
  const decay = ctx.n("decay");
  const now = secs();
  const real = now - clock.current.start;
  const elapsed = clock.current.countBase + (now - clock.current.countStart) * speed;
  const total = 600;
  const remaining = total - (Math.floor(elapsed) % (total + 1));
  const minutes = Math.floor(remaining / 60);
  const seconds = remaining % 60;
  const digits = [Math.floor(minutes / 10), minutes % 10, Math.floor(seconds / 10), seconds % 10];
  const colonOn = real % 1 < 0.5;

  const reset = () => {
    haptics.tap("light");
    const t = secs();
    clock.current = { start: t, countBase: 0, countStart: t };
  };

  return (
    <div onClick={reset} style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 16, cursor: "pointer" }}>
      <div
        style={{
          padding: "20px 22px",
          borderRadius: 24,
          background: "rgb(13 13 13)",
          boxShadow: `inset 0 0 0 1px ${white(0.08)}, 0 10px 18px ${black(0.3)}`,
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          gap: 12,
        }}
      >
        <div style={{ display: "flex", alignItems: "center", gap: 10, transform: "matrix(1, 0, -0.08, 1, 7, 0)", transformOrigin: "0 0" }}>
          <Digit digit={digits[0]} tint={tint} decay={decay} />
          <Digit digit={digits[1]} tint={tint} decay={decay} />
          <div
            style={{
              display: "flex",
              flexDirection: "column",
              gap: 22,
              opacity: colonOn ? 1 : 0.12,
              filter: `drop-shadow(0 0 5px ${alpha(tint, colonOn ? 0.8 : 0)})`,
              transition: "opacity 0.15s ease-out, filter 0.15s ease-out",
            }}
          >
            <span style={{ width: 8, height: 8, borderRadius: "50%", background: tint }} />
            <span style={{ width: 8, height: 8, borderRadius: "50%", background: tint }} />
          </div>
          <Digit digit={digits[2]} tint={tint} decay={decay} />
          <Digit digit={digits[3]} tint={tint} decay={decay} />
        </div>
        <div style={{ display: "flex", alignItems: "center", gap: 6, fontSize: 12, lineHeight: "16px", fontWeight: 600, color: alpha(tint, 0.7) }}>
          <Timer size={13} strokeWidth={2.4} />
          <span>{ctx.t("Pasta · al dente", "意面 · 弹牙口感")}</span>
        </div>
      </div>
      <DemoHint ctx={ctx} en="Tap to reset" zh="点击重置" />
    </div>
  );
}

function segmentFrame(index: number) {
  const gap = 2;
  const hLen = W - T - gap * 2;
  const vLen = H / 2 - T / 2 - gap * 2;
  const left = T / 2;
  const right = W - T / 2;
  const top = T / 2;
  const middle = H / 2;
  const bottom = H - T / 2;
  const upper = H / 4 + T / 8;
  const lower = (H * 3) / 4 - T / 8;
  const r = (x: number, y: number, w: number, h: number) => ({ x: x - w / 2, y: y - h / 2, w, h });
  switch (index) {
    case 0:
      return r(W / 2, top, hLen, T);
    case 1:
      return r(right, upper, T, vLen);
    case 2:
      return r(right, lower, T, vLen);
    case 3:
      return r(W / 2, bottom, hLen, T);
    case 4:
      return r(left, lower, T, vLen);
    case 5:
      return r(left, upper, T, vLen);
    default:
      return r(W / 2, middle, hLen, T);
  }
}

function Digit({ digit, tint, decay }: { digit: number; tint: string; decay: number }) {
  const mask = MASKS[Math.min(Math.max(digit, 0), 9)];
  return (
    <div style={{ position: "relative", width: W, height: H }}>
      {mask.map((on, index) => {
        const f = segmentFrame(index);
        const transition = on ? `opacity 0.08s ease-out ${index * 0.025}s, box-shadow 0.08s ease-out ${index * 0.025}s` : `opacity ${decay}s ease-out, box-shadow ${decay}s ease-out`;
        return (
          <span
            key={index}
            style={{
              position: "absolute",
              left: f.x,
              top: f.y,
              width: f.w,
              height: f.h,
              borderRadius: T / 2,
              background: tint,
              opacity: on ? 1 : 0.07,
              boxShadow: `0 0 6px ${alpha(tint, on ? 0.85 : 0)}`,
              transition,
            }}
          />
        );
      })}
    </div>
  );
}
