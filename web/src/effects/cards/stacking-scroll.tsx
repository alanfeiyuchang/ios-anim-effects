/** cards.stacking-scroll · 堆叠滚动 (Cards+StackingScroll.swift) */
import { BedDouble, Coffee, Footprints, Landmark, Music, Plane, type LucideIcon } from "lucide-react";
import { useRef } from "react";
import { anim, black, fonts, useAutoplay, white, type DemoContext, type DemoProps } from "../../kit";
import { useScroller } from "../scroll/_kit";
import { StrokeBorder, diag, themeColors, tr, type LText } from "./shared";

interface Pass {
  title: LText;
  detail: LText;
  Icon: LucideIcon;
  filled: boolean;
  theme: number;
}

const PASSES: Pass[] = [
  { title: ["Flight", "航班"], detail: ["SFO → NRT · Gate 42", "SFO → NRT · 42 号登机口"], Icon: Plane, filled: true, theme: 0 },
  { title: ["Concert", "演唱会"], detail: ["Row 12 · Seat 8", "12 排 · 8 座"], Icon: Music, filled: false, theme: 1 },
  { title: ["Coffee Club", "咖啡会员"], detail: ["7 of 10 stamps", "已集 7 / 10 枚印章"], Icon: Coffee, filled: false, theme: 2 },
  { title: ["Gym", "健身房"], detail: ["Member since 2021", "2021 年起会员"], Icon: Footprints, filled: true, theme: 3 },
  { title: ["Museum", "美术馆"], detail: ["Tue · 14:00 entry", "周二 · 14:00 入场"], Icon: Landmark, filled: false, theme: 4 },
  { title: ["Hotel", "酒店"], detail: ["Room 1208 · 3 nights", "1208 房 · 3 晚"], Icon: BedDouble, filled: false, theme: 5 },
];

const CARD_H = 150;
const SPACING = 14;
const PIN_TOP = 16;

export default function StackingScroll({ ctx }: DemoProps) {
  const sc = useScroller({ axis: "y", bounce: true });
  const down = useRef(false);
  useAutoplay(
    ctx.isPreview,
    () => {
      down.current = !down.current;
      sc.scrollTo(down.current ? 700 : 0, anim.smoothD(2.8));
    },
    { every: 3.4 },
  );

  const peek = ctx.n("peek");
  const depth = ctx.n("depth");
  const blur = ctx.n("blur");
  const bury = (CARD_H + SPACING) * 3;

  return (
    <div {...sc.props} style={{ ...sc.props.style, position: "absolute", inset: 0, scrollbarWidth: "none" }}>
      <div ref={sc.contentRef} style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: SPACING, paddingTop: PIN_TOP, paddingBottom: 200 }}>
        {PASSES.map((pass, i) => {
          const pinLine = PIN_TOP + i * peek;
          const minY = PIN_TOP + i * (CARD_H + SPACING) - sc.offset;
          const overshoot = Math.max(pinLine - minY, 0);
          const buried = Math.min(overshoot / bury, 1);
          return (
            <div
              key={i}
              style={{
                position: "relative",
                zIndex: i,
                flexShrink: 0,
                transformOrigin: "50% 0",
                transform: `translateY(${overshoot}px) scale(${1 - depth * buried})`,
                filter: blur * buried > 0.01 ? `blur(${blur * buried}px)` : undefined,
              }}
            >
              <PassTile pass={pass} ctx={ctx} />
            </div>
          );
        })}
      </div>
    </div>
  );
}

function PassTile({ pass, ctx }: { pass: Pass; ctx: DemoContext }) {
  const { Icon } = pass;
  const plane = Icon === Plane ? { transform: "rotate(45deg)" } : undefined;
  return (
    <div style={{ position: "relative", width: 300, height: CARD_H, borderRadius: 24, boxShadow: `0 -2px 14px ${black(0.16)}` }}>
      <div style={{ position: "absolute", inset: 0, borderRadius: 24, overflow: "hidden", background: diag(themeColors(pass.theme)), color: "#fff" }}>
        <div style={{ position: "absolute", right: -14 + 4, top: "50%", transform: "translateY(calc(-50% + 10px))", color: white(0.16) }}>
          <Icon size={104} fill={pass.filled ? "currentColor" : "none"} strokeWidth={pass.filled ? 0 : 2.6} style={plane} />
        </div>
        <div style={{ position: "absolute", left: 16, top: 16, display: "flex", alignItems: "center", gap: 8 }}>
          <div style={{ width: 30, height: 30, borderRadius: 9, background: white(0.2), display: "grid", placeItems: "center" }}>
            <Icon size={15} fill={pass.filled ? "currentColor" : "none"} strokeWidth={pass.filled ? 0 : 2.8} style={plane} />
          </div>
          <span style={{ fontFamily: fonts.rounded, fontSize: 17, lineHeight: "22px", fontWeight: 700 }}>{tr(ctx, pass.title)}</span>
        </div>
        <div style={{ position: "absolute", left: 16, bottom: 16, display: "flex", flexDirection: "column", gap: 4 }}>
          <span style={{ fontSize: 15, lineHeight: "20px", fontWeight: 600 }}>{tr(ctx, pass.detail)}</span>
          <span style={{ fontFamily: fonts.mono, fontSize: 12, lineHeight: "16px", opacity: 0.75 }}>{`•••• ${1024 + pass.theme * 1311}`}</span>
        </div>
      </div>
      <StrokeBorder radius={24} color={`linear-gradient(${white(0.45)}, ${white(0.05)})`} />
    </div>
  );
}
