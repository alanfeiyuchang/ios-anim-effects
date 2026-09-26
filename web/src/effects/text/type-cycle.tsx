/** text.type-cycle · 打字轮换 (Text+TypeCycle.swift) */
import { useEffect, useRef, useState } from "react";
import { DemoHint, Palette, alpha, fonts, useClock, useHaptics, type DemoProps } from "../../kit";
import { Glyphs, chars } from "./_text-kit";

interface Frame {
  word: string[];
  visible: number;
  caretOn: boolean;
  selected: boolean;
  lift: number;
  sinceLast: number;
}
const WORDS = { zh: ["动效", "体验", "惊喜", "细节"], en: ["motion", "delight", "clarity", "details"] };
const now = () => Date.now() / 1000;
/** Each word's slot: typing, hold, a 300 ms exit and a 250 ms pause. */
const slotDurations = (list: string[][], perChar: number, hold: number) => list.map((c) => c.length * perChar + hold + 0.3 + 0.25);

export default function TypeCycle({ ctx }: DemoProps) {
  const haptics = useHaptics();
  useClock(true, ctx.isPreview ? 30 : undefined);
  const [shift, setShift] = useState(0);
  const list = WORDS[ctx.lang].map((w) => chars(w));
  const perChar = Math.max(ctx.n("typeSpeed"), 0.01);
  const hold = ctx.n("hold");
  const selectMode = ctx.i("erase") === 1;

  // A new typing speed or hold keeps the same word at the same point of its slot.
  const last = useRef({ perChar, hold });
  useEffect(() => {
    const old = last.current;
    last.current = { perChar, hold };
    if (old.perChar === perChar && old.hold === hold) return;
    const t0 = now();
    const oldDurations = slotDurations(list, old.perChar, old.hold);
    const newDurations = slotDurations(list, perChar, hold);
    let t = (t0 + shift) % Math.max(oldDurations.reduce((a, b) => a + b, 0), 0.1);
    let before = 0;
    for (let index = 0; index < list.length; index++) {
      if (t < oldDurations[index]) {
        const typing = list[index].length * old.perChar;
        const newTyping = list[index].length * perChar;
        const mapped = t < typing ? (t / old.perChar) * perChar : t < typing + old.hold ? newTyping + Math.min(t - typing, hold) : newTyping + hold + (t - typing - old.hold);
        const newTotal = Math.max(newDurations.reduce((a, b) => a + b, 0), 0.1);
        setShift(before + mapped - (t0 % newTotal));
        return;
      }
      t -= oldDurations[index];
      before += newDurations[index];
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [perChar, hold]);

  const skip = () => {
    if (ctx.isPreview) return;
    haptics.selection();
    const durations = slotDurations(list, perChar, hold);
    let t = (now() + shift) % Math.max(durations.reduce((a, b) => a + b, 0), 0.1);
    for (let index = 0; index < list.length; index++) {
      if (t < durations[index]) {
        const exitStart = list[index].length * perChar + hold;
        const amount = t < exitStart ? exitStart - t : durations[index] - t;
        setShift((s) => s + amount);
        return;
      }
      t -= durations[index];
    }
  };

  const schedule = (time: number): Frame => {
    const durations = slotDurations(list, perChar, hold);
    let t = time % Math.max(durations.reduce((a, b) => a + b, 0), 0.1);
    const blink = time % 0.52 < 0.26;
    for (let index = 0; index < list.length; index++) {
      if (t < durations[index]) return phase(list[index], t, blink);
      t -= durations[index];
    }
    return { word: list[0], visible: 0, caretOn: blink, selected: false, lift: 0, sinceLast: 10 };
  };

  const phase = (word: string[], t: number, blink: boolean): Frame => {
    const count = word.length;
    const typing = count * perChar;
    const result: Frame = { word, visible: 0, caretOn: true, selected: false, lift: 0, sinceLast: 10 };
    if (t < typing) {
      const shown = Math.min(Math.floor(t / perChar) + 1, count);
      return { ...result, visible: shown, sinceLast: t - (shown - 1) * perChar };
    }
    result.sinceLast = t - Math.max(count - 1, 0) * perChar;
    const afterHold = t - typing - hold;
    if (afterHold < 0) return { ...result, visible: count, caretOn: blink };
    if (selectMode) {
      const sel = afterHold < 0.3;
      return { ...result, visible: sel ? count : 0, selected: sel, caretOn: !sel && blink };
    }
    const p = Math.min(afterHold / 0.3, 1);
    return { ...result, visible: p < 1 ? count : 0, lift: p < 1 ? p * p : 0, caretOn: blink };
  };

  const frame = schedule(now() + shift);
  const count = frame.visible;
  const tail = Math.min(3, count);
  const text = frame.word.slice(0, count).join("");

  // The newest few glyphs pop in: back ease-out scale from the baseline, a small drop, a fade.
  const pop = (i: number) => {
    if (i < count - tail) return undefined;
    const newer = count - 1 - i;
    const age = frame.sinceLast + newer * perChar;
    const p = Math.min(age / 0.14, 1);
    const q = p - 1;
    const back = 1 + 2.70158 * q * q * q + 1.70158 * q * q;
    return { transformOrigin: "50% 100%", transform: `translateY(${12 * q * q}px) scale(${0.3 + 0.7 * back})`, opacity: Math.min(p * 3, 1) };
  };

  return (
    <div onClick={skip} style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center", cursor: "pointer" }}>
      <div style={{ width: 280, display: "flex", flexDirection: "column", alignItems: "flex-start", gap: 4 }}>
        <span style={{ fontFamily: fonts.text, fontSize: 28, lineHeight: "34px", fontWeight: 700, color: Palette.label }}>{ctx.t("We sweat the", "我们死磕每一处")}</span>
        <div style={{ height: 60, display: "flex", alignItems: "center", gap: 3 }}>
          <div
            style={{
              padding: "0 2px",
              borderRadius: 6,
              background: alpha(Palette.indigo, frame.selected ? 0.25 : 0),
              transform: `translateY(${-18 * frame.lift}px)`,
              opacity: 1 - frame.lift,
              minHeight: 1,
            }}
          >
            {count > 0 && (
              <Glyphs
                text={text}
                fill="linear-gradient(to bottom right, #6E7BFF, #A46BFF)"
                style={{ fontFamily: fonts.text, fontSize: 44, lineHeight: "53px", fontWeight: 800 }}
                glyph={(i) => pop(i)}
              />
            )}
          </div>
          <span style={{ width: 3, height: 44, borderRadius: 1.5, background: Palette.indigo, opacity: frame.caretOn ? 1 : 0 }} />
        </div>
        <div style={{ alignSelf: "stretch", display: "flex", justifyContent: "center", paddingTop: 18 }}>
          <DemoHint ctx={ctx} en="Tap to replace the word" zh="点击替换关键词" />
        </div>
      </div>
    </div>
  );
}
