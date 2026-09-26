/** buttons.jelly-press · 果冻按压 (Buttons+JellyPress.swift) */
import { motion } from "motion/react";
import { Play } from "lucide-react";
import { useRef, useState } from "react";
import { DemoHint, Palette, spring, useAutoplay, useHaptics, useSilently, useTimeouts, type DemoProps } from "../../kit";
import { BOUNCY, cubicKF, springKF, track, trackDuration, useSince } from "./_a-kit";

export default function JellyPress({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const silently = useSilently();
  const { after } = useTimeouts();
  const [pressed, setPressed] = useState(false);
  const pressedRef = useRef(false);
  const [releases, setReleases] = useState(0);
  const pointer = useRef<number | null>(null);

  const press = () => {
    if (pressedRef.current) return;
    pressedRef.current = true;
    setPressed(true);
    haptics.tap("soft");
  };
  const cancelPress = () => {
    if (!pressedRef.current) return;
    pressedRef.current = false;
    setPressed(false);
  };
  const release = () => {
    if (!pressedRef.current) return;
    pressedRef.current = false;
    setPressed(false);
    setReleases((r) => r + 1);
    haptics.tap("light");
  };

  useAutoplay(ctx.isPreview, () => {
    press();
    after(0.28, () => silently(release));
  }, { every: 1.5, delay: 0.4 });

  const squash = ctx.n("squash");
  const stretch = ctx.n("stretch");
  const total = ctx.n("wobble");
  const yTrack = [
    cubicKF(1 + stretch, total * 0.18),
    cubicKF(1 - stretch * 0.35, total * 0.2),
    cubicKF(1 + stretch * 0.12, total * 0.2),
    springKF(1, total * 0.42, BOUNCY),
  ];
  const xTrack = [
    cubicKF(1 - stretch * 0.7, total * 0.18),
    cubicKF(1 + stretch * 0.35, total * 0.2),
    cubicKF(1 - stretch * 0.1, total * 0.2),
    springKF(1, total * 0.42, BOUNCY),
  ];
  const t = useSince(releases, trackDuration(yTrack));
  const kx = track(t, 1, xTrack);
  const ky = track(t, 1, yTrack);

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center" }}>
      <div style={{ flex: 1 }} />
      <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 18 }}>
        <div style={{ fontSize: 15, lineHeight: "20px", fontWeight: 600, color: Palette.secondaryLabel }}>{ctx.t("Lo-fi beats · 42 tracks", "Lo-fi 节拍 · 42 首")}</div>
        <div style={{ position: "relative", width: 240, height: 100, display: "flex", alignItems: "flex-end", justifyContent: "center" }}>
          <motion.div
            initial={false}
            animate={{ width: pressed ? 220 : 180, backgroundColor: pressed ? "rgba(0,0,0,0.22)" : "rgba(0,0,0,0.12)" }}
            transition={spring(0.25, 0.7)}
            style={{ position: "absolute", left: "50%", x: "-50%", bottom: -6, height: 14, borderRadius: "50%", filter: "blur(6px)" }}
          />
          <motion.div
            initial={false}
            animate={{ scaleX: pressed ? 1 + squash * 0.6 : 1, scaleY: pressed ? 1 - squash : 1 }}
            transition={spring(0.18, 0.8)}
            style={{ originY: 1, position: "relative" }}
          >
            <div
              role="button"
              onPointerDown={(e) => {
                if (pointer.current !== null) return;
                pointer.current = e.pointerId;
                e.currentTarget.setPointerCapture(e.pointerId);
                press();
              }}
              onPointerUp={(e) => {
                if (pointer.current !== e.pointerId) return;
                pointer.current = null;
                release();
              }}
              onPointerCancel={(e) => {
                if (pointer.current !== e.pointerId) return;
                pointer.current = null;
                cancelPress();
              }}
              style={{
                position: "relative",
                width: 210,
                height: 64,
                borderRadius: 32,
                background: `linear-gradient(135deg, ${Palette.mint}, ${Palette.sky})`,
                transform: `scale(${kx}, ${ky})`,
                transformOrigin: "50% 100%",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                gap: 10,
                color: "#fff",
                fontSize: 20,
                fontWeight: 700,
                cursor: "pointer",
                touchAction: "none",
              }}
            >
              <div style={{ position: "absolute", inset: 3, borderRadius: 32, background: "linear-gradient(rgb(255 255 255 / 0.35), transparent 50%)", pointerEvents: "none" }} />
              <motion.span initial={false} animate={{ y: pressed ? 3 : 0 }} transition={spring(0.4, 0.5)} style={{ display: "grid", position: "relative" }}>
                <Play size={19} fill="currentColor" strokeWidth={0} />
              </motion.span>
              <span style={{ position: "relative" }}>{ctx.lang === "zh" ? "播放" : "Play"}</span>
            </div>
          </motion.div>
        </div>
      </div>
      <div style={{ flex: 1 }} />
      <DemoHint ctx={ctx} en="Press and release the button" zh="按下按钮再松开" style={{ paddingBottom: 18 }} />
    </div>
  );
}
