/** inputs.password-strength (Inputs+PasswordStrength.swift) */
import { AnimatePresence, motion } from "motion/react";
import { Circle, Lock } from "lucide-react";
import { useRef, useState } from "react";
import { DemoHint, Palette, anim, delayed, demoCard, spring, textStyle, useAutoplay, type DemoProps } from "../../kit";
import { CheckCircleFill, SymbolSwap, fieldInputStyle } from "./_a-common";

const SAMPLES = ["", "moon", "moonlight", "Moonlight7", "Moonlight7!"];

function rulesFor(p: string): [string, string, boolean][] {
  const chars = Array.from(p);
  return [
    ["8+ characters", "至少 8 位", chars.length >= 8],
    ["Uppercase letter", "包含大写字母", chars.some((c) => c !== c.toLowerCase() && c === c.toUpperCase())],
    ["Number", "包含数字", /\p{N}/u.test(p)],
    ["Symbol", "包含符号", chars.some((c) => !/[\p{L}\p{N}\s]/u.test(c))],
  ];
}
const scoreFor = (p: string) => (p.length === 0 ? 0 : Math.max(1, rulesFor(p).filter((r) => r[2]).length));

const COLORS = [Palette.red, Palette.red, Palette.coral, Palette.amber, Palette.green];
const LABELS: [string, string][] = [
  ["Enter a password", "请输入密码"],
  ["Weak", "弱"],
  ["Fair", "一般"],
  ["Good", "良好"],
  ["Strong", "很强"],
];

export default function PasswordStrength({ ctx }: DemoProps) {
  const [password, setPasswordState] = useState("");
  const [scores, setScores] = useState({ score: 0, previous: 0 });
  const step = useRef(0);
  const zh = ctx.lang === "zh";

  const setPassword = (p: string) => {
    setPasswordState(p);
    const next = scoreFor(p);
    setScores((s) => (next === s.score ? s : { score: next, previous: s.score }));
  };

  useAutoplay(
    ctx.isPreview,
    () => {
      step.current += 1;
      setPassword(SAMPLES[step.current % SAMPLES.length]);
    },
    { every: 1.1, delay: 0.4 },
  );

  const { score, previous } = scores;
  const rules = rulesFor(password);
  const color = COLORS[score];
  const stagger = ctx.n("stagger");
  const delayFor = (i: number) =>
    score >= previous ? (i >= previous ? (i - previous) * stagger : 0) : i < previous ? (previous - 1 - i) * stagger : 0;

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center" }}>
      <div style={{ flex: 1 }} />
      <div style={{ ...demoCard(), width: 300, padding: 20, display: "flex", flexDirection: "column", gap: 16 }}>
        <div style={{ display: "flex", alignItems: "center", gap: 10, height: 48, padding: "0 14px", borderRadius: 12, background: Palette.labelAlpha(0.05) }}>
          <Lock size={17} fill="currentColor" strokeWidth={2} style={{ color: Palette.secondaryLabel, flexShrink: 0 }} />
          <input
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            type={ctx.b("mask") ? "password" : "text"}
            placeholder={zh ? "设置密码" : "Create password"}
            autoCapitalize="none"
            autoCorrect="off"
            spellCheck={false}
            className="a-password-field"
            style={{ ...fieldInputStyle, flex: 1, height: 48, ...textStyle.body, fontWeight: 500, color: Palette.label, caretColor: Palette.indigo }}
          />
          <style>{`.a-password-field::placeholder { color: var(--ml-label3); }`}</style>
        </div>
        <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
          <div style={{ display: "flex", gap: 6, height: 6 }}>
            {Array.from({ length: 4 }, (_, i) => {
              const filled = i < score;
              return (
                <div key={i} style={{ position: "relative", flex: 1, borderRadius: 3, background: Palette.labelAlpha(0.08) }}>
                  <motion.div
                    initial={false}
                    animate={{ scaleX: filled ? 1 : 0.001, opacity: filled ? 1 : 0, backgroundColor: color }}
                    transition={{ default: delayed(spring(ctx.n("response"), 0.75), delayFor(i)), backgroundColor: anim.easeOut(0.2) }}
                    style={{ position: "absolute", inset: 0, borderRadius: 3, transformOrigin: "0% 50%" }}
                  />
                </div>
              );
            })}
          </div>
          <div style={{ position: "relative", height: 16 }}>
            <AnimatePresence initial={false}>
              <motion.span
                key={score}
                initial={{ opacity: 0, y: 6 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: -6 }}
                transition={anim.easeOut(0.25)}
                style={{ position: "absolute", left: 0, top: 0, ...textStyle.caption, fontWeight: 600, whiteSpace: "nowrap", color: score === 0 ? Palette.secondaryLabel : color }}
              >
                {zh ? LABELS[score][1] : LABELS[score][0]}
              </motion.span>
            </AnimatePresence>
          </div>
        </div>
        <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
          {rules.map(([en, zhText, ok], i) => (
            <div key={i} style={{ display: "flex", alignItems: "center", gap: 8, ...textStyle.footnote, fontWeight: 500 }}>
              <SymbolSwap k={ok ? "ok" : "no"} style={{ width: 16, height: 16, color: ok ? Palette.green : Palette.secondaryLabel }}>
                {ok ? <CheckCircleFill size={16} /> : <Circle size={16} strokeWidth={1.8} />}
              </SymbolSwap>
              <span style={{ color: ok ? Palette.label : Palette.secondaryLabel, transition: "color 0.3s" }}>{zh ? zhText : en}</span>
            </div>
          ))}
        </div>
      </div>
      <div style={{ flex: 1 }} />
      <DemoHint ctx={ctx} en="Type a password — try adding A, 7 and !" zh="输入密码——试着加上大写、数字和符号" style={{ paddingBottom: 18 }} />
    </div>
  );
}
