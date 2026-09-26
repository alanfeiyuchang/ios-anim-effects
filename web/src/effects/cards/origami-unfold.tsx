/** cards.origami-unfold · 折纸展开 (Cards+OrigamiUnfold.swift) */
import { animate, motion, useMotionValue, type MotionValue } from "motion/react";
import { Plane } from "lucide-react";
import { useEffect, useRef, useState } from "react";
import { DemoHint, Palette, black, delayed, fonts, spring, useAutoplay, useHaptics, type DemoContext, type DemoProps } from "../../kit";
import { Stage, persp, useMV } from "./shared";

const PANELS = 3;
const PANEL_H = 58;
const ROWS: [[string, string], [string, string]][] = [
  [["Boarding", "登机"], ["10:25 · Gate 42", "10:25 · 42 号登机口"]],
  [["Seat", "座位"], ["14A · Window", "14A · 靠窗"]],
  [["Group", "登机组"], ["2 · Priority", "2 · 优先"]],
];

export default function OrigamiUnfold({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [open, setOpen] = useState(false);
  const a0 = useMotionValue(90);
  const a1 = useMotionValue(90);
  const a2 = useMotionValue(90);
  const angles = [a0, a1, a2];
  const first = useRef(true);

  useEffect(() => {
    if (first.current) {
      first.current = false;
      return;
    }
    const stagger = ctx.n("stagger");
    angles.forEach((mv, i) => {
      const delay = open ? i * stagger : (PANELS - 1 - i) * stagger;
      animate(mv, open ? 0 : 90, delayed(spring(ctx.n("response"), 0.72), delay));
    });
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [open]);

  const toggle = () => {
    haptics.tap("soft");
    setOpen((o) => !o);
  };
  useAutoplay(ctx.isPreview, toggle, { every: 2.1 });

  const firstPanelDelay = open ? 0 : (PANELS - 1) * ctx.n("stagger");
  const bottom = open ? 4 : 18;

  return (
    <Stage gap={16}>
      <div style={{ height: 270, width: 270, flexShrink: 0 }}>
        <div onClick={toggle} style={{ width: 270, display: "flex", flexDirection: "column", filter: `drop-shadow(0 10px 16px ${black(0.14)})`, cursor: "pointer" }}>
          <motion.div
            initial={false}
            animate={{ borderBottomLeftRadius: bottom, borderBottomRightRadius: bottom }}
            transition={delayed(spring(ctx.n("response"), 0.72), firstPanelDelay)}
            style={{
              height: 78,
              padding: "0 18px",
              display: "flex",
              alignItems: "center",
              color: "#fff",
              background: Palette.ocean,
              borderTopLeftRadius: 18,
              borderTopRightRadius: 18,
              flexShrink: 0,
            }}
          >
            <City code="SFO" name={ctx.t("San Francisco", "旧金山")} align="flex-start" />
            <span style={{ flex: 1 }} />
            <Plane size={20} fill="currentColor" strokeWidth={0} style={{ transform: "rotate(45deg)" }} />
            <span style={{ flex: 1 }} />
            <City code="HND" name={ctx.t("Tokyo", "东京")} align="flex-end" />
          </motion.div>
          {angles.map((mv, i) => (
            <Panel key={i} angle={mv} index={i} shade={ctx.n("shade")} ctx={ctx} />
          ))}
        </div>
      </div>
      <DemoHint ctx={ctx} en="Tap to unfold" zh="点击展开" />
    </Stage>
  );
}

function City({ code, name, align }: { code: string; name: string; align: "flex-start" | "flex-end" }) {
  return (
    <div style={{ display: "flex", flexDirection: "column", alignItems: align, gap: 2 }}>
      <span style={{ fontFamily: fonts.rounded, fontSize: 26, lineHeight: "31px", fontWeight: 800 }}>{code}</span>
      <span style={{ fontSize: 11, lineHeight: "13px", fontWeight: 600, opacity: 0.8 }}>{name}</span>
    </div>
  );
}

function Panel({ angle: angleMV, index, shade, ctx }: { angle: MotionValue<number>; index: number; shade: number; ctx: DemoContext }) {
  const angle = useMV(angleMV);
  const rad = (angle * Math.PI) / 180;
  const folded = Math.abs(Math.sin(rad));
  const visible = Math.max(Math.cos(rad), 0);
  const [label, value] = ROWS[index % ROWS.length];
  const isLast = index === ROWS.length - 1;
  const bottom = isLast ? 18 : 4;
  return (
    <div style={{ height: PANEL_H * visible, flexShrink: 0, opacity: angle > 89 ? 0 : 1 }}>
      <div style={{ transformOrigin: "50% 0", transform: `${persp(270, PANEL_H, 0.45)} rotateX(${angle}deg)` }}>
        <div
          style={{
            position: "relative",
            width: 270,
            height: PANEL_H,
            padding: "0 18px",
            display: "flex",
            alignItems: "center",
            background: Palette.elevated,
            borderRadius: `4px 4px ${bottom}px ${bottom}px`,
            overflow: "hidden",
            fontSize: 13,
            lineHeight: "18px",
            fontWeight: 600,
          }}
        >
          <span style={{ color: Palette.secondaryLabel }}>{ctx.t(label[0], label[1])}</span>
          <span style={{ flex: 1 }} />
          <span style={{ fontVariantNumeric: "tabular-nums" }}>{ctx.t(value[0], value[1])}</span>
          <div style={{ position: "absolute", left: 0, right: 0, top: 0, height: 1, background: Palette.stroke }} />
          <div style={{ position: "absolute", inset: 0, background: black(shade * folded) }} />
        </div>
      </div>
    </div>
  );
}
