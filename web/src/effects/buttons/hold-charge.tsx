/** buttons.hold-charge · 蓄力发射 (Buttons+HoldCharge.swift) */
import { animate, motion, useMotionValue } from "motion/react";
import { useEffect, useRef, useState } from "react";
import { DemoHint, Palette, anim, spring, useAutoplay, useClock, useHaptics, useSilently, useTimeouts, type DemoProps } from "../../kit";
import { BOUNCY, cubicKF, linearKF, moveKF, springKF, track, useLongPress, useSince } from "./_a-kit";

/** SF Symbols `paperplane.fill`, pointing up-right in a 24 box. */
const PLANE = "M21.3 2.7 L3.2 9.8 C2.3 10.2 2.3 11.4 3.2 11.8 L9.9 14.1 L12.2 20.8 C12.6 21.7 13.8 21.7 14.2 20.8 Z";
const CREASE = "M21.1 2.9 L9.9 14.1";

export default function HoldCharge({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const silently = useSilently();
  const { after, clearAll } = useTimeouts();
  const [holdStart, setHoldStart] = useState<number | null>(null);
  const holdRef = useRef<number | null>(null);
  const squeeze = useMotionValue(1);
  const [launches, setLaunches] = useState(0);
  const [launching, setLaunching] = useState(false);
  const launchingRef = useRef(false);
  const script = useRef<(() => void) | null>(null);
  const duration = ctx.n("duration");

  const begin = () => {
    if (launchingRef.current) return;
    const now = performance.now() / 1000;
    holdRef.current = now;
    setHoldStart(now);
    haptics.tap("soft");
    animate(squeeze, ctx.n("squeeze"), anim.easeIn(duration));
  };
  const cancel = () => {
    if (holdRef.current === null) return;
    holdRef.current = null;
    setHoldStart(null);
    animate(squeeze, 1, spring(0.4, 0.5));
  };
  const launch = (muted = false) => {
    if (launchingRef.current) return;
    holdRef.current = null;
    setHoldStart(null);
    launchingRef.current = true;
    setLaunching(true);
    animate(squeeze, 1, spring(0.35, 0.55));
    setLaunches((l) => l + 1);
    if (!muted) haptics.tap("heavy");
    after(0.25, () => {
      if (!muted) haptics.success();
      after(1.2, () => {
        launchingRef.current = false;
        setLaunching(false);
      });
    });
  };
  const cancelScript = () => {
    script.current?.();
    script.current = null;
  };

  const longPress = useLongPress({
    duration,
    maximumDistance: 50,
    onComplete: () => launch(),
    onPressingChanged: (isPressing) => {
      cancelScript();
      if (isPressing) begin();
      else cancel();
    },
  });

  useAutoplay(ctx.isPreview, () => {
    if (launchingRef.current) return;
    begin();
    cancelScript();
    script.current = after(duration, () => {
      script.current = null;
      silently(() => launch(true));
    });
  }, { every: duration + 2.2, delay: 0.4 });
  useEffect(() => () => clearAll(), [clearAll]);

  useClock(holdStart !== null, ctx.isPreview ? 30 : undefined);
  const now = performance.now() / 1000;
  const charge = holdStart === null ? 0 : Math.min(Math.max((now - holdStart) / Math.max(duration, 0.1), 0), 1);
  const maxShake = ctx.n("shake");
  const jitterX = Math.sin(now * 251) * maxShake * charge;
  const jitterY = Math.cos(now * 197) * maxShake * charge * 0.6;
  const wobble = Math.sin(now * 90) * 2 * charge;
  const glow = 10 + 20 * charge;

  const t = useSince(launches, 1.7);
  const pop = track(t, 1, [cubicKF(1.15, 0.12), springKF(1, 0.5, BOUNCY)]);
  const rise = track(t, 0, [cubicKF(-6, 0.1), cubicKF(140, 0.45), moveKF(60), linearKF(60, 0.6), springKF(0, 0.5, BOUNCY)]);
  const rocketOpacity = track(t, 1, [linearKF(1, 0.3), linearKF(0, 0.25), linearKF(0, 0.6), linearKF(1, 0.2)]);
  const trail = track(t, 0, [linearKF(0, 0.1), cubicKF(1, 0.2), cubicKF(0, 0.3)]);

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center" }}>
      <div style={{ flex: 1 }} />
      <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 22 }}>
        <div {...longPress} style={{ ...longPress.style, position: "relative", width: 200, height: 200, display: "grid", placeItems: "center" }}>
          <motion.div style={{ scale: squeeze }}>
            <div
              style={{
                position: "relative",
                width: 120,
                height: 120,
                transform: `translate(${jitterX}px, ${jitterY}px) rotate(${wobble}deg) scale(${pop})`,
              }}
            >
              <div
                style={{
                  position: "absolute",
                  inset: 0,
                  borderRadius: 34,
                  background: `linear-gradient(135deg, ${Palette.violet}, ${Palette.pink})`,
                  boxShadow: `inset 0 0 0 1px rgb(255 255 255 / 0.25), 0 8px ${glow}px rgb(255 95 162 / ${0.35 + 0.35 * charge})`,
                }}
              />
              <div style={{ position: "absolute", inset: 0, display: "grid", placeItems: "center" }}>
                <div style={{ position: "relative", width: 44, height: 44, transform: `translateY(${-rise}px)`, opacity: rocketOpacity }}>
                  <svg viewBox="0 0 24 24" width={44} height={44} style={{ transform: "rotate(-45deg)" }}>
                    <path d={PLANE} fill="#fff" />
                    <path d={CREASE} stroke="rgb(214 102 208)" strokeWidth={1.1} strokeLinecap="round" />
                  </svg>
                  <div
                    style={{
                      position: "absolute",
                      left: 22 - 4,
                      top: 44,
                      width: 8,
                      height: 60 * trail,
                      borderRadius: 4,
                      background: `linear-gradient(rgb(255 194 71 / 0.9), rgb(255 95 162 / 0))`,
                      opacity: trail,
                    }}
                  />
                </div>
              </div>
            </div>
          </motion.div>
        </div>
        <motion.div
          key={launching ? "go" : "hold"}
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={anim.smoothD(0.25)}
          style={{ fontSize: 17, lineHeight: "22px", fontWeight: 600, color: launching ? Palette.pink : Palette.secondaryLabel }}
        >
          {launching ? ctx.t("Liftoff!", "发射！") : ctx.t("Hold to launch", "长按发射")}
        </motion.div>
      </div>
      <div style={{ flex: 1 }} />
      <DemoHint ctx={ctx} en="Hold until it launches" zh="一直按住直到发射" style={{ paddingBottom: 18 }} />
    </div>
  );
}
