/** feedback.inline-validation · 输入框即时校验 (Feedback+InlineValidation.swift) */
import { AnimatePresence, motion } from "motion/react";
import { Check, CircleAlert, CircleCheck, Mail, TriangleAlert } from "lucide-react";
import { useRef, useState } from "react";
import { DemoHint, Palette, alpha, anim, demoCard, spring, useAutoplay, useElapsed, useHaptics, type DemoProps } from "../../kit";
import { PrimaryCapsule, SPRINGS, track } from "./shared";

type Status = "idle" | "invalid" | "valid";

function isValid(text: string) {
  const trimmed = text.trim();
  if (trimmed.includes(" ")) return false;
  const parts = trimmed.split("@");
  if (parts.length !== 2 || !parts[0]) return false;
  const domain = parts[1];
  const dot = domain.lastIndexOf(".");
  if (dot < 0) return false;
  return dot !== 0 && domain.length - dot > 2;
}

export default function InlineValidation({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [email, setEmail] = useState("alex@studio");
  const [status, setStatus] = useState<Status>("idle");
  const [failures, setFailures] = useState(0);
  const [t, setT] = useState(spring(0.4, 0.8));
  const submitted = useRef(false);
  const previewStep = useRef(0);
  const emailRef = useRef(email);
  emailRef.current = email;
  const sp = () => spring(ctx.n("response"), 0.8);

  const change = (value: string) => {
    setEmail(value);
    if (ctx.b("live") && submitted.current) {
      const next: Status = isValid(value) ? "valid" : "invalid";
      if (next !== status) {
        setT(sp());
        setStatus(next);
      }
    } else if (status !== "idle") {
      setT(anim.easeOut(0.15));
      setStatus("idle");
    }
  };

  const submit = (value = emailRef.current) => {
    submitted.current = true;
    if (isValid(value)) {
      haptics.success();
      setT(spring(ctx.n("response"), 0.62));
      setStatus("valid");
    } else {
      haptics.error();
      setFailures((f) => f + 1);
      setT(sp());
      setStatus("invalid");
    }
  };

  useAutoplay(
    ctx.isPreview,
    () => {
      const value = previewStep.current % 2 === 0 ? "alex@studio" : "alex@studio.com";
      setEmail(value);
      emailRef.current = value;
      submit(value);
      previewStep.current += 1;
    },
    { every: 1.8, delay: 0.6 },
  );

  // Failed-submit pulse: dip, extra border, glow.
  const e = useElapsed(failures, 0.9, true);
  const dip = e < 0 ? 0 : track(e, 0, [{ cubic: 4, d: 0.09 }, { spring: 0, d: 0.32, ...SPRINGS.bouncy }]);
  const border = e < 0 ? 0 : track(e, 0, [{ cubic: 1.5, d: 0.12 }, { cubic: 0, d: 0.28 }]);
  const glow = e < 0 ? 0 : track(e, 0, [{ cubic: 1, d: 0.12 }, { cubic: 0, d: 0.4 }]);
  const a = ctx.n("amplitude");
  const tint = status === "invalid" ? Palette.red : status === "valid" ? Palette.green : Palette.secondaryLabel;
  const valid = status === "valid";

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 16 }}>
      <motion.div layout transition={t} style={{ ...demoCard(26), position: "relative", width: 300, padding: 20, display: "flex", flexDirection: "column", gap: 10 }}>
        <motion.div layout="position" transition={t} style={{ fontSize: 15, lineHeight: "20px", fontWeight: 600, color: Palette.secondaryLabel }}>
          {ctx.t("Email", "邮箱")}
        </motion.div>
        <motion.div
          layout="position"
          transition={t}
          style={{
            position: "relative",
            height: 52,
            borderRadius: 14,
            background: Palette.surface,
            display: "flex",
            alignItems: "center",
            gap: 10,
            padding: "0 14px",
            transform: `translateY(${dip}px)`,
            boxShadow: glow > 0.001 ? `0 0 ${a * glow}px ${alpha(Palette.red, 0.5 * glow)}` : undefined,
          }}
        >
          <motion.div
            initial={false}
            animate={{ boxShadow: `inset 0 0 0 ${status === "idle" ? 1 : 1.5}px ${status === "idle" ? "rgb(var(--ml-label-rgb) / 0.08)" : status === "invalid" ? Palette.red : Palette.green}` }}
            transition={t}
            style={{ position: "absolute", inset: 0, borderRadius: 14, pointerEvents: "none" }}
          />
          {glow > 0.001 && <div style={{ position: "absolute", inset: 0, borderRadius: 14, boxShadow: `inset 0 0 0 ${1.5 + border}px ${Palette.red}`, pointerEvents: "none" }} />}
          <motion.span initial={false} animate={{ color: tint }} transition={t} style={{ display: "grid" }}>
            <Mail size={18} strokeWidth={1.6} fill="currentColor" stroke="var(--ml-surface)" />
          </motion.span>
          <input
            value={email}
            onChange={(ev) => change(ev.target.value)}
            onKeyDown={(ev) => ev.key === "Enter" && submit()}
            disabled={ctx.isPreview}
            placeholder="name@example.com"
            autoCapitalize="off"
            autoCorrect="off"
            spellCheck={false}
            inputMode="email"
            style={{ flex: 1, minWidth: 0, fontSize: 17, background: "transparent", border: 0, outline: "none", padding: 0, userSelect: "text", WebkitUserSelect: "text" }}
          />
          <span style={{ position: "relative", width: 22, height: 22, flexShrink: 0 }}>
            <AnimatePresence initial={false}>
              {status !== "idle" && (
                <motion.span
                  key={status}
                  initial={{ scale: 0.4, opacity: 0 }}
                  animate={{ scale: 1, opacity: 1 }}
                  exit={{ scale: 0.4, opacity: 0 }}
                  transition={t}
                  style={{ position: "absolute", inset: 0, display: "grid", placeItems: "center", color: valid ? Palette.green : Palette.red }}
                >
                  {valid ? <CircleCheck size={22} fill="currentColor" stroke="var(--ml-surface)" strokeWidth={2.2} /> : <CircleAlert size={22} fill="currentColor" stroke="var(--ml-surface)" strokeWidth={2.2} />}
                </motion.span>
              )}
            </AnimatePresence>
          </span>
        </motion.div>
        <AnimatePresence initial={false} mode="popLayout">
          {status !== "idle" && (
            <motion.div
              key="message"
              layout="position"
              initial={{ opacity: 0, y: -8 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -8 }}
              transition={t}
              style={{ display: "grid" }}
            >
              <AnimatePresence initial={false}>
                <motion.div
                  key={valid ? "ok" : "bad"}
                  initial={{ opacity: 0 }}
                  animate={{ opacity: 1 }}
                  exit={{ opacity: 0 }}
                  transition={t}
                  style={{ gridArea: "1/1", display: "flex", alignItems: "center", gap: 6, fontSize: 13, lineHeight: "18px", fontWeight: 500, color: valid ? Palette.green : Palette.red, whiteSpace: "nowrap" }}
                >
                  {valid ? <Check size={13} strokeWidth={2.6} /> : <TriangleAlert size={13} fill="currentColor" stroke="var(--ml-elevated)" strokeWidth={2} />}
                  {valid ? ctx.t("Looks good", "看起来不错") : ctx.t("Enter a valid email address", "请输入有效的邮箱地址")}
                </motion.div>
              </AnimatePresence>
            </motion.div>
          )}
        </AnimatePresence>
        <motion.div layout="position" transition={t} style={{ paddingTop: 6 }}>
          <PrimaryCapsule onClick={() => submit()} height={48} style={{ width: "100%", justifyContent: "center", boxShadow: "none" }}>
            {ctx.t("Continue", "继续")}
          </PrimaryCapsule>
        </motion.div>
      </motion.div>
      <DemoHint ctx={ctx} en="Tap Continue, then fix the address" zh="点击“继续”，再改正邮箱地址" />
    </div>
  );
}
