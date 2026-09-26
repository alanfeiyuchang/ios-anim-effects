/** text.word-drum · 滚筒换词 (Text+WordDrum.swift) */
import { useEffect, useRef, useState } from "react";
import { DemoHint, Palette, fonts, useClock, useHaptics, type DemoProps } from "../../kit";
import { GradientText } from "./_text-kit";

const WORDS = [
  ["fast.", "飞快。"],
  ["alive.", "鲜活。"],
  ["human.", "有温度。"],
  ["calm.", "从容。"],
  ["magic.", "神奇。"],
];
const secs = () => performance.now() / 1000;

export default function WordDrum({ ctx }: DemoProps) {
  const haptics = useHaptics();
  useClock(true, ctx.isPreview ? 30 : undefined);
  const [start, setStart] = useState(() => secs());
  const holdRaw = ctx.n("hold");
  const hold = Math.max(holdRaw, 0.6);
  const turn = Math.min(0.55, hold * 0.8);
  const overshoot = ctx.n("overshoot");
  const radius = ctx.n("radius");

  // A new hold keeps the drum on the same word and the same point of a turn in progress.
  const lastHold = useRef(holdRaw);
  useEffect(() => {
    const oldHold = Math.max(lastHold.current, 0.6);
    lastHold.current = holdRaw;
    if (oldHold === hold) return;
    const oldTurn = Math.min(0.55, oldHold * 0.8);
    const now = secs();
    const elapsed = now - start;
    const steps = Math.floor(elapsed / oldHold);
    const inStep = elapsed - steps * oldHold;
    const newInStep = inStep > oldHold - oldTurn ? hold - turn + ((inStep - (oldHold - oldTurn)) / oldTurn) * turn : Math.min(inStep, hold - turn);
    setStart(now - (steps * hold + newInStep));
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [holdRaw]);

  const advance = () => {
    haptics.tap("light");
    const elapsed = secs() - start;
    const steps = Math.floor(elapsed / hold);
    const inStep = elapsed - steps * hold;
    const base = inStep > hold - turn ? steps + 1 : steps;
    setStart(secs() - (base * hold + (hold - turn)));
  };

  const easeOutBack = (x: number) => {
    const c3 = overshoot + 1;
    const t = x - 1;
    return 1 + c3 * t * t * t + overshoot * t * t;
  };
  const elapsed = secs() - start;
  const steps = Math.floor(elapsed / hold);
  const inStep = elapsed - steps * hold;
  const position = inStep > hold - turn ? steps + easeOutBack((inStep - (hold - turn)) / turn) : steps;

  const count = WORDS.length;
  const fade = "linear-gradient(transparent 0%, #000 22%, #000 78%, transparent 100%)";
  return (
    <div onClick={advance} style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center", cursor: "pointer" }}>
      <div style={{ width: 280, display: "flex", flexDirection: "column", alignItems: "flex-start", gap: 4 }}>
        <span style={{ fontFamily: fonts.text, fontSize: 26, lineHeight: "32px", fontWeight: 700, color: Palette.label }}>{ctx.t("Build apps that feel", "做出让人感觉")}</span>
        <div style={{ position: "relative", width: 280, height: 110, WebkitMaskImage: fade, maskImage: fade }}>
          {WORDS.map((word, index) => {
            let angle = ((index - position) * (360 / count)) % 360;
            if (angle > 180) angle -= 360;
            if (angle < -180) angle += 360;
            const r = (angle * Math.PI) / 180;
            return (
              <div
                key={index}
                style={{
                  position: "absolute",
                  left: 0,
                  top: 0,
                  height: 110,
                  display: "flex",
                  alignItems: "center",
                  opacity: Math.max(Math.cos(r), 0),
                  transform: `translateY(${radius * Math.sin(r)}px)`,
                }}
              >
                <div style={{ transform: `perspective(200px) rotateX(${-angle}deg)` }}>
                  <GradientText fill={Palette.sunset} style={{ fontFamily: fonts.text, fontSize: 40, lineHeight: "48px", fontWeight: 800 }}>
                    {ctx.lang === "zh" ? word[1] : word[0]}
                  </GradientText>
                </div>
              </div>
            );
          })}
        </div>
        <DemoHint ctx={ctx} en="Tap to turn" zh="点击转动" style={{ paddingTop: 20 }} />
      </div>
    </div>
  );
}
