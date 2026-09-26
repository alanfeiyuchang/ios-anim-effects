/** loading.mosaic-resolve · 马赛克渐显 (Loading+PlaceholderVariations.swift) */
import { AnimatePresence, motion } from "motion/react";
import { useEffect, useRef, useState } from "react";
import { DemoHint, Palette, PlaceholderLines, anim, demoCard, useHaptics, type DemoProps } from "../../kit";
import { primary, useTask } from "./shared";

const W = 264;
const H = 168;

/** A procedural sunset: sky gradient, sun disc, two mountain ridges. */
function sceneColor(u: number, v: number): string {
  const far = 0.58 + 0.08 * Math.sin(u * 9 + 0.5) + 0.04 * Math.sin(u * 23);
  const near = 0.76 + 0.06 * Math.sin(u * 13 + 2) + 0.03 * Math.sin(u * 31);
  const rgb = (r: number, g: number, b: number) => `rgb(${Math.round(r * 255)} ${Math.round(g * 255)} ${Math.round(b * 255)})`;
  if (v > near) return rgb(0.16, 0.11, 0.3);
  if (v > far) return rgb(0.38, 0.26, 0.55);
  const dx = u - 0.68;
  const dy = (v - 0.4) * 0.64;
  const sun = Math.sqrt(dx * dx + dy * dy);
  if (sun < 0.09) return rgb(1, 0.88, 0.55);
  const glow = Math.max(0, 1 - sun / 0.35) * 0.25;
  return rgb(Math.min(1, 0.36 + 0.64 * v + glow), Math.min(1, 0.5 + 0.12 * v + glow * 0.8), Math.min(1, 0.98 - 0.5 * v + glow * 0.2));
}

function Mosaic({ columns }: { columns: number }) {
  const ref = useRef<HTMLCanvasElement>(null);
  useEffect(() => {
    const canvas = ref.current;
    if (!canvas) return;
    const dpr = Math.max(window.devicePixelRatio || 1, 2);
    canvas.width = W * dpr;
    canvas.height = H * dpr;
    const g = canvas.getContext("2d");
    if (!g) return;
    g.setTransform(dpr, 0, 0, dpr, 0, 0);
    const cell = W / columns;
    const rows = Math.ceil(H / cell);
    for (let row = 0; row < rows; row++) {
      for (let column = 0; column < columns; column++) {
        const x = column * cell;
        const y = row * cell;
        g.fillStyle = sceneColor((x + cell / 2) / W, Math.min((y + cell / 2) / H, 1));
        g.fillRect(x, y, cell + 0.5, cell + 0.5);
      }
    }
  }, [columns]);
  return <canvas ref={ref} style={{ width: W, height: H, display: "block", filter: columns >= 96 ? "blur(0.5px)" : undefined }} />;
}

export default function MosaicResolve({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [columns, setColumns] = useState(0);
  const [run, setRun] = useState(0);
  useTask(run, async (task) => {
    const live = !ctx.isPreview && run > 0;
    setColumns(0);
    await task.sleep(0.6);
    const levels: number[] = [];
    let n = Math.max(ctx.i("start"), 1);
    while (n < 64) {
      levels.push(n);
      n *= 2;
    }
    levels.push(96);
    for (const level of levels) {
      setColumns(level);
      if (live) haptics.tap("soft");
      await task.sleep(ctx.n("step"));
    }
    await task.sleep(2.0);
    if (ctx.isPreview) setRun((r) => r + 1);
  });
  const zh = ctx.lang === "zh";
  return (
    <div
      onClick={() => setRun((r) => r + 1)}
      style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 16, cursor: "pointer" }}
    >
      <div style={{ ...demoCard(), padding: 14, display: "flex", flexDirection: "column", gap: 12 }}>
        <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
          <div style={{ width: 30, height: 30, borderRadius: "50%", background: Palette.sunset }} />
          <div style={{ display: "flex", flexDirection: "column", gap: 1 }}>
            <span style={{ fontSize: 15, lineHeight: "20px", fontWeight: 600 }}>{zh ? "林晓" : "Lin Xiao"}</span>
            <span style={{ fontSize: 11, lineHeight: "13px", color: Palette.secondaryLabel }}>{zh ? "大理 · 刚刚" : "Dali · just now"}</span>
          </div>
        </div>
        <div style={{ position: "relative", width: W, height: H, borderRadius: 14, overflow: "hidden", background: primary(0.06) }}>
          <AnimatePresence>
            {columns > 0 && (
              <motion.div
                key={columns}
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                exit={{ opacity: 0, transition: columns === 0 ? anim.easeOut(0.2) : anim.easeInOut(0.25) }}
                transition={anim.easeInOut(0.25)}
                style={{ position: "absolute", inset: 0 }}
              >
                <Mosaic columns={columns} />
              </motion.div>
            )}
          </AnimatePresence>
        </div>
        <PlaceholderLines count={2} />
      </div>
      <DemoHint ctx={ctx} en="Tap to reload" zh="点击重新加载" />
    </div>
  );
}
