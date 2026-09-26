/** inputs.slot-reel-code · 老虎机验证码 (Inputs+SlotReelCode.swift) */
import { AnimatePresence, motion } from "motion/react";
import { MessageCircle, RotateCcw } from "lucide-react";
import { useEffect, useRef, useState } from "react";
import { DemoHint, Palette, black, delayed, fonts, spring, useAutoplay, useHaptics, type DemoProps } from "../../kit";
import { useLive, SYMBOL_REPLACE } from "./_b-common";

const DIGITS = [4, 8, 2, 9, 1, 3];
const BOX_W = 42;
const BOX_H = 54;

export default function SlotReelCode({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const cycles = Math.max(ctx.i("cycles"), 1);
  const [rows, setRows] = useState<number[]>(Array(6).fill(0));
  const [instant, setInstant] = useState(true);
  const [landed, setLanded] = useState<boolean[]>(Array(6).fill(false));
  const [verified, setVerified, verifiedRef] = useLive(false);
  const [spinning, setSpinning, spinningRef] = useLive(false);
  const runID = useRef(0);
  const timers = useRef<number[]>([]);
  useEffect(() => () => timers.current.forEach((t) => window.clearTimeout(t)), []);

  const reset = () => {
    runID.current += 1;
    setInstant(true);
    setRows(Array(6).fill(0));
    setLanded(Array(6).fill(false));
    setVerified(false);
    setSpinning(false);
  };

  const spin = (muted: boolean) => {
    runID.current += 1;
    const id = runID.current;
    setSpinning(true);
    const stagger = ctx.n("stagger");
    setInstant(false);
    setRows(DIGITS.map((d) => cycles * 10 + d));
    let elapsed = 0;
    for (let index = 0; index < 6; index++) {
      const delay = index * stagger;
      const settle = delay + (0.6 + delay * 0.4) * 0.8;
      elapsed = Math.max(settle, elapsed);
      timers.current.push(
        window.setTimeout(() => {
          if (id !== runID.current) return;
          setLanded((l) => l.map((v, k) => (k === index ? true : v)));
          if (!muted) haptics.selection();
        }, elapsed * 1000),
      );
    }
    timers.current.push(
      window.setTimeout(() => {
        if (id !== runID.current) return;
        setSpinning(false);
        setVerified(true);
        if (!muted) haptics.success();
      }, (elapsed + 0.3) * 1000),
    );
  };

  const spinOrReset = (muted: boolean) => (spinningRef.current || verifiedRef.current ? reset() : spin(muted));

  const first = useRef(true);
  useEffect(() => {
    if (first.current) {
      first.current = false;
      return;
    }
    reset();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [cycles]);

  useAutoplay(ctx.isPreview, () => spinOrReset(true), { every: 3.2, delay: 0.4 });

  const active = spinning || verified;
  const rowCount = (cycles + 1) * 10;

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", gap: 28 }}>
      <div style={{ flex: 1 }} />
      <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 6 }}>
        <span style={{ fontSize: 17, lineHeight: "22px", fontWeight: 600, color: Palette.label }}>{ctx.t("Enter the code", "输入验证码")}</span>
        <span style={{ fontSize: 12, lineHeight: "16px", color: Palette.secondaryLabel }}>{ctx.t("Sent to +1 ••• ••• 0142", "已发送至 +86 ••• •••• 0142")}</span>
      </div>
      <div style={{ display: "flex", gap: 7 }}>
        {DIGITS.map((_, index) => {
          const isLanded = landed[index];
          const border = verified ? Palette.green : isLanded ? Palette.indigo : Palette.labelAlpha(0.15);
          const delay = index * ctx.n("stagger");
          const mask = isLanded ? "none" : "linear-gradient(transparent, #000 25%, #000 75%, transparent)";
          return (
            <motion.div
              key={index}
              initial={false}
              animate={{ scale: isLanded ? 1 : 0.97 }}
              transition={spring(0.25, 0.5)}
              style={{ position: "relative", width: BOX_W, height: BOX_H, borderRadius: 12, background: Palette.elevated }}
            >
              <div style={{ position: "absolute", inset: 0, overflow: "hidden", WebkitMaskImage: mask, maskImage: mask }}>
                <motion.div
                  initial={false}
                  animate={{ y: -rows[index] * BOX_H }}
                  transition={instant ? { duration: 0 } : delayed(spring(0.6 + delay * 0.4, ctx.n("damping")), delay)}
                >
                  {Array.from({ length: rowCount }, (_, row) => (
                    <div
                      key={row}
                      style={{
                        width: BOX_W,
                        height: BOX_H,
                        display: "grid",
                        placeItems: "center",
                        fontFamily: fonts.rounded,
                        fontSize: 26,
                        fontWeight: 600,
                        fontVariantNumeric: "tabular-nums",
                        color: Palette.label,
                      }}
                    >
                      {row % 10}
                    </div>
                  ))}
                </motion.div>
              </div>
              <div
                style={{
                  position: "absolute",
                  inset: 0,
                  borderRadius: 12,
                  boxShadow: `inset 0 0 0 ${isLanded ? 2 : 1}px ${border}`,
                  transition: verified ? `box-shadow 0.25s cubic-bezier(0, 0, 0.58, 1) ${index * 0.05}s` : "box-shadow 0.2s",
                }}
              />
            </motion.div>
          );
        })}
      </div>
      <motion.button
        type="button"
        layout
        transition={spring(0.35, 0.8)}
        onClick={() => spinOrReset(false)}
        style={{
          height: 40,
          padding: "0 16px",
          borderRadius: 20,
          display: "flex",
          alignItems: "center",
          gap: 8,
          background: Palette.elevated,
          boxShadow: `inset 0 0 0 1px ${Palette.stroke}, 0 4px 8px ${black(0.08)}`,
          fontSize: 15,
          fontWeight: 600,
          color: Palette.label,
          whiteSpace: "nowrap",
        }}
      >
        <motion.span layout="position" style={{ position: "relative", width: 17, height: 17, color: Palette.green }}>
          <AnimatePresence initial={false}>
            <motion.span
              key={active ? "reset" : "msg"}
              {...SYMBOL_REPLACE}
              style={{ position: "absolute", inset: 0, display: "grid", placeItems: "center" }}
            >
              {active ? <RotateCcw size={16} strokeWidth={2.6} /> : <MessageCircle size={17} fill="currentColor" strokeWidth={0} />}
            </motion.span>
          </AnimatePresence>
        </motion.span>
        <AnimatePresence mode="popLayout" initial={false}>
          <motion.span
            key={active ? "reset" : "from"}
            layout="position"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            transition={spring(0.35, 0.8)}
          >
            {active ? ctx.t("Reset", "重置") : ctx.t("From Messages · 482 913", "来自信息 · 482 913")}
          </motion.span>
        </AnimatePresence>
      </motion.button>
      <div style={{ flex: 1 }} />
      <DemoHint ctx={ctx} en="Tap the AutoFill suggestion" zh="点击自动填充建议" style={{ paddingBottom: 14 }} />
    </div>
  );
}
