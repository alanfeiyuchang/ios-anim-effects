/** buttons.hold-ring · 环形长按 (Buttons+HoldRing.swift) */
import { animate, motion, useMotionValue, useMotionValueEvent } from "motion/react";
import { Check, Fingerprint } from "lucide-react";
import { useEffect, useRef, useState } from "react";
import { DemoHint, Palette, anim, spring, useAutoplay, useHaptics, useSilently, useTimeouts, type DemoProps } from "../../kit";
import { BOUNCY, BlurReplace, SymbolReplace, cubicKF, moveKF, springKF, track, useLongPress, useSince } from "./_a-kit";

const RING = 138;
const MINT = [0x21, 0xd4, 0xa8];
const SKY = [0x3a, 0xc4, 0xff];

/** Colour of AngularGradient([mint, sky, mint]) at fraction f of the turn. */
function ringColor(f: number) {
  const k = f <= 0.5 ? f * 2 : (1 - f) * 2;
  const c = MINT.map((m, i) => Math.round(m + (SKY[i] - m) * k));
  return `rgb(${c[0]} ${c[1]} ${c[2]})`;
}

export default function HoldRing({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const silently = useSilently();
  const { after, clearAll } = useTimeouts();
  const progress = useMotionValue(0);
  const [p, setP] = useState(0);
  useMotionValueEvent(progress, "change", setP);
  const [pressing, setPressing] = useState(false);
  const [done, setDone] = useState(false);
  const doneRef = useRef(false);
  const [completions, setCompletions] = useState(0);
  const script = useRef<(() => void) | null>(null);
  const duration = ctx.n("duration");
  const width = ctx.n("width");

  const begin = () => {
    if (doneRef.current) return;
    setPressing(true);
    haptics.tap("soft");
    animate(progress, 1, anim.linear(duration));
  };
  const end = () => {
    setPressing(false);
    if (doneRef.current) return;
    animate(progress, 0, spring(0.4, 1));
  };
  const complete = () => {
    if (doneRef.current) return;
    doneRef.current = true;
    setPressing(false);
    animate(progress, 1, anim.snappyD(0.2));
    setDone(true);
    setCompletions((c) => c + 1);
    haptics.success();
    after(1.5, () => {
      doneRef.current = false;
      setDone(false);
      animate(progress, 0, spring(0.5, 0.9));
    });
  };
  const cancelScript = () => {
    script.current?.();
    script.current = null;
  };

  const longPress = useLongPress({
    duration,
    maximumDistance: 50,
    onComplete: complete,
    onPressingChanged: (isPressing) => {
      cancelScript();
      if (isPressing) begin();
      else end();
    },
  });

  useAutoplay(ctx.isPreview, () => {
    if (doneRef.current) return;
    begin();
    cancelScript();
    script.current = after(duration, () => {
      script.current = null;
      silently(complete);
    });
  }, { every: duration + 2.6, delay: 0.4 });
  useEffect(() => () => clearAll(), [clearAll]);

  const t = useSince(completions, 0.6);
  const popScale = track(t, 1, [cubicKF(1.08, 0.12), springKF(1, 0.4, BOUNCY)]);
  const wave = track(t, 1, [moveKF(1), cubicKF(1.5, 0.6)]);
  const waveOpacity = t < 0 ? 0 : track(t, 0, [moveKF(0.9), cubicKF(0, 0.6)]);

  // Trimmed ring: a conic gradient masked to the ring and to the swept angle, plus round caps.
  const outer = RING / 2 + width / 2;
  const inner = RING / 2 - width / 2;
  const deg = p * 360;
  const cap = (f: number) => {
    const a = f * 2 * Math.PI - Math.PI / 2;
    return (
      <div
        style={{
          position: "absolute",
          left: 100 + Math.cos(a) * (RING / 2) - width / 2,
          top: 100 + Math.sin(a) * (RING / 2) - width / 2,
          width,
          height: width,
          borderRadius: "50%",
          background: ringColor(f),
        }}
      />
    );
  };

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center" }}>
      <div style={{ flex: 1 }} />
      <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 20 }}>
        <div {...longPress} style={{ ...longPress.style, position: "relative", width: 200, height: 200, borderRadius: "50%" }}>
          <div
            style={{
              position: "absolute",
              left: 100 - outer,
              top: 100 - outer,
              width: outer * 2,
              height: outer * 2,
              borderRadius: "50%",
              boxShadow: `inset 0 0 0 ${width}px ${Palette.labelAlpha(0.08)}`,
            }}
          />
          {p > 0.0005 && (
            <div style={{ position: "absolute", inset: 0, filter: "drop-shadow(0 0 6px rgb(33 212 168 / 0.5))", pointerEvents: "none" }}>
              <div
                style={{
                  position: "absolute",
                  left: 100 - outer,
                  top: 100 - outer,
                  width: outer * 2,
                  height: outer * 2,
                  borderRadius: "50%",
                  background: `conic-gradient(${Palette.mint}, ${Palette.sky}, ${Palette.mint})`,
                  WebkitMask: `radial-gradient(circle closest-side, transparent ${inner}px, #000 ${inner + 0.5}px), conic-gradient(#000 ${deg}deg, transparent ${deg}deg)`,
                  WebkitMaskComposite: "source-in",
                  mask: `radial-gradient(circle closest-side, transparent ${inner}px, #000 ${inner + 0.5}px) intersect, conic-gradient(#000 ${deg}deg, transparent ${deg}deg)`,
                }}
              />
              {cap(0)}
              {cap(p)}
            </div>
          )}
          <div
            style={{
              position: "absolute",
              left: 44,
              top: 44,
              width: 112,
              height: 112,
              borderRadius: "50%",
              boxShadow: `0 0 0 1.5px ${Palette.mint}, inset 0 0 0 1.5px ${Palette.mint}`,
              transform: `scale(${wave})`,
              opacity: ctx.b("shockwave") ? waveOpacity : 0,
            }}
          />
          <div
            style={{
              position: "absolute",
              left: 44,
              top: 44,
              width: 112,
              height: 112,
              transform: `scale(${popScale})`,
            }}
          >
            <motion.div
              initial={false}
              animate={{
                scale: pressing && !done ? 0.94 : 1,
                boxShadow: pressing ? "0px 3px 6px rgba(0, 0, 0, 0.08)" : "0px 8px 14px rgba(0, 0, 0, 0.16)",
              }}
              transition={spring(0.3, 0.7)}
              style={{
                position: "absolute",
                inset: 0,
                borderRadius: "50%",
                background: `linear-gradient(${Palette.elevated}, ${Palette.surface})`,
                display: "grid",
                placeItems: "center",
              }}
            >
              <div style={{ position: "absolute", inset: 0, borderRadius: "50%", boxShadow: `inset 0 0 0 1px ${Palette.stroke}` }} />
              <SymbolReplace id={done ? "done" : "touch"}>
                {done ? (
                  <Check size={46} strokeWidth={2.6} color={Palette.mint} />
                ) : (
                  <Fingerprint size={48} strokeWidth={2} color={pressing ? Palette.sky : Palette.secondaryLabel} style={{ transition: "color 0.2s" }} />
                )}
              </SymbolReplace>
            </motion.div>
          </div>
        </div>
        <BlurReplace id={done ? "paid" : "hold"} style={{ fontSize: 17, lineHeight: "22px", fontWeight: 600 }}>
          {done ? (
            <span style={{ color: Palette.mint }}>{ctx.t("Paid · €24.90", "已支付 · €24.90")}</span>
          ) : (
            <span style={{ color: Palette.secondaryLabel }}>{ctx.t("Hold to pay €24.90", "长按支付 €24.90")}</span>
          )}
        </BlurReplace>
      </div>
      <div style={{ flex: 1 }} />
      <DemoHint ctx={ctx} en="Press and hold the button" zh="按住按钮不放" style={{ paddingBottom: 18 }} />
    </div>
  );
}
