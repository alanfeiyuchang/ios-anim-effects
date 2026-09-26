/** inputs.otp-code (Inputs+OTPCode.swift) */
import { AnimatePresence, animate, motion, useMotionValue, useTransform } from "motion/react";
import { useEffect, useRef, useState } from "react";
import { DemoHint, Palette, alpha, anim, ease, fonts, progress, spring, springAt, useAutoplay, useElapsed, useHaptics, useTimeouts, type DemoProps } from "../../kit";
import { fieldInputStyle } from "./_a-common";

type Status = "idle" | "error" | "success";

export default function OTPCode({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const { after } = useTimeouts();
  const length = ctx.i("digits") === 0 ? 4 : 6;
  const expected = "123456".slice(0, length);
  const spaced = expected.split("").join(" ");
  const wrongCode = "123999".slice(0, length - 1) + "0";

  const [code, setCodeState] = useState("");
  const [status, setStatusState] = useState<Status>("idle");
  const [successes, setSuccesses] = useState(0);
  const [focused, setFocused] = useState(false);
  const [scripted, setScripted] = useState(false);
  const codeRef = useRef("");
  const statusRef = useRef<Status>("idle");
  const scriptedRef = useRef(false);
  const holdTicks = useRef(0);
  const scriptIndex = useRef(0);
  const introRun = useRef(0);
  const input = useRef<HTMLInputElement>(null);
  const shake = useMotionValue(0);
  const shakeX = useTransform(shake, (p) => {
    const f = p - Math.floor(p);
    return ctx.n("shake") * Math.sin(f * Math.PI * 6) * (1 - f);
  });

  const setCode = (c: string) => {
    codeRef.current = c;
    setCodeState(c);
  };
  const setStatus = (s: Status) => {
    statusRef.current = s;
    setStatusState(s);
  };
  const reset = () => {
    setCode("");
    setStatus("idle");
  };

  const verify = (digits: string) => {
    if (digits === expected) {
      setStatus("success");
      setSuccesses((s) => s + 1);
      holdTicks.current = 5;
      input.current?.blur();
      if (!scriptedRef.current) haptics.success();
    } else {
      setStatus("error");
      animate(shake, Math.floor(shake.get()) + 1, anim.linear(0.45));
      if (!scriptedRef.current) haptics.error();
      after(0.6, () => {
        if (statusRef.current !== "error") return;
        reset();
      });
    }
  };

  const handle = (value: string) => {
    const digits = value.replace(/\D/g, "").slice(0, length);
    setCode(digits);
    if (digits.length === length && statusRef.current === "idle") verify(digits);
  };

  useEffect(() => {
    reset();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [length]);

  const stopIntro = () => {
    if (!scriptedRef.current) return;
    introRun.current += 1;
    scriptedRef.current = false;
    setScripted(false);
    if (statusRef.current !== "error") reset();
  };

  const playIntro = () => {
    introRun.current += 1;
    const run = introRun.current;
    scriptedRef.current = true;
    setScripted(true);
    const type = (text: string, start: number) => {
      text.split("").forEach((ch, i) =>
        after(start + 0.22 * (i + 1), () => {
          if (run !== introRun.current || statusRef.current !== "idle") return;
          handle(codeRef.current + ch);
        }),
      );
      return start + 0.22 * text.length;
    };
    let t = type(wrongCode, 0);
    t = type(expected, t + 0.9);
    after(t + 1.6, () => {
      if (run !== introRun.current) return;
      reset();
      scriptedRef.current = false;
      setScripted(false);
    });
  };

  const previewTick = () => {
    if (holdTicks.current > 0) {
      holdTicks.current -= 1;
      if (holdTicks.current === 0) reset();
      return;
    }
    if (statusRef.current !== "idle" || codeRef.current.length >= length) return;
    const script = wrongCode + expected;
    const next = script[scriptIndex.current % script.length];
    scriptIndex.current += 1;
    handle(codeRef.current + next);
  };

  useAutoplay(ctx.isPreview, () => (ctx.isPreview ? previewTick() : playIntro()), { every: 0.32, delay: 0.5 });

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", gap: 26 }}>
      <input
        ref={input}
        value={code}
        inputMode="numeric"
        autoComplete="one-time-code"
        onChange={(e) => handle(e.target.value)}
        onFocus={() => setFocused(true)}
        onBlur={() => setFocused(false)}
        style={{ ...fieldInputStyle, position: "absolute", left: 0, top: 0, width: 1, height: 1, opacity: 0.01, fontSize: 16, pointerEvents: "none" }}
      />
      <div style={{ flex: 1 }} />
      <motion.div
        onClick={() => {
          stopIntro();
          if (statusRef.current === "success") reset();
          input.current?.focus();
        }}
        style={{ x: shakeX, display: "flex", gap: 8, cursor: "text" }}
      >
        {Array.from({ length }, (_, index) => (
          <Box
            key={index}
            character={code[index]}
            isCurrent={(focused || ctx.isPreview || scripted) && status === "idle" && index === code.length}
            status={status}
            index={index}
            successes={successes}
            pop={ctx.n("pop")}
          />
        ))}
      </motion.div>
      <DemoHint ctx={ctx} en={`Tap the boxes · correct code is ${spaced}`} zh={`点击格子输入 · 正确验证码为 ${spaced}`} />
      <div style={{ flex: 1 }} />
    </div>
  );
}

function Box({ character, isCurrent, status, index, successes, pop }: { character?: string; isCurrent: boolean; status: Status; index: number; successes: number; pop: number }) {
  const border =
    status === "error"
      ? Palette.red
      : status === "success"
        ? Palette.green
        : isCurrent
          ? Palette.indigo
          : character === undefined
            ? Palette.labelAlpha(0.12)
            : Palette.labelAlpha(0.3);
  const glow = isCurrent ? alpha(Palette.indigo, 0.25) : "rgb(0 0 0 / 0)";
  const lead = 0.001 + index * 0.05;
  const t = useElapsed(successes, lead + 0.61, true);
  let lift = 0;
  if (t > lead && t < lead + 0.61) {
    if (t < lead + 0.16) lift = -10 * ease.out(progress(t, lead, 0.16));
    else lift = -10 + 10 * springAt(t - lead - 0.16, 0.45, 0.7);
  }
  return (
    <motion.div
      initial={false}
      animate={{ scale: isCurrent ? 1.06 : 1, boxShadow: `0 4px 8px ${glow}` }}
      transition={spring(0.3, 0.7)}
      style={{ position: "relative", width: 44, height: 54, borderRadius: 12, background: Palette.elevated, y: lift }}
    >
      <div
        style={{
          position: "absolute",
          inset: 0,
          borderRadius: 12,
          boxShadow: `inset 0 0 0 ${isCurrent || status !== "idle" ? 2 : 1}px ${border}`,
          transition: "box-shadow 0.3s cubic-bezier(0.2, 0.9, 0.3, 1)",
        }}
      />
      <div style={{ position: "absolute", inset: 0, display: "grid", placeItems: "center" }}>
        <AnimatePresence initial={false}>
          {character !== undefined ? (
            <motion.span
              key={`c-${character}`}
              initial={{ scale: pop, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              exit={{ scale: pop, opacity: 0 }}
              transition={spring(0.3, 0.6)}
              style={{ gridArea: "1 / 1", fontFamily: fonts.rounded, fontSize: 24, fontWeight: 600, fontVariantNumeric: "tabular-nums" }}
            >
              {character}
            </motion.span>
          ) : isCurrent ? (
            <motion.div
              key="caret"
              initial={{ opacity: 1 }}
              animate={{ opacity: [1, 0] }}
              exit={{ opacity: 0, transition: { duration: 0 } }}
              transition={{ duration: 0.5, ease: [0.42, 0, 0.58, 1], repeat: Infinity, repeatType: "reverse" }}
              style={{ gridArea: "1 / 1", width: 2, height: 24, borderRadius: 1, background: Palette.indigo }}
            />
          ) : null}
        </AnimatePresence>
      </div>
    </motion.div>
  );
}
