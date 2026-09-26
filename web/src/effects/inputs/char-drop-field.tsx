/** inputs.char-drop-field · 字符掉落输入框 (Inputs+CharDropField.swift) */
import { AnimatePresence, motion } from "motion/react";
import { useEffect, useRef, useState } from "react";
import { DemoHint, NumericText, Palette, anim, demoCard, fonts, spring, useAutoplay, useHaptics, type DemoProps } from "../../kit";

const LIMIT = 16;
const SCRIPT = ["m", "o", "t", "i", "o", "n", "_", "k", "i", "d", "⌫", "⌫", "⌫", "l", "a", "b", "⏸", "⏸", "⌧"];

export default function CharDropField({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [text, setText] = useState("");
  const [focused, setFocused] = useState(false);
  const [intro, setIntro] = useState(false);
  const scriptIndex = useRef(0);
  const introTimers = useRef<number[]>([]);
  const input = useRef<HTMLInputElement>(null);

  const active = focused || ctx.isPreview || intro;

  const apply = (key: string) => {
    setText((t) => {
      if (key === "⌫") return t.slice(0, -1);
      if (key === "⌧") return "";
      if (key === "⏸") return t;
      return t.length < LIMIT ? t + key : t;
    });
  };
  const previewType = () => {
    const key = SCRIPT[scriptIndex.current % SCRIPT.length];
    scriptIndex.current += 1;
    apply(key);
  };
  const stopIntro = () => {
    introTimers.current.forEach((id) => window.clearTimeout(id));
    introTimers.current = [];
    setIntro(false);
  };
  const playIntro = () => {
    if (document.activeElement === input.current) return;
    stopIntro();
    setText("");
    scriptIndex.current = 0;
    setIntro(true);
    const steps = SCRIPT.length - 3;
    for (let k = 1; k <= steps; k++) introTimers.current.push(window.setTimeout(previewType, k * 200));
    introTimers.current.push(window.setTimeout(() => setIntro(false), steps * 200 + 500));
  };
  useEffect(() => () => introTimers.current.forEach((id) => window.clearTimeout(id)), []);

  useAutoplay(ctx.isPreview, () => (ctx.isPreview ? previewType() : playIntro()), { every: 0.22, delay: 0.4 });

  const drop = ctx.n("drop");
  const tilt = ctx.b("tilt") ? -14 : 0;
  const letterSpring = spring(ctx.n("response"), ctx.n("damping"));
  const chars = Array.from(text);

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center" }}>
      <div style={{ flex: 1 }} />
      <div style={{ ...demoCard(24), width: 310, padding: 18, display: "flex", flexDirection: "column", gap: 10 }}>
        <div style={{ display: "flex", alignItems: "center" }}>
          <span style={{ fontSize: 15, lineHeight: "20px", fontWeight: 600, color: Palette.secondaryLabel }}>{ctx.t("Username", "用户名")}</span>
          <span style={{ flex: 1 }} />
          <span style={{ fontSize: 12, lineHeight: "16px", fontWeight: 500, color: Palette.tertiaryLabel, display: "inline-flex" }}>
            <NumericText value={chars.length} />
            <span>/{LIMIT}</span>
          </span>
        </div>
        <div style={{ position: "relative", height: 52, borderRadius: 14, overflow: "hidden", background: Palette.labelAlpha(0.05) }}>
          <div
            style={{
              position: "absolute",
              inset: 0,
              padding: "0 14px",
              display: "flex",
              alignItems: "center",
              fontFamily: fonts.rounded,
              fontSize: 20,
              fontWeight: 600,
              lineHeight: "24px",
              whiteSpace: "pre",
            }}
          >
            <span style={{ color: Palette.tertiaryLabel, paddingRight: 2 }}>@</span>
            <span style={{ display: "flex" }}>
              <AnimatePresence mode="popLayout" initial={false}>
                {chars.map((c, i) => (
                  <motion.span
                    key={i}
                    initial={{ y: -drop, rotate: tilt, scale: 1, opacity: 0 }}
                    animate={{ y: 0, rotate: 0, scale: 1, opacity: 1, transition: letterSpring }}
                    exit={{ y: -14, rotate: 0, scale: 0.6, opacity: 0, transition: anim.easeOut(0.2) }}
                    style={{ display: "inline-block", letterSpacing: 0.2, color: Palette.label, transformOrigin: "50% 100%" }}
                  >
                    {c}
                  </motion.span>
                ))}
              </AnimatePresence>
            </span>
            {active && (
              <motion.span layout="position" transition={letterSpring} style={{ display: "inline-block", marginLeft: 2 }}>
                <motion.span
                  animate={{ opacity: [1, 0] }}
                  transition={{ duration: 0.5, ease: [0.42, 0, 0.58, 1], repeat: Infinity, repeatType: "reverse" }}
                  style={{ display: "block", width: 2, height: 24, borderRadius: 1, background: Palette.indigo }}
                />
              </motion.span>
            )}
            {chars.length === 0 && !active && <span style={{ color: Palette.tertiaryLabel }}>{ctx.t("your-name", "你的名字")}</span>}
          </div>
          <motion.div
            initial={false}
            animate={{ scaleX: active ? 1 : 0 }}
            transition={anim.smoothD(0.45)}
            style={{
              position: "absolute",
              left: 0,
              right: 0,
              bottom: 0,
              height: 2.5,
              transformOrigin: "0% 50%",
              background: `linear-gradient(90deg, ${Palette.indigo}, ${Palette.violet}, ${Palette.pink})`,
            }}
          />
          {!ctx.isPreview && (
            <input
              ref={input}
              value={text}
              maxLength={LIMIT}
              autoCapitalize="none"
              autoCorrect="off"
              autoComplete="off"
              spellCheck={false}
              aria-label={ctx.t("Username", "用户名")}
              onPointerDown={stopIntro}
              onFocus={() => {
                stopIntro();
                setFocused(true);
              }}
              onBlur={() => setFocused(false)}
              onChange={(e) => {
                const next = e.target.value.slice(0, LIMIT);
                if (Array.from(next).length !== chars.length) haptics.selection();
                setText(next);
              }}
              style={{
                position: "absolute",
                inset: 0,
                width: "100%",
                height: "100%",
                opacity: 0,
                border: 0,
                padding: 0,
                fontSize: 16,
                cursor: "text",
                userSelect: "text",
                WebkitUserSelect: "text",
                touchAction: "manipulation",
              }}
            />
          )}
        </div>
      </div>
      <div style={{ flex: 1 }} />
      <DemoHint ctx={ctx} en="Tap the field and type" zh="点击输入框开始输入" style={{ paddingBottom: 18 }} />
    </div>
  );
}
