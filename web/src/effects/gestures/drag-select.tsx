/** gestures.drag-select · 滑动多选 (Gestures+DragSelect.swift) */
import { AnimatePresence, motion, type Transition } from "motion/react";
import { Check } from "lucide-react";
import { useEffect, useRef, useState } from "react";
import { DemoHint, NumericText, Palette, alpha, anim, clamp, localPoint, spring, textStyle, useAutoplay, useHaptics, type DemoContext, type DemoProps } from "../../kit";
import { CircleFillCutout, glyphs } from "./_b-icons";

const ROW_H = 46;
const SPACING = 8;
const COUNT = 5;
const PITCH = ROW_H + SPACING;

const NAMES: [string, string][] = [
  ["Mia · Weekend plan", "米娅 · 周末计划"],
  ["Design review", "设计评审"],
  ["Receipt #2048", "收据 #2048"],
  ["Team lunch", "团队午餐"],
  ["Flight update", "航班变动"],
];

const indexAt = (y: number) => clamp(Math.floor(y / PITCH), 0, COUNT - 1);
const sameSet = (a: Set<number>, b: Set<number>) => a.size === b.size && [...a].every((x) => b.has(x));

export default function DragSelect({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [selected, setSelected] = useState<Set<number>>(new Set());
  const selectedRef = useRef(selected);
  const baseline = useRef<Set<number>>(new Set());
  const [start, setStart] = useState<number | null>(null);
  const startRef = useRef<number | null>(null);
  const [current, setCurrent] = useState<number | null>(null);
  const currentRef = useRef<number | null>(null);
  const mode = useRef(true);
  const held = useRef(false);
  const pointerId = useRef<number | null>(null);
  const script = useRef<number[]>([]);
  const [selT, setSelT] = useState<Transition>(spring(0.3, 0.5));

  const cancelScript = () => {
    script.current.forEach((t) => window.clearTimeout(t));
    script.current = [];
  };
  useEffect(() => cancelScript, []);

  const setSel = (s: Set<number>) => {
    selectedRef.current = s;
    setSelected(s);
  };
  const setStartRow = (r: number | null) => {
    startRef.current = r;
    setStart(r);
  };
  const setCur = (r: number | null) => {
    currentRef.current = r;
    setCurrent(r);
  };

  const apply = (row: number, haptic: boolean) => {
    const first = startRef.current;
    if (first === null) return;
    const next = new Set(baseline.current);
    for (let i = Math.min(first, row); i <= Math.max(first, row); i++) {
      if (mode.current) next.add(i);
      else next.delete(i);
    }
    const changed = !sameSet(next, selectedRef.current);
    setSelT(spring(0.3, ctx.n("damping")));
    setCur(row);
    setSel(next);
    if (changed && haptic) haptics.selection();
  };

  const endSweep = () => {
    setStartRow(null);
    setCur(null);
    baseline.current = selectedRef.current;
  };

  const onMove = (e: React.PointerEvent<HTMLDivElement>) => {
    if (pointerId.current !== e.pointerId) return;
    const row = indexAt(localPoint(e, e.currentTarget).y);
    if (!held.current) {
      held.current = true;
      cancelScript();
      baseline.current = selectedRef.current;
      mode.current = !selectedRef.current.has(row);
      setCur(null);
      setStartRow(row);
    }
    if (row === currentRef.current) return;
    apply(row, true);
  };
  const onUp = (e: React.PointerEvent<HTMLDivElement>) => {
    if (pointerId.current !== e.pointerId) return;
    pointerId.current = null;
    if (!held.current) return;
    held.current = false;
    endSweep();
  };

  const simulate = () => {
    if (held.current) return;
    if (selectedRef.current.size > 0) {
      setSelT(spring(0.35, 0.8));
      setSel(new Set());
      return;
    }
    baseline.current = selectedRef.current;
    mode.current = true;
    const from = Math.floor(Math.random() * 2);
    const to = 3 + Math.floor(Math.random() * 2);
    setStartRow(from);
    cancelScript();
    let t = 0;
    for (let row = from; row <= to; row++) {
      const r = row;
      script.current.push(window.setTimeout(() => apply(r, false), t * 1000));
      t += 0.16;
    }
    script.current.push(window.setTimeout(endSweep, (t + 0.2) * 1000));
  };
  useAutoplay(ctx.isPreview, simulate, { every: 3.2, delay: 0.5 });

  const count = selected.size;
  const low = start !== null && current !== null ? Math.min(start, current) : 0;
  const high = start !== null && current !== null ? Math.max(start, current) : 0;
  const counterT = spring(0.3, 0.8);

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 12 }}>
      {/* Counter */}
      <div style={{ position: "relative", padding: "7px 14px", borderRadius: 999, ...textStyle.subheadline, fontWeight: 600 }}>
        <motion.div initial={false} animate={{ opacity: count > 0 ? 0 : 1 }} transition={counterT} style={{ position: "absolute", inset: 0, borderRadius: 999, background: Palette.elevated }} />
        <motion.div initial={false} animate={{ opacity: count > 0 ? 1 : 0 }} transition={counterT} style={{ position: "absolute", inset: 0, borderRadius: 999, background: Palette.primary }} />
        <div style={{ position: "relative", display: "flex", alignItems: "center", gap: 6, color: count > 0 ? "#fff" : Palette.secondaryLabel, transition: "color 0.3s" }}>
          <span style={{ position: "relative", display: "grid", width: 17, height: 17 }}>
            <AnimatePresence mode="popLayout" initial={false}>
              <motion.span
                key={count > 0 ? "on" : "off"}
                initial={{ scale: 0.4, opacity: 0, filter: "blur(3px)" }}
                animate={{ scale: 1, opacity: 1, filter: "blur(0px)" }}
                exit={{ scale: 0.4, opacity: 0, filter: "blur(3px)" }}
                transition={anim.snappyD(0.3)}
                style={{ display: "grid" }}
              >
                {count > 0 ? (
                  <CircleFillCutout size={17} glyph={glyphs.check} strokeWidth={2.6} />
                ) : (
                  <svg viewBox="0 0 24 24" width={17} height={17} fill="none" stroke="currentColor" strokeWidth={2.2} strokeDasharray="3.2 2.9" strokeLinecap="round">
                    <circle cx="12" cy="12" r="10" />
                  </svg>
                )}
              </motion.span>
            </AnimatePresence>
          </span>
          <NumericText value={count} />
          <span>{ctx.t("selected", "项已选")}</span>
        </div>
      </div>
      {/* Rows */}
      <div style={{ position: "relative", width: 300 }}>
        <div style={{ display: "flex", flexDirection: "column", gap: SPACING }}>
          {NAMES.map((name, i) => (
            <SelectRow key={i} ctx={ctx} title={name} tint={Palette.spectrum[i % Palette.spectrum.length]} isSelected={selected.has(i)} t={selT} />
          ))}
        </div>
        <AnimatePresence>
          {start !== null && current !== null && (
            <motion.div
              key="band"
              initial={{ opacity: 0, y: low * PITCH, height: (high - low) * PITCH + ROW_H }}
              animate={{ opacity: 1, y: low * PITCH, height: (high - low) * PITCH + ROW_H }}
              exit={{ opacity: 0, transition: anim.easeOut(0.2) }}
              transition={{ default: selT, opacity: anim.easeOut(0.15) }}
              style={{ position: "absolute", left: 2, top: 0, width: 40, borderRadius: 14, background: alpha(Palette.indigo, 0.16), pointerEvents: "none" }}
            />
          )}
        </AnimatePresence>
        <div
          onPointerDown={(e) => {
            if (pointerId.current !== null) return;
            pointerId.current = e.pointerId;
            e.currentTarget.setPointerCapture(e.pointerId);
            onMove(e);
          }}
          onPointerMove={onMove}
          onPointerUp={onUp}
          onPointerCancel={onUp}
          style={{ position: "absolute", left: 0, top: 0, width: 44, height: COUNT * PITCH - SPACING, touchAction: "none", cursor: "pointer" }}
        />
      </div>
      <DemoHint ctx={ctx} en="Slide down the checkbox column" zh="沿复选框一列向下滑" />
    </div>
  );
}

function SelectRow({ ctx, title, tint, isSelected, t }: { ctx: DemoContext; title: [string, string]; tint: string; isSelected: boolean; t: Transition }) {
  return (
    <motion.div
      initial={false}
      animate={{ scale: isSelected ? ctx.n("shrink") : 1 }}
      transition={t}
      style={{ position: "relative", height: ROW_H, borderRadius: 16, display: "flex", alignItems: "center", gap: 12, padding: "0 12px" }}
    >
      <motion.div initial={false} animate={{ opacity: isSelected ? 0 : 1 }} transition={t} style={{ position: "absolute", inset: 0, borderRadius: 16, background: Palette.elevated }} />
      <motion.div initial={false} animate={{ opacity: isSelected ? 1 : 0 }} transition={t} style={{ position: "absolute", inset: 0, borderRadius: 16, background: alpha(Palette.indigo, 0.12) }} />
      <div style={{ position: "absolute", inset: 0, borderRadius: 16, boxShadow: `inset 0 0 0 1px ${Palette.stroke}` }} />
      <div style={{ position: "relative", width: 22, height: 22, flexShrink: 0 }}>
        <motion.div initial={false} animate={{ opacity: isSelected ? 0 : 1 }} transition={t} style={{ position: "absolute", inset: 0, borderRadius: "50%", border: `2px solid ${Palette.labelAlpha(0.25)}` }} />
        <motion.div initial={false} animate={{ opacity: isSelected ? 1 : 0 }} transition={t} style={{ position: "absolute", inset: 0, borderRadius: "50%", border: `2px solid ${Palette.indigo}` }} />
        <AnimatePresence>
          {isSelected && (
            <motion.div
              initial={{ scale: 0.2, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              exit={{ scale: 0.2, opacity: 0 }}
              transition={t}
              style={{ position: "absolute", inset: 0, borderRadius: "50%", background: Palette.indigo, display: "grid", placeItems: "center", color: "#fff" }}
            >
              <Check size={12} strokeWidth={4} />
            </motion.div>
          )}
        </AnimatePresence>
      </div>
      <div style={{ position: "relative", width: 28, height: 28, flexShrink: 0, borderRadius: "50%", background: `linear-gradient(color-mix(in srgb, ${tint} 88%, white), ${tint})` }} />
      <span style={{ position: "relative", ...textStyle.subheadline, fontWeight: 500, whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>{ctx.t(...title)}</span>
    </motion.div>
  );
}
