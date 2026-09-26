/** inputs.merge-pin · 融合密码点 (Inputs+MergePin.swift) */
import { AnimatePresence, motion } from "motion/react";
import { Delete } from "lucide-react";
import { useRef, useState } from "react";
import { DemoHint, Palette, anim, delayed, fonts, spring, useAutoplay, useElapsed, useHaptics, type DemoProps } from "../../kit";
import { useLive, useSleep, useTask } from "./_b-common";

type Phase = "entering" | "merging" | "done" | "error";

const CODE = "2580";
const PITCH = 30;
const SCRIPT = ["1", "4", "7", "0", "", "", "", "", "", "2", "5", "8", "0", "", "", "", "", "", ""];
const KEYS = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "", "0", "⌫"];

export default function MergePin({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const sleep = useSleep();
  const intro = useTask();
  const [entered, setEntered, enteredRef] = useLive("");
  const [phase, setPhase, phaseRef] = useLive<Phase>("entering");
  const [shakes, setShakes] = useState(0);
  const [, setBusy, busyRef] = useLive(false);
  const scripted = useRef(false);
  const scriptIndex = useRef(0);

  const silent = () => ctx.isPreview || scripted.current;
  const merged = phase === "merging" || phase === "done";
  const done = phase === "done";
  const dotColor = phase === "error" ? Palette.red : Palette.indigo;

  const reset = () => {
    setEntered("");
    setPhase("entering");
    setBusy(false);
  };

  const verify = async () => {
    setBusy(true);
    const hold = ctx.n("hold");
    const quiet = silent();
    if (enteredRef.current === CODE) {
      await sleep(hold);
      setPhase("merging");
      await sleep(ctx.n("response") * 0.7);
      setPhase("done");
      setBusy(false);
      if (!quiet) haptics.success();
    } else {
      await sleep(0.12);
      setPhase("error");
      setShakes((s) => s + 1);
      if (!quiet) haptics.error();
      await sleep(0.5);
      for (let k = 0; k < 4; k++) {
        if (enteredRef.current) setEntered(enteredRef.current.slice(0, -1));
        await sleep(0.06);
      }
      setPhase("entering");
      setBusy(false);
    }
  };

  const press = (key: string) => {
    if (phaseRef.current === "done") return reset();
    if (phaseRef.current !== "entering" || busyRef.current) return;
    if (key === "⌫") {
      if (enteredRef.current) setEntered(enteredRef.current.slice(0, -1));
      return;
    }
    if (!silent()) haptics.tap();
    setEntered(enteredRef.current + key);
    if (enteredRef.current.length === 4) void verify();
  };

  const stopIntro = () => {
    if (!intro.running.current) return;
    intro.cancel();
    scripted.current = false;
    if (!busyRef.current && phaseRef.current === "entering") setEntered("");
  };

  const playIntro = () => {
    scripted.current = true;
    intro.start(async (wait) => {
      const typeScripted = async (text: string) => {
        for (const c of text) {
          if (!(await wait(0.28)) || busyRef.current || phaseRef.current !== "entering") return;
          press(c);
        }
      };
      await typeScripted("1470");
      if (!(await wait(1.1))) return;
      await typeScripted(CODE);
      if (!(await wait(1.8))) return;
      if (phaseRef.current === "done") reset();
      scripted.current = false;
    });
  };

  useAutoplay(
    ctx.isPreview,
    () => {
      if (!ctx.isPreview) return playIntro();
      const key = SCRIPT[scriptIndex.current % SCRIPT.length];
      scriptIndex.current += 1;
      if (scriptIndex.current % SCRIPT.length === 0) return reset();
      if (key) press(key);
    },
    { every: 0.3, delay: 0.4 },
  );

  // MergePinShake: travel · sin(f · 6π) · (1 − f) over one linear 0.45 s step.
  const shakeT = useElapsed(shakes, 0.45, true);
  const f = shakeT < 0 || shakeT >= 0.45 ? 0 : shakeT / 0.45;
  const shakeX = ctx.n("shake") * Math.sin(f * Math.PI * 6) * (1 - f);
  const colorT = "0.15s cubic-bezier(0.2, 0.9, 0.3, 1)";

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", gap: 16 }}>
      <div style={{ flex: 1 }} />
      <div style={{ position: "relative", display: "grid", fontSize: 17, lineHeight: "22px", fontWeight: 600, color: Palette.label }}>
        <AnimatePresence initial={false}>
          <motion.span
            key={done ? "done" : "enter"}
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            transition={anim.smooth}
            style={{ gridArea: "1 / 1", textAlign: "center", whiteSpace: "nowrap" }}
          >
            {done ? ctx.t("Unlocked", "已解锁") : ctx.t("Enter PIN", "输入密码")}
          </motion.span>
        </AnimatePresence>
      </div>
      <div style={{ position: "relative", width: 44, height: 48, transform: `translateX(${shakeX}px)` }}>
        {[0, 1, 2, 3].map((index) => {
          const filled = index < entered.length;
          const slot = (index - 1.5) * PITCH;
          return (
            <motion.div
              key={index}
              initial={false}
              animate={{ x: merged ? 0 : slot }}
              transition={spring(ctx.n("response"), 0.75)}
              style={{ position: "absolute", left: 14, top: 16, width: 16, height: 16 }}
            >
              <div
                style={{
                  position: "absolute",
                  inset: 0,
                  borderRadius: "50%",
                  boxShadow: `inset 0 0 0 1.5px ${phase === "error" ? "rgb(255 77 94 / 0.5)" : "rgb(110 123 255 / 0.5)"}`,
                  opacity: merged ? 0 : 1,
                  transition: `box-shadow ${colorT}`,
                }}
              />
              <motion.div
                initial={false}
                animate={{ scale: filled ? 1 : 0.3, opacity: filled ? 1 : 0 }}
                transition={spring(0.28, 0.55)}
                style={{ position: "absolute", inset: 0, borderRadius: "50%", background: dotColor, transition: `background-color ${colorT}` }}
              />
            </motion.div>
          );
        })}
        <motion.div
          initial={false}
          animate={{ scale: done ? 1 : 0.36, opacity: done ? 1 : 0, boxShadow: `0 4px 12px rgb(52 199 123 / ${done ? 0.45 : 0})` }}
          transition={spring(0.4, 0.6)}
          style={{ position: "absolute", left: 0, top: 2, width: 44, height: 44, borderRadius: "50%", background: Palette.green, display: "grid", placeItems: "center" }}
        >
          <svg width={20} height={16} viewBox="0 0 20 16" style={{ overflow: "visible" }}>
            <motion.path
              d="M0 8 L7.6 16 L20 0"
              fill="none"
              stroke="#fff"
              strokeWidth={3.5}
              strokeLinecap="round"
              strokeLinejoin="round"
              initial={false}
              animate={{ pathLength: done ? 1 : 0, opacity: done ? 1 : 0 }}
              transition={delayed(anim.easeOut(0.3), done ? 0.15 : 0)}
            />
          </svg>
        </motion.div>
      </div>
      <div style={{ width: 216, display: "grid", gridTemplateColumns: "repeat(3, 64px)", columnGap: 12, rowGap: 8 }}>
        {KEYS.map((key, index) =>
          key ? (
            <PinKey
              key={index}
              label={key}
              onPress={() => {
                if (busyRef.current) return;
                stopIntro();
                press(key);
              }}
            />
          ) : (
            <div key={index} style={{ height: 36 }} />
          ),
        )}
      </div>
      <div style={{ flex: 1 }} />
      <DemoHint ctx={ctx} en="PIN is 2 5 8 0" zh="密码为 2 5 8 0" style={{ paddingBottom: 10 }} />
    </div>
  );
}

function PinKey({ label, onPress }: { label: string; onPress: () => void }) {
  const [pressed, setPressed] = useState(false);
  const del = label === "⌫";
  return (
    <motion.button
      type="button"
      onPointerDown={() => setPressed(true)}
      onPointerUp={() => setPressed(false)}
      onPointerLeave={() => setPressed(false)}
      onPointerCancel={() => setPressed(false)}
      onClick={onPress}
      animate={{ scale: pressed ? 0.88 : 1, opacity: pressed ? 0.7 : 1 }}
      transition={spring(0.25, 0.6)}
      style={{
        width: 64,
        height: 36,
        borderRadius: 12,
        display: "grid",
        placeItems: "center",
        color: Palette.label,
        background: del ? "transparent" : Palette.labelAlpha(0.07),
        fontFamily: fonts.rounded,
        fontSize: 20,
        fontWeight: 600,
      }}
    >
      {del ? <Delete size={21} strokeWidth={2.2} /> : label}
    </motion.button>
  );
}
