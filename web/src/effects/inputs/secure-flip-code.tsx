/** inputs.secure-flip-code · 翻牌密码 (Inputs+SecureFlipCode.swift) */
import { AnimatePresence, motion } from "motion/react";
import { Eye, EyeOff } from "lucide-react";
import { useRef, useState } from "react";
import { DemoHint, Palette, anim, delayed, fonts, mix, springAt, useAutoplay, useElapsed, useHaptics, useTimeouts, type DemoProps } from "../../kit";
import { SYMBOL_REPLACE, TextInputStyles, useLive, useTask } from "./_b-common";

const LENGTH = 4;
const SCRIPT = ["7", "", "3", "", "9", "", "1", "", "", "", "👁", "", "", "", "👁", "", "", "⌧", ""];

export default function SecureFlipCode({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const { after } = useTimeouts();
  const intro = useTask();
  const [code, setCodeState, codeRef] = useLive("");
  const [masked, setMasked, maskedRef] = useLive<Set<number>>(new Set());
  const [peeking, setPeeking, peekingRef] = useLive(false);
  const [staggerFlips, setStaggerFlips] = useState(false);
  const [completions, setCompletions] = useState(0);
  const [focused, setFocused] = useState(false);
  const slotGeneration = useRef<Record<number, number>>({});
  const scriptIndex = useRef(0);
  const input = useRef<HTMLInputElement>(null);

  /** `onChange(of: code)` */
  const setCode = (next: string, muted: boolean) => {
    const old = codeRef.current;
    const digits = next.replace(/\D/g, "").slice(0, LENGTH);
    setCodeState(digits);
    if (digits.length < old.length) {
      setMasked(new Set([...maskedRef.current].filter((i) => i < digits.length)));
      return;
    }
    if (digits.length <= old.length) return;
    const index = digits.length - 1;
    if (!muted) haptics.selection();
    const generation = (slotGeneration.current[index] ?? 0) + 1;
    slotGeneration.current[index] = generation;
    after(ctx.n("reveal"), () => {
      if (index >= codeRef.current.length || slotGeneration.current[index] !== generation) return;
      setStaggerFlips(false);
      setMasked(new Set([...maskedRef.current, index]));
    });
    if (digits.length === LENGTH) {
      setCompletions((c) => c + 1);
      if (!muted) haptics.success();
    }
  };

  const reset = () => {
    setCodeState("");
    setMasked(new Set());
    setPeeking(false);
  };

  const previewTick = () => {
    const key = SCRIPT[scriptIndex.current % SCRIPT.length];
    scriptIndex.current += 1;
    if (key === "") return;
    if (key === "👁") {
      setStaggerFlips(true);
      setPeeking(!peekingRef.current);
    } else if (key === "⌧") reset();
    else if (codeRef.current.length < LENGTH) setCode(codeRef.current + key, true);
  };

  const playIntro = () => {
    scriptIndex.current = 0;
    intro.start(async (sleep) => {
      for (let k = 0; k < SCRIPT.length; k++) {
        previewTick();
        if (!(await sleep(0.35))) return;
      }
    });
  };

  const takeOver = () => {
    if (!intro.running.current) return;
    intro.cancel();
    reset();
  };

  useAutoplay(ctx.isPreview, () => (ctx.isPreview ? previewTick() : playIntro()), { every: 0.35, delay: 0.4 });

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", gap: 22 }}>
      <TextInputStyles />
      <div style={{ flex: 1 }} />
      <span style={{ fontSize: 17, lineHeight: "22px", fontWeight: 600, color: Palette.label }}>{ctx.t("Card PIN", "银行卡密码")}</span>
      <div
        onClick={() => {
          takeOver();
          if (codeRef.current.length === LENGTH) reset();
          input.current?.focus();
        }}
        style={{ position: "relative", display: "flex", alignItems: "center", gap: 10, cursor: "text" }}
      >
        {Array.from({ length: LENGTH }, (_, index) => (
          <FlipTile
            key={index}
            digit={index < code.length ? code[index] : null}
            showsBack={masked.has(index) && !peeking}
            halfFlip={ctx.n("flip")}
            delay={staggerFlips ? index * ctx.n("stagger") : 0}
            isCurrent={index === code.length && (focused || ctx.isPreview)}
            complete={code.length === LENGTH}
            index={index}
            completions={completions}
          />
        ))}
        <button
          type="button"
          onClick={(e) => {
            e.stopPropagation();
            takeOver();
            if (!ctx.isPreview) haptics.tap();
            setStaggerFlips(true);
            setPeeking(!peekingRef.current);
          }}
          style={{ position: "relative", width: 40, height: 40, borderRadius: "50%", background: Palette.labelAlpha(0.06), color: peeking ? Palette.indigo : Palette.secondaryLabel }}
        >
          <AnimatePresence initial={false}>
            <motion.span key={peeking ? "eye" : "slash"} {...SYMBOL_REPLACE} style={{ position: "absolute", inset: 0, display: "grid", placeItems: "center" }}>
              {peeking ? <Eye size={19} strokeWidth={2.4} /> : <EyeOff size={19} strokeWidth={2.4} />}
            </motion.span>
          </AnimatePresence>
        </button>
        {!ctx.isPreview && (
          <input
            ref={input}
            className="ml-b-input"
            value={code}
            inputMode="numeric"
            autoComplete="off"
            aria-label={ctx.t("Card PIN", "银行卡密码")}
            onChange={(e) => setCode(e.target.value, false)}
            onFocus={() => setFocused(true)}
            onBlur={() => setFocused(false)}
            style={{ position: "absolute", left: 0, top: 0, width: 1, height: 1, opacity: 0.01, fontSize: 16, pointerEvents: "none" }}
          />
        )}
      </div>
      <div style={{ flex: 1 }} />
      <DemoHint ctx={ctx} en="Tap the tiles and type" zh="点击方块开始输入" style={{ paddingBottom: 18 }} />
    </div>
  );
}

function FlipTile({
  digit,
  showsBack,
  halfFlip,
  delay,
  isCurrent,
  complete,
  index,
  completions,
}: {
  digit: string | null;
  showsBack: boolean;
  halfFlip: number;
  delay: number;
  isCurrent: boolean;
  complete: boolean;
  index: number;
  completions: number;
}) {
  // keyframeAnimator(trigger: completions): hold `lead`, snap up 6 pt, bounce back.
  const lead = 0.001 + index * 0.06;
  const t = useElapsed(completions, lead + 0.16 + 0.45, true);
  let lift = 0;
  if (t > lead) {
    const up = t - lead;
    lift = up < 0.16 ? mix(0, -6, springAt(up, 0.5, 0.85)) : mix(mix(0, -6, springAt(0.16, 0.5, 0.85)), 0, springAt(up - 0.16, 0.5, 0.7));
  }
  const border = complete ? Palette.green : isCurrent ? Palette.indigo : Palette.labelAlpha(0.14);
  return (
    <div
      style={{
        position: "relative",
        width: 54,
        height: 64,
        borderRadius: 14,
        background: Palette.elevated,
        transform: `translateY(${lift}px)`,
        boxShadow: complete ? "0 4px 10px rgb(52 199 123 / 0.35)" : "0 4px 10px rgb(52 199 123 / 0)",
        transition: "box-shadow 0.3s ease",
      }}
    >
      <AnimatePresence>
        {digit !== null && (
          <motion.div
            key="face"
            initial={{ rotateX: 90, opacity: 0 }}
            animate={{ rotateX: 0, opacity: 1 }}
            exit={{ rotateX: 90, opacity: 0 }}
            transition={anim.easeOut(0.22)}
            style={{ position: "absolute", inset: 0, transformPerspective: 64 }}
          >
            <motion.div
              initial={false}
              animate={{ rotateX: showsBack ? 90 : 0, opacity: showsBack ? 0 : 1 }}
              transition={showsBack ? delayed(anim.easeIn(halfFlip), delay) : delayed(anim.easeOut(halfFlip), delay + halfFlip)}
              style={{
                position: "absolute",
                inset: 0,
                display: "grid",
                placeItems: "center",
                transformPerspective: 64,
                fontFamily: fonts.rounded,
                fontSize: 28,
                fontWeight: 600,
                fontVariantNumeric: "tabular-nums",
                color: Palette.label,
              }}
            >
              {digit}
            </motion.div>
            <motion.div
              initial={false}
              animate={{ rotateX: showsBack ? 0 : -90, opacity: showsBack ? 1 : 0 }}
              transition={showsBack ? delayed(anim.easeOut(halfFlip), delay + halfFlip) : delayed(anim.easeIn(halfFlip), delay)}
              style={{
                position: "absolute",
                inset: 4,
                borderRadius: 12,
                background: "rgb(110 123 255 / 0.1)",
                display: "grid",
                placeItems: "center",
                transformPerspective: 64,
              }}
            >
              <div style={{ width: 14, height: 14, borderRadius: "50%", background: Palette.indigo }} />
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>
      <div
        style={{
          position: "absolute",
          inset: 0,
          borderRadius: 14,
          pointerEvents: "none",
          boxShadow: `inset 0 0 0 ${isCurrent || complete ? 2 : 1}px ${border}`,
          transition: "box-shadow 0.25s ease",
        }}
      />
    </div>
  );
}
