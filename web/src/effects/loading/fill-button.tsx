/** loading.fill-button · 进度填充按钮 (Loading+ButtonVariations.swift) */
import { motion } from "motion/react";
import { useEffect, useRef, useState } from "react";
import { DemoHint, NumericText, Palette, alpha, pressHandlers, spring, useAutoplay, useHaptics, type DemoProps } from "../../kit";
import { popScale } from "./bar-shared";
import { makeRun, springSmooth, useAnimatedNumber, useTriggerElapsed, type Run } from "./shared";

type State = "idle" | "loading" | "done";
const W = 250;

export default function FillButton({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [state, setState] = useState<State>("idle");
  const [pops, setPops] = useState(0);
  const [pressed, setPressed] = useState(false);
  const progress = useAnimatedNumber(0);
  const stateRef = useRef<State>("idle");
  stateRef.current = state;
  const task = useRef<Run | null>(null);
  const muted = useRef(false);
  useEffect(() => () => task.current?.cancel(), []);

  const tap = () => {
    task.current?.cancel();
    if (stateRef.current !== "idle") {
      setState("idle");
      progress.to(0, springSmooth(0.4));
      return;
    }
    haptics.tap("medium");
    setState("loading");
    const speed = ctx.n("speed");
    const quiet = muted.current;
    const loops = ctx.isPreview;
    const run = makeRun();
    task.current = run;
    (async () => {
      await run.sleep(0.3);
      while (progress.target.current < 1) {
        const step = (0.05 + Math.random() * 0.09) * speed;
        progress.to(Math.min(1, progress.target.current + step), springSmooth(0.45));
        await run.sleep(0.2 + Math.random() * 0.18);
      }
      setState("done");
      setPops((p) => p + 1);
      if (!quiet) haptics.success();
      if (!loops) return;
      await run.sleep(1.5);
      setState("idle");
      progress.to(0, springSmooth(0.4));
    })().catch(() => {});
  };

  useAutoplay(
    ctx.isPreview,
    () => {
      if (stateRef.current !== "idle") return;
      muted.current = true;
      tap();
      muted.current = false;
    },
    { every: 1.0, delay: 0.5 },
  );

  const zh = ctx.lang === "zh";
  const percent = Math.round(progress.target.current * 100);
  const title = state === "idle" ? (zh ? "下载 · 1.2 GB" : "Download · 1.2 GB") : state === "loading" ? `${zh ? "正在下载 " : "Downloading "}${percent}%` : zh ? "打开" : "Open";
  const done = state === "done";
  const fillWidth = W * progress.value;
  const pop = popScale(useTriggerElapsed(pops, 0.7), 1.05, 0.14);
  const label = (color: string) => (
    <div style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center", color, fontSize: 17, fontWeight: 600, fontVariantNumeric: "tabular-nums", whiteSpace: "pre" }}>
      <NumericText value={percent} text={title} />
    </div>
  );
  const ease = "0.3s cubic-bezier(0.42,0,0.58,1)";

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 22 }}>
      <div style={{ transform: `scale(${pop})` }}>
        <motion.button
          type="button"
          onClick={tap}
          {...pressHandlers(setPressed)}
          animate={{ scale: pressed ? 0.96 : 1 }}
          transition={spring(0.28, 0.6)}
          style={{ display: "block" }}
        >
          <div
            style={{
              position: "relative",
              width: W,
              height: 56,
              borderRadius: 28,
              boxShadow: `0 6px 12px ${alpha(done ? Palette.green : Palette.indigo, 0.25)}`,
              transition: `box-shadow ${ease}`,
            }}
          >
            <div style={{ position: "absolute", inset: 0, borderRadius: 28, overflow: "hidden", background: alpha(Palette.indigo, 0.1) }}>
              <div style={{ position: "absolute", left: 0, top: 0, bottom: 0, width: fillWidth, background: Palette.primary }} />
              <div style={{ position: "absolute", inset: 0, background: Palette.successStrong, opacity: done ? 1 : 0, transition: `opacity ${ease}` }} />
              {label(done ? "#fff" : Palette.indigo)}
              <div style={{ position: "absolute", left: 0, top: 0, bottom: 0, width: ctx.b("invert") ? fillWidth : 0, overflow: "hidden", opacity: done ? 0 : 1, transition: `opacity ${ease}` }}>
                <div style={{ position: "relative", width: W, height: 56 }}>{label("#fff")}</div>
              </div>
            </div>
            <div
              style={{
                position: "absolute",
                inset: 0,
                borderRadius: 28,
                boxShadow: `inset 0 0 0 1.5px ${done ? Palette.green : alpha(Palette.indigo, 0.5)}`,
                transition: `box-shadow ${ease}`,
                pointerEvents: "none",
              }}
            />
          </div>
        </motion.button>
      </div>
      <DemoHint ctx={ctx} en="Tap the button" zh="点击按钮" />
    </div>
  );
}
