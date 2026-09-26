/** feedback.coach-spotlight · 引导聚光灯 (Feedback+Spotlight.swift) */
import { motion, useTransform } from "motion/react";
import { Ellipsis, Heart, Plus, Share } from "lucide-react";
import { useEffect, useState } from "react";
import { DemoHint, Palette, PlaceholderLines, alpha, spring, useAutoplay, useClock, useHaptics, type DemoProps } from "../../kit";
import { useAnimated } from "./shared";

const W = 300;
const H = 260;
const STEPS = [
  { x: 193, y: 34, r: 22, title: ["Share with your team", "与团队分享"], below: true },
  { x: 233, y: 34, r: 22, title: ["Save to favorites", "加入收藏"], below: true },
  { x: 256, y: 216, r: 34, title: ["Create something new", "开始新的创作"], below: false },
];
const tipPos = (s: (typeof STEPS)[number]) => ({ x: Math.min(Math.max(s.x, 112), W - 112), y: s.below ? s.y + s.r + 42 : s.y - s.r - 42 });

export default function CoachSpotlight({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [step, setStep] = useState(0);
  const current = STEPS[step % STEPS.length];
  const [cx, cxTo] = useAnimated(STEPS[0].x);
  const [cy, cyTo] = useAnimated(STEPS[0].y);
  const [r, rTo] = useAnimated(STEPS[0].r);
  const [tx, txTo] = useAnimated(tipPos(STEPS[0]).x);
  const [ty, tyTo] = useAnimated(tipPos(STEPS[0]).y);
  const response = ctx.n("response");

  useEffect(() => {
    const t = spring(response, 0.78);
    const s = STEPS[step % STEPS.length];
    const p = tipPos(s);
    cxTo(s.x, t);
    cyTo(s.y, t);
    rTo(s.r, t);
    txTo(p.x, t);
    tyTo(p.y, t);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [step]);

  const advance = () => {
    haptics.selection();
    setStep((s) => s + 1);
  };
  useAutoplay(ctx.isPreview, advance, { every: 1.8, delay: 1.0 });

  const hole = useTransform(() => {
    const x = cx.get(), y = cy.get(), rr = Math.max(r.get(), 0);
    return `M0 0H${W}V${H}H0Z M${x - rr} ${y} a${rr} ${rr} 0 1 0 ${rr * 2} 0 a${rr} ${rr} 0 1 0 ${-rr * 2} 0Z`;
  });
  const ringSize = useTransform(r, (v) => v * 2);
  const ringLeft = useTransform(() => cx.get() - r.get());
  const ringTop = useTransform(() => cy.get() - r.get());

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 16 }}>
      <div
        onClick={advance}
        style={{ position: "relative", width: W, height: H, flexShrink: 0, borderRadius: 24, overflow: "hidden", boxShadow: "0 10px 18px rgb(0 0 0 / 0.12)", cursor: "pointer" }}
      >
        <MockScreen zh={ctx.lang === "zh"} />
        <svg width={W} height={H} style={{ position: "absolute", inset: 0 }}>
          <motion.path d={hole} fill={`rgb(0 0 0 / ${ctx.n("dim")})`} fillRule="evenodd" />
        </svg>
        <motion.div style={{ position: "absolute", left: ringLeft, top: ringTop, width: ringSize, height: ringSize, borderRadius: "50%", boxShadow: "inset 0 0 0 1.5px rgb(255 255 255 / 0.9)" }} />
        {ctx.b("pulse") && (
          <motion.div style={{ position: "absolute", left: cx, top: cy, width: 0, height: 0 }}>
            <Pulse radius={current.r} fps={ctx.isPreview ? 30 : undefined} />
          </motion.div>
        )}
        <motion.div style={{ position: "absolute", left: tx, top: ty, width: 0, height: 0 }}>
          <div style={{ position: "absolute", left: 0, top: 0, transform: "translate(-50%, -50%)" }}>
            <Tooltip title={current.title[ctx.lang === "zh" ? 1 : 0]} index={step % STEPS.length} zh={ctx.lang === "zh"} />
          </div>
        </motion.div>
        <div style={{ position: "absolute", inset: 0, borderRadius: 24, boxShadow: `inset 0 0 0 1px ${Palette.stroke}`, pointerEvents: "none" }} />
      </div>
      <DemoHint ctx={ctx} en="Tap to go to the next tip" zh="点击进入下一条提示" />
    </div>
  );
}

function Pulse({ radius, fps }: { radius: number; fps?: number }) {
  const t = useClock(true, fps) + performance.timeOrigin / 1000;
  return (
    <>
      {[0, 1].map((i) => {
        const age = (t / 1.4 + i * 0.5) % 1;
        const side = (radius + 16 * age) * 2;
        return (
          <div
            key={i}
            style={{ position: "absolute", left: -side / 2 - 1, top: -side / 2 - 1, width: side + 2, height: side + 2, borderRadius: "50%", border: `2px solid rgb(255 255 255 / ${0.7 * (1 - age)})` }}
          />
        );
      })}
    </>
  );
}

function Tooltip({ title, index, zh }: { title: string; index: number; zh: boolean }) {
  return (
    <div style={{ display: "flex", alignItems: "center", gap: 10, padding: "9px 12px", borderRadius: 14, background: Palette.elevated, boxShadow: "0 6px 12px rgb(0 0 0 / 0.25)", whiteSpace: "nowrap" }}>
      <div style={{ display: "flex", flexDirection: "column", gap: 2 }}>
        <span style={{ fontSize: 15, lineHeight: "20px", fontWeight: 600 }}>{title}</span>
        <span style={{ fontSize: 11, lineHeight: "13px", fontWeight: 500, fontVariantNumeric: "tabular-nums", color: Palette.secondaryLabel }}>
          {index + 1} / {STEPS.length}
        </span>
      </div>
      <span style={{ fontSize: 12, lineHeight: "16px", fontWeight: 700, color: "#fff", padding: "6px 10px", borderRadius: 999, background: Palette.primary }}>{zh ? "下一步" : "Next"}</span>
    </div>
  );
}

function MockScreen({ zh }: { zh: boolean }) {
  return (
    <div style={{ position: "absolute", inset: 0, background: Palette.elevated, padding: "12px 16px 0", display: "flex", flexDirection: "column", gap: 14 }}>
      <div style={{ height: 44, display: "flex", alignItems: "center", gap: 18, color: Palette.indigo }}>
        <span style={{ fontSize: 20, lineHeight: "25px", fontWeight: 700, color: Palette.label }}>{zh ? "资料库" : "Library"}</span>
        <span style={{ flex: 1 }} />
        <span style={{ width: 22, display: "grid", placeItems: "center" }}><Share size={18} strokeWidth={2.4} /></span>
        <span style={{ width: 22, display: "grid", placeItems: "center" }}><Heart size={18} strokeWidth={2.4} /></span>
        <span style={{ width: 22, display: "grid", placeItems: "center" }}><Ellipsis size={18} strokeWidth={2.8} /></span>
      </div>
      <div style={{ height: 96, display: "flex", gap: 10 }}>
        <div style={{ flex: 1, borderRadius: 14, background: Palette.aurora }} />
        <div style={{ flex: 1, borderRadius: 14, background: Palette.sunset }} />
      </div>
      <PlaceholderLines count={3} />
      <div style={{ position: "absolute", left: 256 - 28, top: 216 - 28, width: 56, height: 56, borderRadius: "50%", background: Palette.primary, boxShadow: `0 5px 10px ${alpha(Palette.indigo, 0.35)}`, display: "grid", placeItems: "center", color: "#fff" }}>
        <Plus size={24} strokeWidth={2.6} />
      </div>
    </div>
  );
}
