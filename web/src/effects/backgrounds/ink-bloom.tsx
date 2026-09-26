/** backgrounds.ink-bloom · 水墨晕染 (Backgrounds+LiquidVariations.swift) */
import { useRef } from "react";
import { useAutoplay, useHaptics, type DemoProps, type Point } from "../../kit";
import { BackgroundClock, BgHint, Layer, SampleTitle, Stage, TAU, circle, prep, rand, randIn, rgba, sizeOf, useFrameLoop, useModel, useRatio, useTap } from "./_support";

interface InkDrop {
  /** Unit coordinates (0…1) inside the stage. */
  cx: number;
  cy: number;
  born: number;
  color: number;
  seed: number;
}

class InkModel {
  clock = new BackgroundClock(100);
  /** Two drops already ~1.5 s into their bloom, so the first frame shows ink on the paper. */
  drops: InkDrop[] = [
    { cx: 0.34, cy: 0.5, born: 98.4, color: 1, seed: 10 },
    { cx: 0.66, cy: 0.62, born: 98.9, color: 2, seed: 17 },
  ];
  private serial = 2;
  step(now: number, speed: number, life: number) {
    const t = this.clock.advance(now, speed);
    this.drops = this.drops.filter((d) => t - d.born <= life);
    return t;
  }
  drop(u: Point) {
    this.serial += 1;
    this.drops.push({ cx: u.x, cy: u.y, born: this.clock.phase, color: this.serial % 4, seed: this.serial * 7 + 3 });
    if (this.drops.length > 10) this.drops.splice(0, this.drops.length - 10);
  }
}

const DARK = [0x6e7bff, 0xff5fa2, 0x21d4a8, 0xffc247];
const LIGHT = [0x2b2fa8, 0xc2186b, 0x0e8a87, 0xd9822b];

function drawDrop(g: CanvasRenderingContext2D, d: InkDrop, color: number, w: number, h: number, t: number, spread: number, life: number) {
  const age = t - d.born;
  if (age < 0) return;
  const fade = Math.max(0, 1 - age / Math.max(life, 0.1));
  const alpha = Math.min(age * 6, 1) * fade * fade;
  if (alpha <= 0.002) return;
  const gr = 1 - Math.exp(-age / 0.9);
  const side = Math.min(w, h);
  const ox = d.cx * w;
  const oy = d.cy * h;
  g.fillStyle = rgba(color, alpha * 0.55);
  for (let k = 0; k < 7; k++) {
    const direction = rand(d.seed, k) * TAU;
    const reach = side * (0.05 + 0.13 * rand(d.seed, k + 10)) * spread;
    const sink = side * 0.09 * rand(d.seed, k + 20);
    const cx = ox + Math.cos(direction) * reach * gr;
    const cy = oy + Math.sin(direction) * reach * gr + sink * gr * gr;
    const radius = side * (0.03 + 0.07 * rand(d.seed, k + 30)) * spread * (0.25 + gr);
    g.beginPath();
    circle(g, cx, cy, radius);
    g.fill();
  }
  const coreRadius = side * 0.035 * (1 + 1.4 * gr) * spread;
  g.fillStyle = rgba(color, alpha * 0.8 * (1 - 0.6 * gr));
  g.beginPath();
  circle(g, ox, oy, coreRadius);
  g.fill();
  const ringRadius = 10 + gr * side * 0.3;
  g.strokeStyle = rgba(color, 0.3 * (1 - gr) * fade);
  g.lineWidth = 1.5;
  g.beginPath();
  circle(g, ox, oy, ringRadius);
  g.stroke();
}

export default function InkBloom({ ctx }: DemoProps) {
  const root = useRef<HTMLDivElement>(null);
  const canvas = useRef<HTMLCanvasElement>(null);
  const model = useModel(() => new InkModel());
  const haptics = useHaptics();
  const ratio = useRatio(root);
  const dark = ctx.scheme === "dark";

  useFrameLoop(root, ctx.isPreview, (now) => {
    const { w, h } = sizeOf(root.current);
    const life = ctx.n("life");
    const t = model.step(now, ctx.n("speed"), life);
    const g = prep(canvas.current, w, h, ratio());
    if (!g) return;
    g.globalCompositeOperation = dark ? "screen" : "multiply";
    const colors = dark ? DARK : LIGHT;
    for (const d of model.drops) drawDrop(g, d, colors[d.color % colors.length], w, h, t, ctx.n("spread"), life);
  });

  const tap = useTap((p) => {
    haptics.tap("soft");
    const { w, h } = sizeOf(root.current);
    model.drop({ x: p.x / Math.max(w, 1), y: p.y / Math.max(h, 1) });
  });

  useAutoplay(ctx.isPreview, () => model.drop({ x: randIn(0.18, 0.82), y: randIn(0.3, 0.75) }), { every: 1.6, delay: 0.4 });

  return (
    <Stage rootRef={root} background={dark ? "#0C0E14" : "#F3EFE6"} handlers={tap}>
      <Layer canvasRef={canvas} blur={10} />
      <SampleTitle
        title={ctx.t("Ink & Water", "水 · 墨")}
        subtitle={ctx.t("A quiet place to think", "一处安静思考的地方")}
        color={dark ? "#fff" : "rgb(0 0 0 / 0.72)"}
        size={28}
        top={34}
      />
      <BgHint ctx={ctx} en="Tap to drop ink" zh="点击滴入墨滴" light={!dark} />
    </Stage>
  );
}
