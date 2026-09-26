/** inputs.pull-cord-toggle (Inputs+PullCordToggle.swift) */
import { animate, motion, useMotionValue, useTransform } from "motion/react";
import { useRef, useState } from "react";
import { DemoHint, Palette, anim, clamp, hex, rubberBand, spring, useAutoplay, useHaptics, usePan, useSilently, useTimeouts, type DemoProps } from "../../kit";

const REST = 80;

export default function PullCordToggle({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const silently = useSilently();
  const { after } = useTimeouts();
  const [isOn, setIsOn] = useState(false);
  const [armed, setArmed] = useState(false);
  const armedRef = useRef(false);
  const pull = useMotionValue(0);
  const sway = useMotionValue(0);
  const cordHeight = useTransform(pull, (p) => Math.max(REST + p, 20));

  const setArmedBoth = (v: boolean) => {
    armedRef.current = v;
    setArmed(v);
  };

  const settle = () => {
    const t = spring(ctx.n("response"), ctx.n("damping"));
    animate(pull, 0, t);
    animate(sway, 0, t);
    setArmedBoth(false);
  };

  const release = () => {
    const fire = armedRef.current;
    settle();
    if (fire) {
      haptics.tap();
      setIsOn((v) => !v);
    }
  };

  const pan = usePan({
    onChange: ({ translation }) => {
      const down = Math.max(translation.y, 0);
      pull.set(rubberBand(down, 110, 0.9));
      sway.set(clamp(-translation.x / 6, -12, 12));
      const past = pull.get() >= ctx.n("threshold");
      if (past && !armedRef.current) {
        haptics.tap("medium");
        setArmedBoth(true);
      } else if (!past && armedRef.current) setArmedBoth(false);
    },
    onEnd: () => release(),
  });

  useAutoplay(
    ctx.isPreview,
    () => {
      const e = anim.easeOut(0.35);
      animate(pull, ctx.n("threshold") + 10, e);
      animate(sway, 4, e);
      setArmedBoth(true);
      after(0.45, () => silently(release));
    },
    { every: 1.8, delay: 0.4 },
  );

  const lampT = anim.easeOut(isOn ? 0.35 : 0.2);

  return (
    <div style={{ position: "absolute", inset: 0 }}>
      {/* floor glow */}
      <div style={{ position: "absolute", left: 0, right: 0, bottom: 36, display: "flex", justifyContent: "center" }}>
        <motion.div
          initial={false}
          animate={{ opacity: isOn ? 1 : 0, scale: isOn ? 1 : 0.6 }}
          transition={anim.easeOut(isOn ? 0.45 : 0.2)}
          style={{
            width: 280,
            height: 70,
            borderRadius: "50%",
            background: `radial-gradient(circle 130px at 50% 50%, ${hex(0xffc247, 0.35)} 4px, transparent 130px)`,
          }}
        />
      </div>
      <div style={{ position: "absolute", left: 0, right: 0, top: 24, display: "flex", flexDirection: "column", alignItems: "center" }}>
        {/* shade + bulb */}
        <div style={{ position: "relative", width: 132, height: 58 }}>
          <motion.div
            initial={false}
            animate={{
              boxShadow: `0 0 14px ${hex(0xffc247, isOn ? 0.9 : 0)}`,
            }}
            transition={lampT}
            style={{
              position: "absolute",
              left: 66 - 13,
              bottom: -10,
              width: 26,
              height: 26,
              borderRadius: "50%",
              background: isOn ? "#FFE8A3" : Palette.labelAlpha(0.2),
              transition: `background-color ${isOn ? 0.35 : 0.2}s ease-out`,
            }}
          />
          <svg width={132} height={64} viewBox="0 0 132 64" style={{ position: "absolute", left: 0, top: 0, overflow: "visible", filter: "drop-shadow(0 4px 6px rgb(0 0 0 / 0.18))" }}>
            <defs>
              <linearGradient id="a-lampshade" x1="0" y1="0" x2="0" y2="1">
                <stop offset="0" stopColor={Palette.coral} />
                <stop offset="1" stopColor="#C94A36" />
              </linearGradient>
            </defs>
            <path d={shadePath(132, 58)} fill="url(#a-lampshade)" />
          </svg>
        </div>
        <div style={{ position: "relative", width: 280, height: 190 }}>
          <motion.svg
            initial={false}
            animate={{ opacity: isOn ? 1 : 0 }}
            transition={lampT}
            width={280}
            height={190}
            style={{ position: "absolute", left: 0, top: 0, pointerEvents: "none" }}
          >
            <defs>
              <linearGradient id="a-cone" x1="0" y1="0" x2="0" y2="1">
                <stop offset="0" stopColor={Palette.amber} stopOpacity={0.45} />
                <stop offset="1" stopColor={Palette.amber} stopOpacity={0} />
              </linearGradient>
            </defs>
            <path d={`M${280 * 0.26} 0 L${280 - 280 * 0.26} 0 L280 190 L0 190 Z`} fill="url(#a-cone)" />
          </motion.svg>
          {/* cord */}
          <motion.div
            style={{
              position: "absolute",
              top: 0,
              left: 140 + 34 - 10,
              width: 20,
              display: "flex",
              flexDirection: "column",
              alignItems: "center",
              rotate: sway,
              transformOrigin: "50% 0",
            }}
          >
            <motion.div style={{ width: 1.5, height: cordHeight, background: Palette.labelAlpha(0.45) }} />
            <div {...pan} style={{ ...pan.style, padding: 16, margin: -16, cursor: "grab" }}>
              <motion.div
                animate={{ scale: armed ? 1.15 : 1 }}
                transition={spring(0.2, 0.6)}
                style={{
                  width: 20,
                  height: 20,
                  borderRadius: "50%",
                  background: "radial-gradient(circle 14px at 35% 30%, #E2B07A 1px, #9C6B3E 14px)",
                  boxShadow: "0 2px 3px rgb(0 0 0 / 0.25)",
                }}
              />
            </div>
          </motion.div>
        </div>
      </div>
      <div style={{ position: "absolute", left: 0, right: 0, bottom: 0, display: "flex", justifyContent: "center" }}>
        <DemoHint ctx={ctx} en="Pull the cord down and let go" zh="向下拉绳子再松手" style={{ paddingBottom: 18 }} />
      </div>
    </div>
  );
}

function shadePath(w: number, h: number) {
  const ti = w * 0.28;
  return [
    `M${ti} 0`,
    `L${w - ti} 0`,
    `Q${w - ti * 0.3} ${h * 0.3} ${w} ${h}`,
    `Q${w / 2} ${h + 6} 0 ${h}`,
    `Q${ti * 0.3} ${h * 0.3} ${ti} 0`,
    "Z",
  ].join(" ");
}
