/** inputs.token-field · 标签输入框 (Inputs+TokenField.swift) */
import { AnimatePresence, LayoutGroup, motion } from "motion/react";
import { Send, X } from "lucide-react";
import { useEffect, useRef, useState } from "react";
import { DemoHint, NumericText, Palette, anim, black, demoCard, spring, useAutoplay, useHaptics, type DemoProps } from "../../kit";
import { PRIMARY_STRONG, TextInputStyles } from "./_b-common";

interface FieldToken {
  id: number;
  name: string;
}

const NAMES = ["Leo", "Ava", "Noah", "Zoe", "Kai"];

export default function TokenField({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [tokens, setTokens] = useState<FieldToken[]>([{ id: 0, name: "Mia" }]);
  const [draft, setDraft] = useState("");
  const nextID = useRef(1);
  const scriptIndex = useRef(0);
  const introTimers = useRef<number[]>([]);
  const input = useRef<HTMLInputElement>(null);
  const state = useRef({ tokens, draft });
  state.current = { tokens, draft };

  const springT = spring(ctx.n("response"), ctx.n("damping"));
  const avatars = ctx.b("avatars");

  const commit = (userInitiated: boolean, raw = state.current.draft) => {
    const name = raw.replace(/,/g, "").trim();
    setDraft("");
    state.current.draft = "";
    if (!name) return;
    if (userInitiated && !ctx.isPreview) haptics.tap();
    const token = { id: nextID.current++, name };
    state.current.tokens = [...state.current.tokens, token];
    setTokens(state.current.tokens);
  };

  const remove = (token: FieldToken, silent: boolean) => {
    if (!silent && !ctx.isPreview) haptics.tap();
    state.current.tokens = state.current.tokens.filter((t) => t.id !== token.id);
    setTokens(state.current.tokens);
  };

  const stopIntro = () => {
    if (!introTimers.current.length) return;
    introTimers.current.forEach((id) => window.clearTimeout(id));
    introTimers.current = [];
    setDraft("");
  };
  useEffect(() => () => introTimers.current.forEach((id) => window.clearTimeout(id)), []);

  const playIntro = () => {
    if (document.activeElement === input.current) return;
    introTimers.current.forEach((id) => window.clearTimeout(id));
    introTimers.current = [];
    const name = "Leo";
    let t = 0;
    for (const c of name) {
      t += 0.24;
      introTimers.current.push(
        window.setTimeout(() => {
          state.current.draft += c;
          setDraft(state.current.draft);
        }, t * 1000),
      );
    }
    introTimers.current.push(
      window.setTimeout(() => {
        introTimers.current = [];
        commit(false);
      }, (t + 0.4) * 1000),
    );
  };

  const previewTick = () => {
    const name = NAMES[scriptIndex.current % NAMES.length];
    const { tokens: list, draft: d } = state.current;
    if (list.length >= 4) {
      remove(list[0], true);
      return;
    }
    if (d.length < name.length) {
      state.current.draft = d + name[d.length];
      setDraft(state.current.draft);
    } else {
      commit(false);
      scriptIndex.current += 1;
    }
  };

  useAutoplay(ctx.isPreview, () => (ctx.isPreview ? previewTick() : playIntro()), { every: 0.3, delay: 0.4 });

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center" }}>
      <TextInputStyles />
      <div style={{ flex: 1 }} />
      <div style={{ ...demoCard(24), width: 318, padding: 18, display: "flex", flexDirection: "column", gap: 14 }}>
        <div style={{ fontSize: 17, lineHeight: "22px", fontWeight: 600, color: Palette.label }}>{ctx.t("Share with", "共享给")}</div>
        <LayoutGroup>
          <div
            style={{
              position: "relative",
              width: 282,
              minHeight: 96,
              padding: 10,
              borderRadius: 16,
              background: Palette.labelAlpha(0.05),
              display: "flex",
              flexWrap: "wrap",
              alignContent: "flex-start",
              alignItems: "flex-start",
              gap: 6,
            }}
          >
            <AnimatePresence mode="popLayout" initial={false}>
              {tokens.map((token) => (
                <motion.div
                  key={token.id}
                  layout
                  initial={{ scale: 0.4, opacity: 0, originX: 0 }}
                  animate={{ scale: 1, opacity: 1, originX: 0 }}
                  exit={{ scale: 0.4, opacity: 0, originX: 0.5, transition: { ...anim.easeIn(0.18), originX: { duration: 0 } } }}
                  transition={springT}
                >
                  <Chip
                    token={token}
                    avatars={avatars}
                    onRemove={() => {
                      stopIntro();
                      remove(token, false);
                    }}
                  />
                </motion.div>
              ))}
              <motion.div key="input" layout transition={springT} style={{ width: 104, height: 30, display: "flex", alignItems: "center" }}>
                <input
                  ref={input}
                  className="ml-b-input"
                  value={draft}
                  placeholder={ctx.t("Add people", "添加成员")}
                  autoCapitalize="words"
                  autoCorrect="off"
                  autoComplete="off"
                  spellCheck={false}
                  enterKeyHint="done"
                  tabIndex={ctx.isPreview ? -1 : 0}
                  onFocus={stopIntro}
                  onPointerDown={stopIntro}
                  onChange={(e) => {
                    const v = e.target.value;
                    if (v.includes(",")) commit(introTimers.current.length === 0, v);
                    else {
                      state.current.draft = v;
                      setDraft(v);
                    }
                  }}
                  onKeyDown={(e) => {
                    if (e.key === "Enter") {
                      e.preventDefault();
                      commit(true);
                    }
                  }}
                  style={{ width: 104, height: 30, fontSize: 15, lineHeight: "20px", color: Palette.label }}
                />
              </motion.div>
            </AnimatePresence>
          </div>
        </LayoutGroup>
        <div
          style={{
            height: 44,
            borderRadius: 22,
            background: PRIMARY_STRONG,
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            gap: 6,
            fontSize: 15,
            fontWeight: 600,
            color: "#fff",
          }}
        >
          <Send size={16} fill="currentColor" strokeWidth={1.5} />
          <span style={{ display: "inline-flex", whiteSpace: "pre" }}>
            {ctx.lang === "zh" ? "发送给 " : "Send to "}
            <NumericText value={tokens.length} />
            {ctx.lang === "zh" ? " 人" : ""}
          </span>
        </div>
      </div>
      <div style={{ flex: 1 }} />
      <DemoHint ctx={ctx} en="Type a name, then press return" zh="输入名字后按回车" style={{ paddingBottom: 18 }} />
    </div>
  );
}

function Chip({ token, avatars, onRemove }: { token: FieldToken; avatars: boolean; onRemove: () => void }) {
  const hue = Palette.spectrum[token.name.length % Palette.spectrum.length];
  return (
    <div
      style={{
        height: 30,
        display: "flex",
        alignItems: "center",
        gap: 6,
        paddingLeft: avatars ? 4 : 10,
        paddingRight: 5,
        borderRadius: 15,
        background: Palette.elevated,
        boxShadow: `inset 0 0 0 1px ${Palette.stroke}, 0 1px 3px ${black(0.06)}`,
        whiteSpace: "nowrap",
      }}
    >
      {avatars && (
        <span
          style={{
            width: 22,
            height: 22,
            borderRadius: "50%",
            display: "grid",
            placeItems: "center",
            fontSize: 11,
            fontWeight: 700,
            color: "#fff",
            background: `linear-gradient(${hue}, color-mix(in srgb, ${hue} 70%, transparent))`,
          }}
        >
          {token.name.slice(0, 1)}
        </span>
      )}
      <span style={{ fontSize: 15, lineHeight: "20px", fontWeight: 500, color: Palette.label }}>{token.name}</span>
      <button
        type="button"
        onClick={onRemove}
        style={{ width: 18, height: 18, borderRadius: "50%", background: Palette.labelAlpha(0.08), display: "grid", placeItems: "center", color: Palette.secondaryLabel }}
      >
        <X size={10} strokeWidth={3.4} />
      </button>
    </div>
  );
}
