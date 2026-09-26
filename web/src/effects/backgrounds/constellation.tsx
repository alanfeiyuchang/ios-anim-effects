/** backgrounds.constellation · 星座连线网络 (Backgrounds+Constellation.swift) */
import { useRef } from "react";
import { Palette, alpha, type DemoProps, type Point } from "../../kit";
import { BackgroundClock, BgHint, Layer, SampleTitle, Stage, TAU, circle, prep, radial, rand, rgba, sizeOf, useBackgroundsTouch, useFrameLoop, useModel, useRatio } from "./_support";

/** One radius for both the hub's pull and its mint links. */
const REACH = 130;

class ConstellationModel {
  clock = new BackgroundClock();
  touch: Point | null = null;
  hub: Point | null = null;
  presence = 0;
  step(now: number, speed: number, simulated: Point | null) {
    const t = this.clock.advance(now, speed);
    const target = this.touch ?? simulated;
    if (target) {
      if (this.hub) {
        const k = this.clock.follow(12);
        this.hub = { x: this.hub.x + (target.x - this.hub.x) * k, y: this.hub.y + (target.y - this.hub.y) * k };
      } else this.hub = target;
      this.presence += (1 - this.presence) * this.clock.follow(6);
    } else {
      this.presence += (0 - this.presence) * this.clock.follow(10);
      if (this.presence < 0.01) this.hub = null;
    }
    return t;
  }
}

export default function Constellation({ ctx }: DemoProps) {
  const root = useRef<HTMLDivElement>(null);
  const canvas = useRef<HTMLCanvasElement>(null);
  const model = useModel(() => new ConstellationModel());
  const ratio = useRatio(root);
  const start = useRef<number | null>(null);

  useFrameLoop(root, ctx.isPreview, (now) => {
    const { w, h } = sizeOf(root.current);
    if (start.current === null) start.current = now;
    const sim = now - start.current + 1;
    const simulated = ctx.isPreview ? { x: w * (0.5 + 0.3 * Math.cos(sim * 0.55)), y: h * (0.56 + 0.2 * Math.sin(sim * 0.9)) } : null;
    const t = model.step(now, ctx.n("speed"), simulated);
    const g = prep(canvas.current, w, h, ratio());
    if (!g) return;
    const count = Math.max(ctx.i("count"), 2);
    const link = Math.max(ctx.n("link"), 1);
    const { hub, presence } = model;
    const pts: Point[] = [];
    for (let i = 0; i < count; i++) {
      const r = (salt: number) => rand(i, salt);
      const dx = 22 * Math.sin(t * (0.18 + 0.25 * r(3)) + r(4) * TAU);
      const dy = 18 * Math.cos(t * (0.15 + 0.22 * r(5)) + r(6) * TAU);
      const p = { x: (0.04 + 0.92 * r(1)) * w + dx, y: (0.34 + 0.62 * r(2)) * h + dy };
      if (hub && presence > 0.001) {
        const ox = hub.x - p.x;
        const oy = hub.y - p.y;
        const d = Math.sqrt(ox * ox + oy * oy);
        if (d < REACH) {
          const pull = 0.35 * (1 - d / REACH) * (1 - d / REACH) * presence;
          p.x += ox * pull;
          p.y += oy * pull;
        }
      }
      pts.push(p);
    }
    // Links in four tiers
    const tiers = [new Path2D(), new Path2D(), new Path2D(), new Path2D()];
    for (let i = 0; i < pts.length; i++) {
      for (let j = i + 1; j < pts.length; j++) {
        const d = Math.hypot(pts[i].x - pts[j].x, pts[i].y - pts[j].y);
        if (d >= link) continue;
        const q = (1 - d / link) * (1 - d / link);
        const tier = Math.min(Math.floor(q * 4), 3);
        tiers[tier].moveTo(pts[i].x, pts[i].y);
        tiers[tier].lineTo(pts[j].x, pts[j].y);
      }
    }
    tiers.forEach((path, tier) => {
      g.strokeStyle = rgba(0x8fa8ff, 0.05 + 0.05 * tier);
      g.lineWidth = 0.5 + 0.3 * tier;
      g.stroke(path);
    });
    // Hub
    if (hub && presence > 0.01) {
      const spokes = new Path2D();
      for (const p of pts) {
        if (Math.hypot(p.x - hub.x, p.y - hub.y) < REACH) {
          spokes.moveTo(hub.x, hub.y);
          spokes.lineTo(p.x, p.y);
        }
      }
      g.strokeStyle = alpha(Palette.mint, 0.55 * presence);
      g.lineWidth = 0.9;
      g.stroke(spokes);
      g.beginPath();
      circle(g, hub.x, hub.y, 46);
      g.fillStyle = radial(g, hub.x, hub.y, 0, 46, [
        [0, alpha(Palette.mint, 0.45 * presence)],
        [1, alpha(Palette.mint, 0)],
      ]);
      g.fill();
      g.beginPath();
      circle(g, hub.x, hub.y, 4);
      g.fillStyle = `rgba(255,255,255,${presence})`;
      g.fill();
    }
    // Nodes
    pts.forEach((p, i) => {
      const radius = 1.2 + 1.4 * rand(i, 7);
      const twinkle = 0.55 + 0.45 * Math.sin(t * (1.2 + rand(i, 8) * 1.6) + i);
      g.fillStyle = `rgba(255,255,255,${0.45 + 0.5 * twinkle})`;
      g.beginPath();
      circle(g, p.x, p.y, radius);
      g.fill();
    });
  });

  const touch = useBackgroundsTouch(
    (p) => (model.touch = p),
    () => (model.touch = null),
  );

  return (
    <Stage rootRef={root} background="linear-gradient(#050816, #0D1233, #1A1446)" handlers={touch}>
      <Layer canvasRef={canvas} />
      <SampleTitle title={ctx.t("Everything, connected", "万物互联")} subtitle={ctx.t("Your team graph · live", "团队关系图 · 实时")} size={26} top={36} />
      <BgHint ctx={ctx} en="Tap or drag sideways to gather nodes" zh="点击或横向拖动以聚拢节点" />
    </Stage>
  );
}
