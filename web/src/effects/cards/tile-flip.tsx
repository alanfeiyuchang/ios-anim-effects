/** cards.tile-flip · 马赛克翻转 (Cards+TileFlip.swift) */
import { animate, useMotionValue } from "motion/react";
import { MoonStar, Sun } from "lucide-react";
import { useEffect, useRef, useState } from "react";
import { DemoHint, black, delayed, fonts, spring, useAutoplay, useHaptics, white, type DemoProps } from "../../kit";
import { Stage, persp, useMV } from "./shared";

const COLUMNS = 4;
const ROWS = 3;
const TW = 60;
const TH = 56;
const GAP = 4;
const GW = COLUMNS * TW + (COLUMNS - 1) * GAP;
const GH = ROWS * TH + (ROWS - 1) * GAP;

function order(pattern: number, column: number, row: number) {
  switch (pattern) {
    case 1:
      return Math.round((Math.abs(column - 1.5) + Math.abs(row - 1)) * 2);
    case 2:
      return (column * 7 + row * 5 + 3) % 9;
    default:
      return column + row;
  }
}

export default function TileFlip({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [turns, setTurns] = useState(0);
  const flip = () => {
    haptics.tap("soft");
    setTurns((t) => t + 1);
  };
  useAutoplay(ctx.isPreview, flip, { every: 2.0 });

  return (
    <Stage gap={30}>
      <div
        onClick={flip}
        style={{ display: "flex", flexDirection: "column", gap: GAP, filter: `drop-shadow(0 10px 16px ${black(0.18)})`, cursor: "pointer" }}
      >
        {Array.from({ length: ROWS }, (_, row) => (
          <div key={row} style={{ display: "flex", gap: GAP }}>
            {Array.from({ length: COLUMNS }, (_, column) => (
              <Tile
                key={column}
                column={column}
                row={row}
                turns={turns}
                delay={order(ctx.i("pattern"), column, row) * ctx.n("stagger")}
                vertical={ctx.b("vertical")}
              />
            ))}
          </div>
        ))}
      </div>
      <DemoHint ctx={ctx} en="Tap to flip the mosaic" zh="点击翻转马赛克" />
    </Stage>
  );
}

function Tile({ column, row, turns, delay, vertical }: { column: number; row: number; turns: number; delay: number; vertical: boolean }) {
  const angleMV = useMotionValue(0);
  const first = useRef(true);
  useEffect(() => {
    if (first.current) {
      first.current = false;
      return;
    }
    animate(angleMV, turns * 180, delayed(spring(0.55, 0.72), delay));
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [turns]);
  const angle = useMV(angleMV);
  const remainder = angle % 360;
  const normalized = remainder < 0 ? remainder + 360 : remainder;
  const showBack = normalized > 90 && normalized < 270;
  const dip = Math.abs(Math.sin((angle * Math.PI) / 180));
  const rot = vertical ? "rotateX" : "rotateY";
  return (
    <div style={{ width: TW, height: TH, transform: `scale(${1 - 0.12 * dip})` }}>
      <div style={{ position: "relative", width: TW, height: TH, transform: `${persp(TW, TH, 0.5)} ${rot}(${angle}deg)` }}>
        <div style={{ position: "absolute", inset: 0, opacity: showBack ? 0 : 1 }}>
          <Slice night column={column} row={row} />
        </div>
        <div style={{ position: "absolute", inset: 0, opacity: showBack ? 1 : 0, transform: `${rot}(180deg)` }}>
          <Slice night={false} column={column} row={row} />
        </div>
      </div>
    </div>
  );
}

function Slice({ night, column, row }: { night: boolean; column: number; row: number }) {
  return (
    <div style={{ position: "relative", width: TW, height: TH, borderRadius: 8, overflow: "hidden" }}>
      <div style={{ position: "absolute", left: -column * (TW + GAP), top: -row * (TH + GAP) }}>
        <Artwork night={night} />
      </div>
    </div>
  );
}

/** The full picture each tile shows a slice of: a night sky or a sunny day. */
function Artwork({ night }: { night: boolean }) {
  const sunColor = night ? white(0.95) : "#FFC247";
  return (
    <div
      style={{
        position: "relative",
        width: GW,
        height: GH,
        overflow: "hidden",
        background: night ? "linear-gradient(#1B1D4B, #5B3BFF, #A46BFF)" : "linear-gradient(#3AC4FF, #8FE3FF, #FFE7A8)",
      }}
    >
      <div
        style={{
          position: "absolute",
          left: GW / 2 + 58 - 38,
          top: GH / 2 - 30 - 38,
          color: sunColor,
          filter: `drop-shadow(0 0 16px ${night ? "rgb(255 255 255 / 0.5)" : "rgb(255 194 71 / 0.5)"})`,
        }}
      >
        {night ? <MoonStar size={76} fill="currentColor" strokeWidth={0.8} /> : <Sun size={76} fill="currentColor" strokeWidth={2.4} />}
      </div>
      <Mountains night={night} />
      <div style={{ position: "absolute", left: GW / 2 - 78 - 40, top: GH / 2 - 58 - 14, width: 80, textAlign: "center", fontFamily: fonts.rounded, fontSize: 22, lineHeight: "28px", fontWeight: 700, fontVariantNumeric: "tabular-nums", color: "#fff", textShadow: `0 2px 4px ${black(0.2)}` }}>
        {night ? "22:40" : "10:15"}
      </div>
    </div>
  );
}

/** SF `mountain.2.fill` at 110 pt, drawn in artwork coordinates: two rounded peaks with snow-line cut-outs. */
function Mountains({ night }: { night: boolean }) {
  const fill = night ? "rgb(14 15 42 / 0.9)" : "#1A9E9A";
  const cut = night ? "rgb(120 80 230 / 0.55)" : "rgb(220 246 255 / 0.75)";
  return (
    <svg width={GW} height={GH} style={{ position: "absolute", inset: 0, overflow: "visible" }}>
      <path d="M-16 200 L29 121 Q41 101 53 121 L128 200 Z" fill={fill} />
      <path d="M36 200 L99 99 Q110 81 121 99 L196 200 Z" fill={fill} />
      <g fill="none" stroke={cut} strokeWidth={4} strokeLinecap="round" strokeLinejoin="round">
        <path d="M-2 152 Q10 142 20 150 T44 146 Q52 142 58 150" />
        <path d="M84 126 Q94 118 102 125 T122 122 Q130 118 136 124" />
      </g>
    </svg>
  );
}
