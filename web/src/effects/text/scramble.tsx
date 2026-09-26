/** text.scramble · 乱码解码 (Text+Scramble.swift) */
import { AnimatePresence, motion } from "motion/react";
import { useEffect, useRef, useState } from "react";
import { DemoHint, Palette, alpha, anim, demoCard, fonts, useAutoplay, useClock, useHaptics, type DemoProps } from "../../kit";
import { SHEEN, chars } from "./_text-kit";

const TARGETS = {
  zh: ["访问已授权", "信号已解密", "动效词典"],
  en: ["ACCESS GRANTED", "SIGNAL DECODED", "MOTION LEXICON"],
};

function poolFor(choice: number, zh: boolean): string[] {
  if (choice === 1) return chars("01");
  if (choice === 2) return chars("▖▗▘▙▚▛▜▝▞▟█▓▒░");
  return zh
    ? chars("的一是不了人我在有他这中大来上国个到说们为子和你地出道也时年得就那要下以生会自着去之过家学对可里后")
    : chars("ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789#%&*@$<>/");
}

/** Swift's wrapping Int arithmetic hash → pool bucket. */
function bucket(frame: number, index: number, count: number): number {
  const f = BigInt(frame);
  const i = BigInt(index);
  const h = BigInt.asIntN(64, BigInt.asIntN(64, f * 73_856_093n) ^ BigInt.asIntN(64, i * 19_349_663n) ^ BigInt.asIntN(64, f * i * 83_492_791n));
  return Number(BigInt.asUintN(64, h) % BigInt(count));
}

export default function Scramble({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [start, setStart] = useState(-Infinity);
  const [index, setIndex] = useState(0);
  const [done, setDone] = useState(true);
  const userTriggered = useRef(false);
  const duration = Math.max(ctx.n("duration"), 0.1);
  useClock(!done, ctx.isPreview ? 30 : undefined);
  const elapsed = performance.now() / 1000 - start;

  const replay = () => {
    setIndex((i) => i + 1);
    setStart(performance.now() / 1000);
    setDone(false);
  };
  useAutoplay(ctx.isPreview, replay, { every: Math.max(ctx.n("duration"), 0.5) + 1.6, delay: 0.1 });

  useEffect(() => {
    if (start === -Infinity) return;
    setDone(false);
    const id = window.setTimeout(() => {
      setDone(true);
      if (userTriggered.current) haptics.success();
    }, duration * 1000);
    return () => window.clearTimeout(id);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [start]);

  const target = chars(TARGETS[ctx.lang][index % 3]);
  const pool = poolFor(ctx.i("pool"), ctx.lang === "zh");
  const rate = ctx.n("rate");
  const tone = done ? Palette.green : Palette.indigo;
  const dot = done ? Palette.green : Palette.amber;
  const p = Math.min(Math.max(elapsed / duration, 0), 1);

  return (
    <div
      onClick={() => {
        userTriggered.current = true;
        replay();
      }}
      style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 18, cursor: "pointer" }}
    >
      <div style={{ ...demoCard(26), width: 300, padding: "22px 0", display: "flex", flexDirection: "column", alignItems: "center", gap: 16 }}>
        <motion.div
          animate={{ backgroundColor: tone, boxShadow: `0 6px 12px ${alpha(tone, 0.35)}` }}
          transition={anim.snappy}
          style={{ width: 52, height: 52, borderRadius: 16, display: "grid", placeItems: "center", color: "#fff", backgroundImage: SHEEN }}
        >
          <AnimatePresence mode="popLayout" initial={false}>
            <motion.span
              key={done ? "open" : "closed"}
              initial={{ scale: 0.4, opacity: 0, filter: "blur(3px)" }}
              animate={{ scale: 1, opacity: 1, filter: "blur(0px)" }}
              exit={{ scale: 0.4, opacity: 0, filter: "blur(3px)" }}
              transition={anim.snappyD(0.3)}
              style={{ display: "grid" }}
            >
              <LockGlyph open={done} />
            </motion.span>
          </AnimatePresence>
        </motion.div>
        <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
          <motion.span
            animate={{ backgroundColor: dot, boxShadow: `0 0 6px ${alpha(dot, 0.8)}` }}
            transition={anim.snappy}
            style={{ width: 8, height: 8, borderRadius: "50%" }}
          />
          <span style={{ position: "relative", fontFamily: fonts.mono, fontSize: 12, lineHeight: "16px", fontWeight: 700, color: Palette.secondaryLabel }}>
            <AnimatePresence mode="popLayout" initial={false}>
              <motion.span key={done ? "d" : "r"} initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} transition={anim.snappy} style={{ display: "inline-block" }}>
                {done ? ctx.t("DECODED", "已解码") : ctx.t("DECRYPTING", "解密中")}
              </motion.span>
            </AnimatePresence>
          </span>
        </div>
        <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 14 }}>
          <div style={{ height: 44, display: "flex", alignItems: "center", fontFamily: fonts.mono, fontSize: 28, fontWeight: 700 }}>
            {target.map((final, i) => {
              const lockAt = duration * (0.25 + (0.75 * (i + 1)) / Math.max(target.length, 1));
              const locked = elapsed >= lockAt || final === " ";
              const shown = locked ? final : pool.length ? pool[bucket(Math.floor(elapsed * rate), i, pool.length)] : "?";
              return (
                <span key={i} style={{ whiteSpace: "pre", color: locked ? Palette.label : Palette.mint, opacity: locked ? 1 : 0.85 }}>
                  {shown}
                </span>
              );
            })}
          </div>
          <div style={{ position: "relative", width: 180, height: 3, borderRadius: 2, background: Palette.labelAlpha(0.08) }}>
            <div
              style={{
                position: "absolute",
                left: 0,
                top: 0,
                height: 3,
                width: 180 * p,
                borderRadius: 2,
                background: p >= 1 ? Palette.green : Palette.aurora,
              }}
            />
          </div>
        </div>
      </div>
      <DemoHint ctx={ctx} en="Tap to decode again" zh="点击再次解码" />
    </div>
  );
}

/** SF Symbol `lock.fill` / `lock.open.fill` at 22 pt semibold. */
function LockGlyph({ open }: { open: boolean }) {
  return (
    <svg width={22} height={24} viewBox="0 0 22 24">
      <path
        d={open ? "M14 11V6.5a3.5 3.5 0 0 1 7 0V8" : "M6 11V7a5 5 0 0 1 10 0v4"}
        fill="none"
        stroke="currentColor"
        strokeWidth={2.6}
        strokeLinecap="round"
      />
      <rect x={open ? 1 : 3} y={10} width={16} height={13} rx={3} fill="currentColor" />
    </svg>
  );
}
