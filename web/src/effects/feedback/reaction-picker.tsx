/** feedback.reaction-picker · 表情回应 (Feedback+Reactions.swift) */
import { AnimatePresence, LayoutGroup, motion } from "motion/react";
import { useEffect, useRef, useState } from "react";
import { DemoHint, Palette, delayed, glass, pressHandlers, spring, useAutoplay, useHaptics, type DemoProps } from "../../kit";

const EMOJIS = ["❤️", "👍", "😂", "😮", "😢", "🔥"];

export default function ReactionPicker({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [open, setOpenState] = useState(false);
  const [chosen, setChosen] = useState<number | null>(null);
  const openRef = useRef(false);
  const previewStep = useRef(0);
  const sp = spring(ctx.n("response"), 0.72);
  const zh = ctx.lang === "zh";
  const focus = open && ctx.b("focus");

  const setOpen = (value: boolean) => {
    if (value) haptics.tap("medium");
    openRef.current = value;
    setOpenState(value);
  };
  const select = (index: number) => {
    haptics.success();
    openRef.current = false;
    setChosen(index);
    setOpenState(false);
  };

  useAutoplay(ctx.isPreview, () => {
    const targets = [0, 2, 5, 1];
    const s = previewStep.current;
    if (s % 4 === 0) setOpen(true);
    else if (s % 4 === 2) select(targets[Math.floor(s / 4) % targets.length]);
    previewStep.current += 1;
  }, { every: 0.8, delay: 0.5 });

  const outgoing = (text: string) => (
    <motion.div initial={false} animate={{ filter: `blur(${focus ? 3 : 0}px)`, opacity: focus ? 0.45 : 1 }} transition={sp} style={{ display: "flex", justifyContent: "flex-end" }}>
      <div style={{ fontSize: 15, lineHeight: "20px", color: "#fff", padding: "10px 14px", borderRadius: 20, background: Palette.primary }}>{text}</div>
    </motion.div>
  );

  return (
    <div
      onClick={() => openRef.current && setOpen(false)}
      style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 18 }}
    >
      <LayoutGroup>
        <div style={{ width: 300, display: "flex", flexDirection: "column", gap: 12 }}>
          {outgoing(zh ? "新的引导流程刚上线 🚀" : "Just shipped the new onboarding 🚀")}
          <div style={{ paddingTop: 8, position: "relative", zIndex: 1 }}>
            <div style={{ position: "relative", display: "inline-block", maxWidth: 230 }}>
              <motion.div
                onClick={(e) => {
                  e.stopPropagation();
                  setOpen(!openRef.current);
                }}
                initial={false}
                animate={{ scale: open ? 1.03 : 1, boxShadow: open ? "0 8px 16px rgb(0 0 0 / 0.18), inset 0 0 0 1px var(--ml-stroke)" : "0 0px 0px rgb(0 0 0 / 0), inset 0 0 0 1px var(--ml-stroke)" }}
                transition={sp}
                style={{ transformOrigin: "0% 50%", fontSize: 15, lineHeight: "20px", padding: "10px 14px", borderRadius: 20, background: Palette.surface, cursor: "pointer" }}
              >
                {zh ? "太惊艳了，转场丝滑得不像话！" : "It looks incredible — those transitions are so smooth!"}
              </motion.div>
              <AnimatePresence>
                {chosen !== null && !open && (
                  <motion.div
                    key="badge"
                    initial={{ opacity: 0 }}
                    animate={{ opacity: 1 }}
                    exit={{ opacity: 0 }}
                    transition={sp}
                    style={{ position: "absolute", right: -12, top: -14, width: 32, height: 32, borderRadius: "50%", background: Palette.elevated, boxShadow: "inset 0 0 0 1px var(--ml-stroke), 0 3px 6px rgb(0 0 0 / 0.15)", display: "grid", placeItems: "center" }}
                  >
                    <motion.span layoutId={`reaction-${chosen}`} layoutCrossfade={false} transition={sp} style={{ fontSize: 17, lineHeight: 1, display: "block" }}>
                      {EMOJIS[chosen]}
                    </motion.span>
                  </motion.div>
                )}
              </AnimatePresence>
              <AnimatePresence>
                {open && (
                  <motion.div
                    key="bar"
                    initial={{ scale: 0.4, opacity: 0 }}
                    animate={{ scale: 1, opacity: 1 }}
                    exit={{ scale: 0.4, opacity: 0 }}
                    transition={sp}
                    onClick={(e) => e.stopPropagation()}
                    style={{ position: "absolute", left: -6, top: -60, transformOrigin: "0% 100%" }}
                  >
                    <Bar returning={chosen} stagger={ctx.n("stagger")} onSelect={select} transition={sp} />
                  </motion.div>
                )}
              </AnimatePresence>
            </div>
          </div>
          {outgoing(zh ? "谢谢！调了好久的弹簧 😄" : "Thanks! Tuned those springs forever 😄")}
        </div>
      </LayoutGroup>
      <DemoHint ctx={ctx} en="Tap the incoming message" zh="点击对方发来的消息" />
    </div>
  );
}

function Bar({ returning, stagger, onSelect, transition }: { returning: number | null; stagger: number; onSelect: (i: number) => void; transition: ReturnType<typeof spring> }) {
  const [appeared, setAppeared] = useState(false);
  useEffect(() => {
    const id = requestAnimationFrame(() => setAppeared(true));
    return () => cancelAnimationFrame(id);
  }, []);
  return (
    <div style={{ display: "flex", gap: 2, padding: "4px 6px", borderRadius: 999, ...glass("regular"), boxShadow: "inset 0 0 0 1px var(--ml-stroke), 0 8px 18px rgb(0 0 0 / 0.18)", whiteSpace: "nowrap" }}>
      {EMOJIS.map((emoji, index) => {
        const visible = appeared || index === returning;
        return (
          <motion.div
            key={index}
            initial={false}
            animate={{ scale: visible ? 1 : 0.2, y: visible ? 0 : 8, opacity: visible ? 1 : 0 }}
            transition={delayed(spring(0.36, 0.62), index === returning ? 0 : 0.05 + index * stagger)}
          >
            <EmojiButton emoji={emoji} index={index} returning={index === returning} onSelect={onSelect} transition={transition} />
          </motion.div>
        );
      })}
    </div>
  );
}

function EmojiButton({ emoji, index, onSelect, transition }: { emoji: string; index: number; returning: boolean; onSelect: (i: number) => void; transition: ReturnType<typeof spring> }) {
  const [pressed, setPressed] = useState(false);
  return (
    <motion.button
      type="button"
      onClick={() => onSelect(index)}
      {...pressHandlers(setPressed)}
      animate={{ scale: pressed ? 1.35 : 1, y: pressed ? -6 : 0 }}
      transition={spring(0.25, 0.6)}
      style={{ width: 40, height: 40, display: "grid", placeItems: "center", transformOrigin: "50% 100%" }}
    >
      <motion.span layoutId={`reaction-${index}`} layoutCrossfade={false} transition={transition} style={{ fontSize: 26, lineHeight: 1, display: "block" }}>
        {emoji}
      </motion.span>
    </motion.button>
  );
}
