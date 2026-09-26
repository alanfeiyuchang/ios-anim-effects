/** gestures.detent-sheet · 速度感知分段面板 (Gestures+DetentSheet.swift) */
import { animate, motion, useMotionValue, useTransform } from "motion/react";
import { useEffect, useRef } from "react";
import { DemoHint, Palette, PlaceholderLines, anim, black, clamp, glass, rubberBand, spring, textStyle, useAutoplay, useHaptics, usePan, white, type DemoProps } from "../../kit";

const W = 230;
const H = 320;
type Detent = "peek" | "half" | "full";
const DETENTS: Detent[] = ["peek", "half", "full"];
const detentTop = (d: Detent) => (d === "peek" ? H - 74 : d === "half" ? H * 0.48 : 26);
const PEEK = detentTop("peek");
const FULL = detentTop("full");

function displayed(raw: number) {
  if (raw < FULL) return FULL + rubberBand(raw - FULL, 40);
  if (raw > PEEK) return PEEK + rubberBand(raw - PEEK, 40);
  return raw;
}

export default function DetentSheet({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const detent = useRef<Detent>("peek");
  const top = useMotionValue(PEEK);
  const fraction = useTransform(top, (t) => clamp((PEEK - t) / (PEEK - FULL)));
  const backdropScale = useTransform(fraction, (f) => 1 - 0.06 * f);
  const dim = useTransform(fraction, (f) => 0.3 * f);
  const held = useRef(false);
  const engaged = useRef<"no" | "yes" | "failed">("no");
  const autoStep = useRef(0);
  const script = useRef<number | null>(null);
  useEffect(() => () => {
    if (script.current) window.clearTimeout(script.current);
  }, []);

  const nearestDetent = (y: number) => {
    let best: Detent = "peek";
    let bestD = Infinity;
    for (const c of DETENTS) {
      const d = Math.abs(detentTop(c) - y);
      if (d < bestD) {
        bestD = d;
        best = c;
      }
    }
    return best;
  };

  const settle = (target: Detent, haptic: boolean) => {
    const changed = target !== detent.current;
    detent.current = target;
    animate(top, detentTop(target), spring(ctx.n("response"), ctx.n("damping")));
    if (changed && haptic) haptics.selection();
  };

  // PageSafePan: begins only when the first movement heads in a direction the detent can move.
  const base = useRef({ x: 0, y: 0 });
  const pan = usePan(
    {
      onStart: ({ translation, velocity }) => {
        const d = Math.abs(velocity.x) + Math.abs(velocity.y) > 20 ? velocity : translation;
        const vertical = Math.abs(d.y) > Math.abs(d.x);
        const dirs = detent.current === "peek" ? ["up"] : detent.current === "full" ? ["down"] : ["up", "down"];
        const ok = vertical && ((d.y > 0 && dirs.includes("down")) || (d.y < 0 && dirs.includes("up")));
        engaged.current = ok ? "yes" : "failed";
        if (!ok) return;
        base.current = translation;
        if (!held.current) {
          held.current = true;
          if (script.current) window.clearTimeout(script.current);
          script.current = null;
        }
        top.stop();
      },
      onChange: ({ translation }) => {
        if (engaged.current !== "yes") return;
        top.stop();
        top.set(displayed(detentTop(detent.current) + translation.y - base.current.y));
      },
      onEnd: ({ velocity }) => {
        const was = engaged.current;
        engaged.current = "no";
        if (was !== "yes" || !held.current) return;
        held.current = false;
        const projected = top.get() + velocity.y * ctx.n("projection");
        settle(nearestDetent(projected), true);
      },
    },
    10,
  );

  /** Cycles peek → full → half → peek: a quick pre-pull toward the target, then the settle spring. */
  const simulate = () => {
    if (held.current) return;
    const order: Detent[] = ["full", "half", "peek"];
    const target = order[autoStep.current % order.length];
    autoStep.current += 1;
    const pull = detentTop(target) - detentTop(detent.current);
    animate(top, displayed(detentTop(detent.current) + pull * 0.55), anim.easeOut(0.22));
    if (script.current) window.clearTimeout(script.current);
    script.current = window.setTimeout(() => {
      script.current = null;
      settle(target, false);
    }, 240);
  };
  useAutoplay(ctx.isPreview, simulate, { every: 1.5 });

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 12 }}>
      <div
        style={{
          position: "relative",
          width: W,
          height: H,
          flexShrink: 0,
          borderRadius: 34,
          background: "#000",
          boxShadow: `0 10px 18px ${black(0.14)}`,
        }}
      >
        <div style={{ position: "absolute", inset: 0, borderRadius: 34, overflow: "hidden", isolation: "isolate" }}>
          <motion.div style={{ position: "absolute", inset: 0, scale: backdropScale }}>
            <SheetBackdrop />
            <motion.div style={{ position: "absolute", inset: 0, background: "#000", opacity: dim }} />
          </motion.div>
          <motion.div {...pan} style={{ position: "absolute", left: 0, top: 0, width: W, height: H, y: top, touchAction: "none" }}>
            <div
              style={{
                position: "absolute",
                inset: 0,
                borderRadius: "24px 24px 0 0",
                ...glass("regular"),
                boxShadow: `0 -2px 12px ${black(0.18)}`,
              }}
            />
            <div style={{ position: "relative", padding: "0 16px", display: "flex", flexDirection: "column", gap: 12 }}>
              <div style={{ alignSelf: "center", marginTop: 8, width: 36, height: 5, borderRadius: 3, background: Palette.labelAlpha(0.25) }} />
              <div style={{ ...textStyle.headline }}>{ctx.t("Nearby", "附近地点")}</div>
              {Array.from({ length: 5 }, (_, i) => {
                const c = Palette.spectrum[i % Palette.spectrum.length];
                return (
                  <div key={i} style={{ display: "flex", alignItems: "center", gap: 10 }}>
                    <div
                      style={{
                        width: 32,
                        height: 32,
                        flexShrink: 0,
                        borderRadius: 9,
                        background: `linear-gradient(color-mix(in srgb, ${c} 88%, white), ${c})`,
                      }}
                    />
                    <div style={{ flex: 1 }}>
                      <PlaceholderLines count={2} />
                    </div>
                  </div>
                );
              })}
            </div>
          </motion.div>
        </div>
        <div style={{ position: "absolute", inset: 0, borderRadius: 34, boxShadow: `inset 0 0 0 1px ${Palette.stroke}`, pointerEvents: "none" }} />
      </div>
      <DemoHint ctx={ctx} en="Flick the sheet up or down" zh="上下甩动面板" />
    </div>
  );
}

function SheetBackdrop() {
  return (
    <div style={{ position: "absolute", inset: 0, overflow: "hidden", background: `linear-gradient(135deg, rgb(33 212 168 / 0.55), rgb(58 196 255 / 0.6))` }}>
      {Array.from({ length: 4 }, (_, i) => {
        const h = i % 2 === 0 ? 10 : 6;
        return (
          <div
            key={i}
            style={{
              position: "absolute",
              left: W / 2 - 190,
              top: H / 2 - h / 2,
              width: 380,
              height: h,
              borderRadius: h / 2,
              background: white(0.7),
              transform: `translate(${i * 22 - 30}px, ${i * 50 - 90}px) rotate(${i * 47 - 30}deg)`,
            }}
          />
        );
      })}
      <svg viewBox="0 0 30 30" width={30} height={30} style={{ position: "absolute", left: W / 2 - 15 + 20, top: H / 2 - 15 - 40 }}>
        <circle cx="15" cy="15" r="14" fill={Palette.red} />
        <circle cx="15" cy="10.5" r="4.6" fill="#fff" />
        <rect x="14" y="13" width="2" height="10" rx="1" fill="#fff" />
      </svg>
    </div>
  );
}
