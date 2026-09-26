/** inputs.passcode-pad · 密码键盘 (Inputs+PasscodePad.swift) */
import { AnimatePresence, motion } from "motion/react";
import { Delete } from "lucide-react";
import { useRef, useState } from "react";
import { DemoHint, Palette, anim, delayed, fonts, spring, useAutoplay, useHaptics, useTimeouts, type DemoProps } from "../../kit";
import { LockGlyph, useLive, useSleep, useTask, SYMBOL_REPLACE } from "./_b-common";

type Status = "idle" | "error" | "success";

const CODE = "2580";
const WRONG = "1379";
const SCRIPT: (string | null)[] = ["1", "3", "7", "9", null, null, null, "2", "5", "8", "0", null, null, null, null];
const KEYS = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "", "0", "del"];
const LETTERS = ["", "ABC", "DEF", "GHI", "JKL", "MNO", "PQRS", "TUV", "WXYZ", "", "", ""];
const KEY = 54;

export default function PasscodePad({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const { after } = useTimeouts();
  const sleep = useSleep();
  const intro = useTask();
  const [entered, setEntered, enteredRef] = useLive("");
  const [status, setStatus] = useState<Status>("idle");
  const [statusT, setStatusT] = useState(anim.easeOut(0.15));
  const busy = useRef(false);
  const [dropping, setDropping] = useState(false);
  const [flashed, setFlashed, flashedRef] = useLive<string | null>(null);
  const scripted = useRef(false);
  const step = useRef(0);

  const silent = () => ctx.isPreview || scripted.current;
  const dotColor = status === "idle" ? Palette.label : status === "error" ? Palette.red : Palette.green;
  const dotRGB = status === "idle" ? "rgb(var(--ml-label-rgb) / 0.8)" : status === "error" ? "rgb(255 77 94 / 0.8)" : "rgb(52 199 123 / 0.8)";

  const evaluate = async () => {
    busy.current = true;
    const correct = enteredRef.current === CODE;
    const quiet = silent();
    await sleep(0.18);
    if (correct) {
      if (!quiet) haptics.success();
      setStatusT(spring(0.4, 0.6));
      setStatus("success");
      await sleep(1.3);
    } else {
      if (!quiet) haptics.error();
      setStatusT(anim.easeOut(0.15));
      setStatus("error");
      setDropping(true);
      await sleep(0.75);
    }
    setDropping(false);
    setEntered("");
    setStatusT(anim.smoothD(0.3));
    setStatus("idle");
    busy.current = false;
  };

  const press = (digit: string) => {
    if (busy.current || enteredRef.current.length >= 4) return;
    if (!silent()) haptics.tap();
    setEntered(enteredRef.current + digit);
    if (enteredRef.current.length === 4) void evaluate();
  };

  const deleteLast = () => {
    if (busy.current || !enteredRef.current) return;
    if (!silent()) haptics.selection();
    setEntered(enteredRef.current.slice(0, -1));
  };

  const flash = (digit: string) => {
    setFlashed(digit);
    press(digit);
    after(0.14, () => flashedRef.current === digit && setFlashed(null));
  };

  const stopIntro = () => {
    if (!intro.running.current) return;
    intro.cancel();
    scripted.current = false;
    setFlashed(null);
    if (!busy.current) setEntered("");
  };

  const playIntro = () => {
    scripted.current = true;
    intro.start(async (wait) => {
      const typeScripted = async (text: string) => {
        for (const c of text) {
          if (!(await wait(0.3)) || busy.current) return;
          flash(c);
        }
      };
      await typeScripted(WRONG);
      if (!(await wait(1.2))) return;
      await typeScripted(CODE);
      if (!(await wait(1.8))) return;
      scripted.current = false;
    });
  };

  useAutoplay(
    ctx.isPreview,
    () => {
      if (!ctx.isPreview) return playIntro();
      const item = SCRIPT[step.current % SCRIPT.length];
      step.current += 1;
      if (item) flash(item);
    },
    { every: 0.32, delay: 0.5 },
  );

  const title = status === "idle" ? ctx.t("Enter passcode", "输入密码") : status === "error" ? ctx.t("Try again", "密码错误") : ctx.t("Unlocked", "已解锁");

  return (
    <div style={{ position: "absolute", inset: 0, paddingTop: 16, display: "flex", flexDirection: "column", alignItems: "center" }}>
      <div style={{ flex: 1 }} />
      <div style={{ display: "flex", alignItems: "center", gap: 8, fontSize: 17, lineHeight: "22px", fontWeight: 600, color: Palette.label }}>
        <span style={{ position: "relative", width: 14, height: 17, color: status === "success" ? Palette.green : Palette.label }}>
          <AnimatePresence initial={false}>
            <motion.span
              key={status === "success" ? "open" : "closed"}
              {...SYMBOL_REPLACE}
              style={{ position: "absolute", left: 0, top: 0, display: "block" }}
            >
              <LockGlyph open={status === "success"} size={17} />
            </motion.span>
          </AnimatePresence>
        </span>
        <span style={{ position: "relative", display: "grid" }}>
          <AnimatePresence initial={false}>
            <motion.span
              key={title}
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              transition={statusT}
              style={{ gridArea: "1 / 1", whiteSpace: "nowrap" }}
            >
              {title}
            </motion.span>
          </AnimatePresence>
        </span>
      </div>
      <div style={{ display: "flex", gap: 18, marginTop: 12, marginBottom: 20 }}>
        {[0, 1, 2, 3].map((index) => {
          const filled = index < entered.length;
          const fall = dropping ? ctx.n("fall") : 0;
          const tip = dropping ? (index % 2 === 0 ? -40 : 34) : 0;
          return (
            <div key={index} style={{ position: "relative", width: 13, height: 13 }}>
              <div style={{ position: "absolute", inset: 0, borderRadius: "50%", boxShadow: `inset 0 0 0 1.5px ${dotRGB}`, transition: "box-shadow 0.2s ease-out" }} />
              <motion.div
                initial={false}
                animate={{ y: fall, rotate: tip, opacity: dropping ? 0 : 1 }}
                transition={dropping ? delayed(anim.easeIn(0.42), index * 0.05) : { duration: 0 }}
                style={{ position: "absolute", inset: 0, originY: 1 }}
              >
                <motion.div
                  initial={false}
                  animate={{ scale: filled ? 1 : 0.85, opacity: filled ? 1 : 0 }}
                  transition={dropping || !filled ? { duration: 0 } : spring(0.3, ctx.n("damping"))}
                  style={{ position: "absolute", inset: 0, borderRadius: "50%", background: dotColor, transition: "background-color 0.2s ease-out" }}
                />
              </motion.div>
            </div>
          );
        })}
      </div>
      <div style={{ display: "grid", gridTemplateColumns: `repeat(3, ${KEY}px)`, columnGap: 18, rowGap: 12 }}>
        {KEYS.map((label, index) => {
          if (!label) return <div key={index} style={{ width: KEY, height: KEY }} />;
          if (label === "del")
            return (
              <button
                key={index}
                type="button"
                onClick={() => {
                  stopIntro();
                  deleteLast();
                }}
                style={{ width: KEY, height: KEY, borderRadius: "50%", display: "grid", placeItems: "center", color: Palette.label, opacity: entered ? 1 : 0.3 }}
              >
                <Delete size={24} strokeWidth={1.8} />
              </button>
            );
          return (
            <Key
              key={index}
              label={label}
              letters={LETTERS[index]}
              forced={flashed === label}
              fade={ctx.n("fade")}
              onPress={() => {
                stopIntro();
                press(label);
              }}
            />
          );
        })}
      </div>
      <div style={{ flex: 1 }} />
      <DemoHint ctx={ctx} en="Passcode is 2580" zh="密码是 2580" style={{ paddingTop: 10, paddingBottom: 12 }} />
    </div>
  );
}

/** Backlit-glass key: the fill jumps up on touch and fades out slowly on release. */
function Key({ label, letters, forced, fade, onPress }: { label: string; letters: string; forced: boolean; fade: number; onPress: () => void }) {
  const [pressed, setPressed] = useState(false);
  const lit = pressed || forced;
  return (
    <button
      type="button"
      onPointerDown={() => setPressed(true)}
      onPointerUp={() => setPressed(false)}
      onPointerLeave={() => setPressed(false)}
      onPointerCancel={() => setPressed(false)}
      onClick={onPress}
      style={{
        width: KEY,
        height: KEY,
        borderRadius: "50%",
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        justifyContent: "center",
        color: Palette.label,
        background: Palette.labelAlpha(lit ? 0.26 : 0.07),
        transition: lit ? "none" : `background-color ${fade}s cubic-bezier(0, 0, 0.58, 1)`,
      }}
    >
      <span style={{ fontFamily: fonts.rounded, fontSize: 26, fontWeight: 400, lineHeight: "31px" }}>{label}</span>
      {letters && <span style={{ fontSize: 8, lineHeight: "10px", fontWeight: 700, letterSpacing: 1.2, color: Palette.secondaryLabel, marginRight: -1.2 }}>{letters}</span>}
    </button>
  );
}
