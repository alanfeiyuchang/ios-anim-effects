/** text.split-flap · 翻牌显示 (Text+SplitFlap.swift) */
import { PlaneTakeoff } from "lucide-react";
import { useEffect, useRef, useState } from "react";
import { DemoHint, Palette, black, fonts, useAutoplay, useClock, type DemoProps } from "../../kit";
import { chars } from "./_text-kit";

const WHEEL = chars(" 0123456789:.-ABCDEFGHIJKLMNOPQRSTUVWXYZ");
const MAX_FLIPS = 10;
const ROW_DELAY = 0.12;
const W = 28;
const H = 42;

const BOARDS = [
  ["NRT 09:40", "SFO 11:15", "CDG 13:05"],
  ["PVG 10:20", "JFK 12:55", "LHR 16:30"],
  ["HND 07:50", "SIN 14:10", "DXB 22:35"],
];

/** The characters a cell shows on its way from `from` to `to`, both ends included. */
function path(from: string, to: string): string[] {
  const n = WHEEL.length;
  const a = Math.max(WHEEL.indexOf(from), 0);
  const b = Math.max(WHEEL.indexOf(to), 0);
  const distance = (b - a + n) % n;
  if (distance <= 0) return [from];
  const result = [from];
  if (distance <= MAX_FLIPS) {
    for (let step = 1; step <= distance; step++) result.push(WHEEL[(a + step) % n]);
    return result;
  }
  const first = b - MAX_FLIPS + 1 + n;
  for (let step = 0; step < MAX_FLIPS; step++) result.push(WHEEL[(first + step) % n]);
  return result;
}

interface Plan {
  paths: string[][][];
  start: number;
}
const still = (rows: string[]): Plan => ({ paths: rows.map((r) => chars(r).map((c) => [c])), start: -Infinity });

export default function SplitFlap({ ctx }: DemoProps) {
  const [boardIndex, setBoardIndex] = useState(0);
  const [plan, setPlan] = useState<Plan>(() => still(BOARDS[0]));
  const [running, setRunning] = useState(false);
  const step = Math.max(ctx.n("step"), 0.01);
  const stagger = ctx.n("stagger");
  useClock(running, ctx.isPreview ? 30 : undefined);
  const now = performance.now() / 1000;

  const delay = (row: number, column: number) => row * ROW_DELAY + column * stagger;
  const columns = Math.max(...plan.paths.map((r) => r.length), 0);
  const totalDuration = delay(Math.max(plan.paths.length - 1, 0), Math.max(columns - 1, 0)) + MAX_FLIPS * step;

  const cellState = (p: Plan, row: number, column: number, at: number) => {
    const cell = p.paths[row][column];
    const first = cell[0];
    const last = cell[cell.length - 1];
    const elapsed = at - p.start - delay(row, column);
    if (!(elapsed > 0)) return { previous: first, current: first, progress: 1 };
    const flip = Math.floor(elapsed / step);
    if (flip >= cell.length - 1) return { previous: last, current: last, progress: 1 };
    return { previous: cell[flip], current: cell[flip + 1], progress: elapsed / step - flip };
  };

  useEffect(() => {
    if (boardIndex === 0) return;
    const id = window.setTimeout(() => setRunning(false), (totalDuration + 0.1) * 1000);
    return () => window.clearTimeout(id);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [boardIndex]);

  const planRef = useRef(plan);
  planRef.current = plan;
  const indexRef = useRef(boardIndex);
  indexRef.current = boardIndex;
  const update = () => {
    const at = performance.now() / 1000;
    const current = planRef.current;
    const next = BOARDS[(indexRef.current + 1) % BOARDS.length];
    const paths = next.map((text, row) =>
      chars(text).map((target, column) => {
        let visible = " ";
        if (row < current.paths.length && column < current.paths[row].length) {
          const s = cellState(current, row, column, at);
          visible = s.progress < 0.5 ? s.previous : s.current;
        }
        return path(visible, target);
      }),
    );
    setPlan({ paths, start: at });
    setRunning(true);
    indexRef.current += 1;
    setBoardIndex((i) => i + 1);
  };
  useAutoplay(ctx.isPreview, update, { every: 3.0, delay: 1.0 });

  return (
    <div onClick={update} style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center", cursor: "pointer" }}>
      <div
        className="ml-dark"
        style={{
          padding: 16,
          borderRadius: 20,
          background: "rgb(18 18 18)",
          boxShadow: `0 10px 20px ${black(0.25)}`,
          display: "flex",
          flexDirection: "column",
          alignItems: "flex-start",
          gap: 10,
        }}
      >
        <div style={{ display: "flex", alignItems: "center", gap: 6, fontSize: 15, lineHeight: "20px", fontWeight: 700, color: Palette.amber }}>
          <PlaneTakeoff size={16} strokeWidth={2.4} />
          <span>{ctx.t("Departures", "出发航班")}</span>
        </div>
        <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
          {plan.paths.map((cells, row) => (
            <div key={row} style={{ display: "flex", gap: 3 }}>
              {cells.map((_, column) => {
                const s = cellState(plan, row, column, now);
                return <FlapFace key={column} {...s} />;
              })}
            </div>
          ))}
        </div>
        <DemoHint ctx={ctx} en="Tap to update the board" zh="点击更新信息牌" style={{ paddingTop: 4 }} />
      </div>
    </div>
  );
}

function FlapFace({ current, previous, progress }: { current: string; previous: string; progress: number }) {
  const p = Math.min(Math.max(progress, 0), 1);
  return (
    <div style={{ position: "relative", width: W, height: H, perspective: 84 }}>
      <FlapHalf character={current} top />
      <FlapHalf character={previous} top={false} />
      {p < 0.5 ? (
        <FlapHalf character={previous} top shade={p * 0.25} rotate={-p * 180} />
      ) : (
        <FlapHalf character={current} top={false} shade={(1 - p) * 0.25} rotate={(1 - p) * 180} />
      )}
      <div style={{ position: "absolute", left: 0, right: 0, top: H / 2 - 0.5, height: 1, background: black(0.6) }} />
    </div>
  );
}

/** One half of a cell; `shade` is SwiftUI's additive `.brightness(-shade)`. */
function FlapHalf({ character, top, shade = 0, rotate = 0 }: { character: string; top: boolean; shade?: number; rotate?: number }) {
  const g = (v: number) => {
    const c = Math.round(Math.max(v - shade, 0) * 255);
    return `rgb(${c} ${c} ${c})`;
  };
  return (
    <div
      style={{
        position: "absolute",
        inset: 0,
        clipPath: top ? `inset(0 0 ${H / 2}px 0)` : `inset(${H / 2}px 0 0 0)`,
        transform: rotate ? `rotateX(${rotate}deg)` : undefined,
        backfaceVisibility: "visible",
      }}
    >
      <div
        style={{
          position: "absolute",
          inset: 0,
          borderRadius: 5,
          background: `linear-gradient(${g(0.2)}, ${g(0.13)})`,
          display: "grid",
          placeItems: "center",
          fontFamily: fonts.mono,
          fontSize: 26,
          fontWeight: 700,
          color: g(0.96),
          whiteSpace: "pre",
        }}
      >
        {character}
      </div>
    </div>
  );
}
