/** cards.scratch-reveal · 刮刮卡 (Cards+ScratchReveal.swift) */
import { motion } from "motion/react";
import { Hand, Sparkle } from "lucide-react";
import { useEffect, useId, useRef, useState } from "react";
import { DemoHint, Palette, anim, black, delayed, fonts, spring, useAutoplay, useHaptics, usePan, white, type DemoContext, type DemoProps, type Point } from "../../kit";
import { Stage, StrokeBorder } from "./shared";

const W = 280;
const H = 170;
const CELL = 14;
const COLUMNS = Math.ceil(W / CELL);
const ROWS = Math.ceil(H / CELL);
const TOTAL = COLUMNS * ROWS;
const SPARKLES = [
  [-110, -52], [-84, 50], [96, -58], [116, 30], [70, 62],
];

export default function ScratchReveal({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [strokes, setStrokes] = useState<Point[][]>([]);
  const strokesRef = useRef<Point[][]>([]);
  const cells = useRef(new Set<number>());
  const [revealed, setRevealed] = useState(false);
  const revealedRef = useRef(false);
  const [round, setRound] = useState(0);
  const autoStep = useRef(0);
  const dragging = useRef(false);
  const startedRevealed = useRef(false);
  const intro = useRef<number[]>([]);
  useEffect(() => () => intro.current.forEach((id) => window.clearTimeout(id)), []);

  const commit = (next: Point[][]) => {
    strokesRef.current = next;
    setStrokes(next);
  };
  const appendPoint = (p: Point) => {
    const s = strokesRef.current.slice();
    s[s.length - 1] = [...s[s.length - 1], p];
    commit(s);
  };
  const brush = ctx.n("brush");

  /** Records grid cells under the brush and fires the reveal once enough foil is gone. */
  const mark = (p: Point) => {
    const radius = brush / 2;
    const before = cells.current.size;
    const minCol = Math.max(Math.floor((p.x - radius) / CELL), 0);
    const maxCol = Math.min(Math.floor((p.x + radius) / CELL), COLUMNS - 1);
    const minRow = Math.max(Math.floor((p.y - radius) / CELL), 0);
    const maxRow = Math.min(Math.floor((p.y + radius) / CELL), ROWS - 1);
    for (let row = minRow; row <= maxRow; row++) {
      for (let col = minCol; col <= maxCol; col++) {
        const cx = (col + 0.5) * CELL;
        const cy = (row + 0.5) * CELL;
        if (Math.hypot(cx - p.x, cy - p.y) <= radius + CELL * 0.35) cells.current.add(row * COLUMNS + col);
      }
    }
    if (Math.floor(cells.current.size / 6) !== Math.floor(before / 6)) haptics.selection();
    if (!revealedRef.current && cells.current.size / TOTAL >= ctx.n("threshold")) {
      revealedRef.current = true;
      setRevealed(true);
      haptics.success();
    }
  };

  const deal = () => {
    commit([]);
    cells.current = new Set();
    setRound((r) => r + 1);
    revealedRef.current = false;
    setRevealed(false);
  };

  const pan = usePan({
    onChange: ({ location }) => {
      if (!dragging.current) {
        dragging.current = true;
        intro.current.forEach((id) => window.clearTimeout(id));
        startedRevealed.current = revealedRef.current;
        if (!revealedRef.current) commit([...strokesRef.current, []]);
      }
      if (startedRevealed.current || revealedRef.current || strokesRef.current.length === 0) return;
      appendPoint(location);
      mark(location);
    },
    onEnd: () => {
      if (!dragging.current) return;
      dragging.current = false;
      if (startedRevealed.current) {
        haptics.tap("soft");
        deal();
      }
      startedRevealed.current = false;
    },
  });

  useAutoplay(
    ctx.isPreview,
    () => {
      if (!ctx.isPreview) {
        // Detail stage, once on arrival: a short soft swoosh (drawn only, not counted).
        if (strokesRef.current.length > 0 || revealedRef.current) return;
        commit([[]]);
        for (let step = 0; step < 18; step++) {
          intro.current.push(
            window.setTimeout(() => {
              if (strokesRef.current.length === 0 || revealedRef.current) return;
              const t = step / 17;
              appendPoint({ x: 70 + 140 * t, y: 96 - 34 * Math.sin(t * Math.PI) });
            }, step * 24),
          );
        }
        return;
      }
      const steps = 90;
      const k = autoStep.current;
      if (k < steps) {
        const t = k / (steps - 1);
        const lanes = 5;
        const lane = Math.min(Math.floor(t * lanes), lanes - 1);
        const local = t * lanes - lane;
        const forward = lane % 2 === 0;
        const x = 24 + (W - 48) * (forward ? local : 1 - local);
        const y = 22 + (H - 44) * ((lane + local * 0.9) / lanes);
        if (strokesRef.current.length === 0) commit([[]]);
        if (!revealedRef.current) {
          appendPoint({ x, y });
          mark({ x, y });
        }
      } else if (k === steps + 30) {
        deal();
        autoStep.current = -1;
      }
      autoStep.current += 1;
    },
    { every: 0.05, delay: 0.3 },
  );

  return (
    <Stage gap={22}>
      <div {...pan} style={{ ...pan.style, position: "relative", width: W, height: H, borderRadius: 22, boxShadow: `0 10px 18px ${black(0.18)}`, cursor: "crosshair" }}>
        <div style={{ position: "absolute", inset: 0, borderRadius: 22, overflow: "hidden" }}>
          <Prize round={round} revealed={revealed} ctx={ctx} />
          <motion.div
            initial={false}
            animate={{ scale: revealed ? 1.04 : 1, opacity: revealed ? 0 : 1 }}
            transition={revealed ? anim.easeOut(0.35) : anim.smoothD(0.3)}
            style={{ position: "absolute", inset: 0, pointerEvents: "none" }}
          >
            <Foil gold={ctx.i("foil") === 1} strokes={strokes} brush={brush} ctx={ctx} />
          </motion.div>
        </div>
        <StrokeBorder radius={22} color={white(0.25)} />
      </div>
      <DemoHint ctx={ctx} en={revealed ? "Tap the card for a new one" : "Scratch the foil"} zh={revealed ? "点击卡片换一张" : "刮开涂层"} />
    </Stage>
  );
}

function Prize({ round, revealed, ctx }: { round: number; revealed: boolean; ctx: DemoContext }) {
  const amounts = ctx.lang === "zh" ? ["¥88", "¥520", "¥66", "¥128"] : ["$25", "$100", "$10", "$50"];
  return (
    <div style={{ position: "absolute", inset: 0, background: "linear-gradient(to bottom right, #FFF4E0, #FFE1EC)" }}>
      {SPARKLES.map(([sx, sy], i) => {
        const size = 10 + ((i * 7) % 14);
        return (
          <motion.div
            key={i}
            initial={false}
            animate={{ scale: revealed ? 1 : 0.4, opacity: revealed ? 1 : 0.5 }}
            transition={delayed(spring(0.5, 0.55), 0.1 + i * 0.05)}
            style={{ position: "absolute", left: W / 2 + sx - size * 0.6, top: H / 2 + sy - size * 0.6, color: Palette.amber }}
          >
            <Sparkle size={size * 1.2} fill="currentColor" strokeWidth={0} />
          </motion.div>
        );
      })}
      <motion.div
        initial={false}
        animate={{ scale: revealed ? 1 : 0.92 }}
        transition={spring(0.45, 0.6)}
        style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 4 }}
      >
        <span style={{ fontSize: 12, lineHeight: "16px", fontWeight: 800, letterSpacing: 2, color: "rgb(217 70 143 / 0.8)" }}>{ctx.t("YOU WON", "恭喜获得")}</span>
        <span
          style={{
            fontFamily: fonts.rounded,
            fontSize: 54,
            lineHeight: "64px",
            fontWeight: 900,
            fontVariantNumeric: "tabular-nums",
            background: Palette.sunset,
            WebkitBackgroundClip: "text",
            backgroundClip: "text",
            color: "transparent",
          }}
        >
          {amounts[round % amounts.length]}
        </span>
        <span style={{ fontSize: 11, lineHeight: "13px", fontWeight: 600, color: black(0.45) }}>{ctx.t("Cash reward · valid 7 days", "现金红包 · 7 天内有效")}</span>
      </motion.div>
    </div>
  );
}

/** The foil, masked by the scratched strokes (erased with a feathered round brush). */
function Foil({ gold, strokes, brush, ctx }: { gold: boolean; strokes: Point[][]; brush: number; ctx: DemoContext }) {
  const id = useId().replace(/:/g, "");
  const colors = gold ? ["#F3DDA0", "#C9A24B", "#F7E7B8", "#B08A3E"] : ["#E4E7EE", "#A9B0BE", "#EEF0F5", "#959DAD"];
  const lines: string[] = [];
  for (let x = -H; x < W; x += 6) lines.push(`M${x} ${H}L${x + H} 0`);
  const label = (dx: number, dy: number, color: string) => (
    <g transform={`translate(${dx} ${dy})`} fill={color}>
      <Hand x={W / 2 - 15} y={H / 2 - 32} width={30} height={30} fill={color} stroke={color} strokeWidth={1.2} />
      <text x={W / 2} y={H / 2 + 22} textAnchor="middle" fontFamily={fonts.rounded} fontSize={15} fontWeight={800} letterSpacing={2}>
        {ctx.t("SCRATCH HERE", "刮开此处")}
      </text>
    </g>
  );
  return (
    <svg width={W} height={H} style={{ position: "absolute", inset: 0 }}>
      <defs>
        <linearGradient id={`${id}g`} x1="0" y1="0" x2="1" y2="1">
          {colors.map((c, i) => (
            <stop key={i} offset={i / (colors.length - 1)} stopColor={c} />
          ))}
        </linearGradient>
        <filter id={`${id}b`} filterUnits="userSpaceOnUse" x={-20} y={-20} width={W + 40} height={H + 40}>
          <feGaussianBlur stdDeviation={brush * 0.2} />
        </filter>
        <mask id={`${id}m`} maskUnits="userSpaceOnUse" x="0" y="0" width={W} height={H}>
          <rect width={W} height={H} fill="#fff" />
          <g filter={`url(#${id}b)`} fill="none" stroke="#000" strokeWidth={brush} strokeLinecap="round" strokeLinejoin="round">
            {strokes.map((s, i) =>
              s.length === 0 ? null : <path key={i} d={`M${s[0].x} ${s[0].y}L${s[0].x + 0.1} ${s[0].y}${s.slice(1).map((p) => `L${p.x} ${p.y}`).join("")}`} />,
            )}
          </g>
        </mask>
      </defs>
      <g mask={`url(#${id}m)`}>
        <rect width={W} height={H} fill={`url(#${id}g)`} />
        <path d={lines.join("")} stroke={white(0.18)} strokeWidth={1} />
        {label(0.5, 1, white(0.6))}
        {label(0, 0, black(0.28))}
      </g>
    </svg>
  );
}
