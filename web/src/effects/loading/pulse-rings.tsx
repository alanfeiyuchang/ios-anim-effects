/** loading.pulse-rings · 雷达脉冲 (Loading+Ambient.swift) */
import { RadioTower } from "lucide-react";
import { Palette, alpha, useClock, type DemoProps } from "../../kit";
import { frac, previewFps, usePhase } from "./shared";

const CORE = 72;
const PEERS = [
  { initials: "MJ", colors: [Palette.pink, Palette.coral], angle: -145 },
  { initials: "DK", colors: [Palette.mint, Palette.sky], angle: -30 },
  { initials: "AN", colors: [Palette.amber, Palette.coral], angle: 105 },
];

/** Staggered back-out pop-in over a 6 s scene, then a shared fade before the loop restarts. */
function peerState(t: number, index: number) {
  const local = t % 6;
  const a = Math.min(Math.max((local - 0.8 - index * 1.1) / 0.45, 0), 1);
  const out = Math.min(Math.max((6 - local) / 0.45, 0), 1);
  const c1 = 1.70158;
  const c3 = c1 + 1;
  const back = a <= 0 ? 0 : 1 + c3 * Math.pow(a - 1, 3) + c1 * Math.pow(a - 1, 2);
  return { scale: back * (0.85 + 0.15 * out), opacity: Math.min(a * 2, 1) * out };
}

export default function PulseRings({ ctx }: DemoProps) {
  const count = Math.max(ctx.i("count"), 1);
  const period = ctx.n("period");
  const spread = ctx.n("spread");
  const tint = [Palette.blue, Palette.mint, Palette.coral][Math.min(Math.max(ctx.i("tint"), 0), 2)];
  const fps = previewFps(ctx.isPreview);
  const cycles = usePhase(1 / Math.max(period, 0.1), fps);
  const scene = useClock(true, fps);
  const breath = 1 + 0.03 * Math.sin(cycles * 2 * Math.PI);
  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 14 }}>
      <div style={{ position: "relative", width: 260, height: 250 }}>
        {Array.from({ length: count }, (_, index) => {
          const age = frac(cycles + index / count);
          const eased = 1 - (1 - age) * (1 - age);
          const side = CORE + (CORE * spread - CORE) * eased;
          return (
            <div
              key={index}
              style={{
                position: "absolute",
                left: 130 - side / 2,
                top: 125 - side / 2,
                width: side,
                height: side,
                borderRadius: "50%",
                background: alpha(tint, 0.18 * (1 - age)),
                boxShadow: `inset 0 0 0 1.5px ${alpha(tint, 0.6 * (1 - age))}`,
              }}
            />
          );
        })}
        {PEERS.map((peer, index) => {
          const s = peerState(scene, index);
          const angle = (peer.angle * Math.PI) / 180;
          return (
            <div
              key={peer.initials}
              style={{
                position: "absolute",
                left: 130 - 20 + Math.cos(angle) * 100,
                top: 125 - 20 + Math.sin(angle) * 100,
                width: 40,
                height: 40,
                borderRadius: "50%",
                background: `linear-gradient(135deg, ${peer.colors.join(", ")})`,
                boxShadow: "inset 0 0 0 2.5px #fff, 0 3px 6px rgb(0 0 0 / 0.18)",
                display: "grid",
                placeItems: "center",
                color: "#fff",
                fontSize: 12,
                fontWeight: 700,
                transform: `scale(${s.scale})`,
                opacity: s.opacity,
              }}
            >
              {peer.initials}
            </div>
          );
        })}
        <div
          style={{
            position: "absolute",
            left: 130 - CORE / 2,
            top: 125 - CORE / 2,
            width: CORE,
            height: CORE,
            borderRadius: "50%",
            background: `linear-gradient(135deg, ${alpha(tint, 0.75)}, ${tint})`,
            boxShadow: `0 6px 14px ${alpha(tint, 0.45)}`,
            display: "grid",
            placeItems: "center",
            color: "#fff",
            transform: `scale(${breath})`,
          }}
        >
          <RadioTower size={30} strokeWidth={2.4} />
        </div>
      </div>
      <span style={{ fontSize: 13, lineHeight: "18px", fontWeight: 500, color: Palette.secondaryLabel }}>
        {ctx.t("Looking for nearby devices…", "正在查找附近的设备…")}
      </span>
    </div>
  );
}
