/** scroll.rotary-wheel · 旋钮转盘 (Scroll+RotaryWheel.swift) */
import { motion } from "motion/react";
import { useRef } from "react";
import { DemoHint, Palette, alpha, black, spring, useAutoplay, type DemoProps } from "../../kit";
import { FadeText, ScrollKit, ScrollKitIcon, SnapMarkers, strideSnap, useScroller, useSelectionTick, wrap } from "./_kit";

const COUNT = 12;
/** Three turns of the dial; re-centred on the middle turn whenever scrolling stops. */
const COPIES = 3;
const DIAL = 250;
const RADIUS = 100;
const TARGETS = [3, 5, 2, 8, 11, 6, 0];

export default function RotaryWheel({ ctx }: DemoProps) {
  const pitch = Math.max(ctx.n("pitch"), 1);
  const step = useRef(0);
  const scripted = useRef(false);
  const sc = useScroller({
    axis: "y",
    initial: COUNT * pitch,
    snap: strideSnap(pitch),
    onPhase: (p) => {
      if (p === "interacting") scripted.current = false;
      if (p !== "idle") return;
      // Jump a whole turn back into the middle copy: invisible, every turn looks the same.
      const notch = Math.round(sc.get() / pitch);
      const shift = notch < COUNT ? COUNT : notch >= COUNT * 2 ? -COUNT : 0;
      if (shift) sc.scrollTo((notch + shift) * pitch, null);
    },
  });
  const turns = sc.offset / pitch;
  const selected = wrap(Math.round(turns), COUNT);
  useSelectionTick(selected, ctx.isPreview, scripted);

  useAutoplay(
    ctx.isPreview,
    () => {
      const target = TARGETS[step.current % TARGETS.length];
      step.current += 1;
      scripted.current = true;
      sc.scrollTo((COUNT + target) * pitch, spring(0.8, 0.82));
    },
    { every: 1.3 },
  );

  const focus = ctx.n("focus");

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 14 }}>
      <div style={{ position: "relative", width: DIAL, height: DIAL, flexShrink: 0 }}>
        <div style={{ position: "absolute", inset: 0, borderRadius: "50%", background: Palette.elevated, boxShadow: `0 10px 18px ${black(0.12)}` }} />
        <svg
          width={164}
          height={164}
          style={{ position: "absolute", left: (DIAL - 164) / 2, top: (DIAL - 164) / 2, overflow: "visible", transform: `rotate(${-turns * 30}deg)` }}
        >
          <circle cx={82} cy={82} r={82} fill="none" stroke={Palette.labelAlpha(0.12)} strokeWidth={6} strokeDasharray="1.5 7.2" />
        </svg>
        <svg width={12} height={10} viewBox="0 0 12 10" style={{ position: "absolute", left: DIAL / 2 - 6, top: DIAL / 2 - RADIUS - 30 - 5 }}>
          <defs>
            <linearGradient id="rotary-tri" x1="0" y1="0" x2="1" y2="1">
              <stop offset="0" stopColor={Palette.indigo} />
              <stop offset="1" stopColor={Palette.violet} />
            </linearGradient>
          </defs>
          <path d="M1.2 0.5 H10.8 Q12 0.5 11.3 1.6 L6.9 9 Q6 10.2 5.1 9 L0.7 1.6 Q0 0.5 1.2 0.5 Z" fill="url(#rotary-tri)" />
        </svg>
        {Array.from({ length: COUNT }, (_, i) => {
          const radians = (((i - turns) * 30) * Math.PI) / 180;
          const on = i === selected;
          return (
            <div
              key={i}
              style={{
                position: "absolute",
                left: DIAL / 2 - 20 + RADIUS * Math.sin(radians),
                top: DIAL / 2 - 20 - RADIUS * Math.cos(radians),
                width: 40,
                height: 40,
                pointerEvents: "none",
              }}
            >
              <motion.div
                animate={{ scale: on ? focus : 1, opacity: on ? 1 : 0.85 }}
                transition={spring(0.3, 0.7)}
                style={{ position: "relative", width: 40, height: 40, borderRadius: "50%", boxShadow: on ? `0 0 10px ${alpha(Palette.violet, 0.5)}` : "none" }}
              >
                <ScrollKitIcon index={i} size={40} circle />
                <motion.div
                  animate={{ opacity: on ? 1 : 0 }}
                  transition={spring(0.3, 0.7)}
                  style={{
                    position: "absolute",
                    inset: -4,
                    borderRadius: "50%",
                    padding: 2.5,
                    background: Palette.primary,
                    WebkitMask: "linear-gradient(#000 0 0) content-box, linear-gradient(#000 0 0)",
                    WebkitMaskComposite: "xor",
                    maskComposite: "exclude",
                  }}
                />
              </motion.div>
            </div>
          );
        })}
        <div style={{ position: "absolute", inset: 0, display: "grid", placeItems: "center", pointerEvents: "none" }}>
          <FadeText text={ScrollKit.title(selected, ctx.lang)} duration={0.2} style={{ fontSize: 17, lineHeight: "22px", fontWeight: 600 }} />
        </div>
        <div {...sc.props} style={{ ...sc.props.style, position: "absolute", inset: 0, borderRadius: "50%", cursor: "grab" }}>
          <div ref={sc.contentRef} style={{ position: "relative", height: DIAL + pitch * (COUNT * COPIES - 1) }}>
            <SnapMarkers count={COUNT * COPIES} pitch={pitch} axis="y" />
          </div>
        </div>
      </div>
      <DemoHint ctx={ctx} en="Scroll up and down on the dial" zh="在转盘上上下滚动" />
    </div>
  );
}
