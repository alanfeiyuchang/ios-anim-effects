/** buttons.echo-press · 声呐回响 (Buttons+EchoPress.swift) */
import { Key, Radio } from "lucide-react";
import { useRef, useState } from "react";
import { DemoHint, Palette, SymbolBounce, alpha, demoCard, useAutoplay, useHaptics, useTimeouts, type DemoProps } from "../../kit";
import { BOUNCY, BlurReplace, cubicKF, linearKF, springKF, track, useMountClock, useSince } from "./_a-kit";

const W = 230;
const H = 60;

export default function EchoPress({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const { after } = useTimeouts();
  const [pulses, setPulses] = useState<number[]>([]);
  const [taps, setTaps] = useState(0);
  const tapsRef = useRef(0);
  const nextID = useRef(0);
  const [ringing, setRinging] = useState(false);
  const count = Math.max(ctx.i("rings"), 1);
  const stagger = ctx.n("stagger");

  const ping = () => {
    haptics.tap("medium");
    tapsRef.current += 1;
    setTaps(tapsRef.current);
    const id = nextID.current++;
    setPulses((p) => [...p, id]);
    setRinging(true);
    const tag = tapsRef.current;
    after(0.9 + stagger * count, () => {
      setPulses((p) => p.filter((x) => x !== id));
      if (tag === tapsRef.current) setRinging(false);
    });
  };

  useAutoplay(ctx.isPreview, ping, { every: 1.4, delay: 0.3 });

  const scale = track(useSince(taps, 0.5), 1, [cubicKF(0.95, 0.08), springKF(1, 0.4, BOUNCY)]);
  const zh = ctx.lang === "zh";

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center" }}>
      <div style={{ flex: 1 }} />
      <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 30 }}>
        <div style={{ ...demoCard(18), width: W, padding: 12, display: "flex", alignItems: "center", gap: 12 }}>
          <div style={{ width: 42, height: 42, borderRadius: "50%", background: alpha(Palette.sky, 0.16), display: "grid", placeItems: "center", color: Palette.blue }}>
            <Key size={19} strokeWidth={2.4} style={{ transform: "rotate(-45deg)" }} />
          </div>
          <div style={{ display: "flex", flexDirection: "column", gap: 3 }}>
            <div style={{ fontSize: 15, lineHeight: "20px", fontWeight: 600, color: Palette.label }}>{ctx.t("Keys", "钥匙")}</div>
            <BlurReplace id={ringing ? "ring" : "idle"} align="leading" style={{ fontSize: 12, lineHeight: "16px" }}>
              {ringing ? (
                <span style={{ color: Palette.blue }}>{ctx.t("Playing sound…", "正在播放声音…")}</span>
              ) : (
                <span style={{ color: Palette.secondaryLabel }}>{ctx.t("Nearby · 3 m", "附近 · 3 米")}</span>
              )}
            </BlurReplace>
          </div>
        </div>
        <div style={{ position: "relative", width: W, height: H + 100, display: "grid", placeItems: "center" }}>
          {pulses.map((id) => (
            <Rings key={id} count={count} spread={ctx.n("spread")} stagger={stagger} />
          ))}
          <button
            type="button"
            onClick={ping}
            style={{
              position: "relative",
              width: W,
              height: H,
              borderRadius: H / 2,
              background: Palette.ocean,
              boxShadow: "inset 0 0 0 1px rgb(255 255 255 / 0.25), 0 8px 14px rgb(79 124 255 / 0.35)",
              color: "#fff",
              fontSize: 17,
              fontWeight: 600,
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              gap: 8,
              transform: `scale(${scale})`,
            }}
          >
            <SymbolBounce trigger={taps}>
              <Radio size={19} strokeWidth={2.4} />
            </SymbolBounce>
            <span>{zh ? "让钥匙响铃" : "Ping my keys"}</span>
          </button>
        </div>
      </div>
      <div style={{ flex: 1 }} />
      <DemoHint ctx={ctx} en="Tap the button" zh="点击按钮" style={{ paddingBottom: 18 }} />
    </div>
  );
}

/** One tap's worth of echoes; ring i waits i × stagger, then grows over 0.8 s. */
function Rings({ count, spread, stagger }: { count: number; spread: number; stagger: number }) {
  const elapsed = useMountClock(stagger * count + 0.9);
  return (
    <>
      {Array.from({ length: count }, (_, i) => {
        const delay = i * stagger;
        const p = track(elapsed, 0, [linearKF(0, Math.max(delay, 0.001)), linearKF(0.001, 0.001), cubicKF(1, 0.8)]);
        const grow = spread * 2 * p;
        const lw = 2.5 - 2 * p;
        const visible = p > 0 && p < 1;
        return (
          <div
            key={i}
            style={{
              position: "absolute",
              left: "50%",
              top: "50%",
              width: W + grow + lw,
              height: H + grow + lw,
              transform: "translate(-50%, -50%)",
              borderRadius: 999,
              border: `${lw}px solid ${Palette.sky}`,
              opacity: visible ? 1 - p : 0,
              pointerEvents: "none",
            }}
          />
        );
      })}
    </>
  );
}
