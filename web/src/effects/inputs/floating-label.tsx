/** inputs.floating-label (Inputs+FloatingLabel.swift) */
import { AnimatePresence, motion, type Transition } from "motion/react";
import { useRef, useState } from "react";
import { DemoHint, Palette, demoCard, spring, useAutoplay, useTimeouts, type DemoProps } from "../../kit";
import { CheckCircleFill, fieldInputStyle } from "./_a-common";

type FieldID = "name" | "email";

export default function FloatingLabel({ ctx }: DemoProps) {
  const { after } = useTimeouts();
  const [focus, setFocus] = useState<FieldID | null>(null);
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [previewFocus, setPreviewFocus] = useState<FieldID | null>(null);
  const previewStep = useRef(0);
  const introRun = useRef(0);
  const introActive = useRef(false);
  const t = spring(ctx.n("response"), ctx.n("damping"));
  const root = useRef<HTMLDivElement>(null);

  const previewTick = () => {
    const step = previewStep.current % 4;
    previewStep.current += 1;
    if (step === 0) setPreviewFocus("name");
    else if (step === 1) {
      setName("Ada Lovelace");
      setPreviewFocus("email");
    } else if (step === 2) {
      setEmail("ada@motion.dev");
      setPreviewFocus(null);
    } else {
      setName("");
      setEmail("");
    }
  };

  const introFill = () => {
    introRun.current += 1;
    const run = introRun.current;
    introActive.current = true;
    [0, 1.2, 2.4].forEach((d) => after(d, () => run === introRun.current && previewTick()));
    after(3.6, () => {
      if (run === introRun.current) introActive.current = false;
    });
  };

  useAutoplay(ctx.isPreview, () => (ctx.isPreview ? previewTick() : introFill()), { every: 1.4, delay: 0.4 });

  const onFocus = (id: FieldID) => {
    setFocus(id);
    if (introActive.current) {
      introRun.current += 1;
      introActive.current = false;
      setPreviewFocus(null);
    }
  };

  const common = { t, lift: ctx.n("lift"), rise: ctx.n("rise"), onFocus, onBlur: () => setFocus(null) };

  return (
    <div
      ref={root}
      onPointerDown={(e) => {
        if (!(e.target instanceof HTMLInputElement)) {
          const active = document.activeElement;
          if (active instanceof HTMLInputElement && root.current?.contains(active)) active.blur();
        }
      }}
      style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center" }}
    >
      <div style={{ flex: 1 }} />
      <div style={{ ...demoCard(), width: 300, padding: 22, display: "flex", flexDirection: "column", gap: 18 }}>
        <Field {...common} id="name" title={ctx.t("Full name", "姓名")} text={name} setText={setName} focused={focus === "name" || previewFocus === "name"} isValid={false} />
        <Field
          {...common}
          id="email"
          title={ctx.t("Email", "邮箱")}
          text={email}
          setText={setEmail}
          focused={focus === "email" || previewFocus === "email"}
          isValid={email.includes("@") && email.includes(".")}
        />
      </div>
      <div style={{ flex: 1 }} />
      <DemoHint ctx={ctx} en="Tap a field and start typing" zh="点击输入框开始输入" style={{ paddingBottom: 18 }} />
    </div>
  );
}

function Field({
  id,
  title,
  text,
  setText,
  focused,
  isValid,
  lift,
  rise,
  t,
  onFocus,
  onBlur,
}: {
  id: FieldID;
  title: string;
  text: string;
  setText: (s: string) => void;
  focused: boolean;
  isValid: boolean;
  lift: number;
  rise: number;
  t: Transition;
  onFocus: (id: FieldID) => void;
  onBlur: () => void;
}) {
  const floated = focused || text.length > 0;
  return (
    <div style={{ position: "relative", paddingTop: 18, paddingBottom: 10 }}>
      <div style={{ position: "relative", height: 22, display: "flex", alignItems: "center", gap: 8 }}>
        <input
          value={text}
          onChange={(e) => setText(e.target.value)}
          onFocus={() => onFocus(id)}
          onBlur={onBlur}
          type={id === "email" ? "email" : "text"}
          inputMode={id === "email" ? "email" : "text"}
          autoCapitalize={id === "email" ? "none" : "words"}
          autoCorrect="off"
          spellCheck={false}
          style={{ ...fieldInputStyle, flex: 1, height: 22, fontSize: 17, lineHeight: "22px", color: Palette.label, caretColor: Palette.indigo }}
        />
        <AnimatePresence initial={false}>
          {isValid && (
            <motion.span
              initial={{ scale: 0.2, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              exit={{ scale: 0.2, opacity: 0 }}
              transition={spring(0.35, 0.55)}
              style={{ display: "grid", color: Palette.green }}
            >
              <CheckCircleFill size={19} />
            </motion.span>
          )}
        </AnimatePresence>
        <motion.span
          initial={false}
          animate={{ scale: floated ? lift : 1, y: floated ? -rise : 0 }}
          transition={t}
          style={{
            position: "absolute",
            left: 0,
            top: 0,
            lineHeight: "22px",
            fontSize: 17,
            transformOrigin: "0% 50%",
            pointerEvents: "none",
            whiteSpace: "nowrap",
            color: focused ? Palette.indigo : Palette.secondaryLabel,
            transition: "color 0.3s",
          }}
        >
          {title}
        </motion.span>
      </div>
      <div style={{ position: "absolute", left: 0, right: 0, bottom: 0, height: 2, display: "grid", alignItems: "center" }}>
        <div style={{ gridArea: "1 / 1", height: 1, background: Palette.labelAlpha(0.15) }} />
        <motion.div
          initial={false}
          animate={{ scaleX: focused ? 1 : 0.001, opacity: focused ? 1 : 0 }}
          transition={t}
          style={{ gridArea: "1 / 1", height: 2, borderRadius: 1, background: `linear-gradient(90deg, ${Palette.indigo}, ${Palette.violet})` }}
        />
      </div>
    </div>
  );
}
