/** backgrounds.window-droplets · 窗上雨滴 (Backgrounds+WeatherVariations.swift) */
import { useRef } from "react";
import { useAutoplay, useHaptics, type DemoProps, type Point } from "../../kit";
import { BackgroundClock, BgHint, Layer, SampleTitle, Stage, circle, ellipse, fract, prep, rand, randIn, rgba, sizeOf, useFrameLoop, useModel, useRatio, useTap } from "./_support";

interface Falling {
  x: number;
  y: number;
  born: number;
}

class GlassModel {
  clock = new BackgroundClock();
  drops: Falling[] = [];
  step(now: number) {
    const t = this.clock.advance(now, 1);
    this.drops = this.drops.filter((d) => t - d.born <= 2.5);
    return t;
  }
  knock(p: Point) {
    this.drops.push({ x: p.x, y: p.y, born: this.clock.phase });
    if (this.drops.length > 8) this.drops.splice(0, this.drops.length - 8);
  }
}

const CITY = [0xffb86b, 0xff8fa3, 0xffe0a3, 0x9fd4ff, 0xffd27a];

interface Paths {
  shadows: Path2D;
  bodies: Path2D;
  lights: Path2D;
}

function addDrop(p: Paths, cx: number, cy: number, radius: number) {
  const bx = cx - radius;
  const by = cy - radius * 1.1;
  ellipse(p.shadows, bx, by + radius * 0.35, radius * 2, radius * 2.2);
  ellipse(p.bodies, bx, by, radius * 2, radius * 2.2);
  const hl = Math.max(radius * 0.32, 0.5);
  circle(p.lights, cx - radius * 0.45, cy - radius * 0.55, hl);
}

function runnerPoint(index: number, y: number, width: number): Point {
  const meander = 5 * Math.sin(y * 0.045 + rand(index, 57) * 6);
  return { x: rand(index, 55) * width + meander, y };
}

export default function WindowDroplets({ ctx }: DemoProps) {
  const root = useRef<HTMLDivElement>(null);
  const city = useRef<HTMLCanvasElement>(null);
  const glass = useRef<HTMLCanvasElement>(null);
  const model = useModel(() => new GlassModel());
  const haptics = useHaptics();
  const ratio = useRatio(root);
  const drawn = useRef("");

  useFrameLoop(root, ctx.isPreview, (now) => {
    const { w, h } = sizeOf(root.current);
    const k = ratio();
    const key = `${w}x${h}@${k}`;
    if (drawn.current !== key) {
      drawn.current = key;
      const gc = prep(city.current, w, h, k);
      if (gc) {
        for (let i = 0; i < 11; i++) {
          const r = Math.min(w, h) * (0.06 + 0.07 * rand(i, 81));
          gc.fillStyle = rgba(CITY[i % CITY.length], 0.45);
          gc.beginPath();
          circle(gc, rand(i, 82) * w, h * (0.25 + 0.7 * rand(i, 83)), r);
          gc.fill();
        }
      }
    }
    if (city.current) city.current.style.filter = `blur(${ctx.n("blur")}px)`;
    const t = model.step(now);
    const g = prep(glass.current, w, h, k);
    if (!g) return;
    g.fillStyle = "rgba(255,255,255,0.04)";
    g.fillRect(0, 0, w, h);
    const p: Paths = { shadows: new Path2D(), bodies: new Path2D(), lights: new Path2D() };
    const beads = Math.max(ctx.i("beads"), 0);
    for (let i = 0; i < beads; i++) {
      const kk = rand(i, 86);
      addDrop(p, rand(i, 84) * w, rand(i, 85) * h, 0.8 + 2.6 * kk * kk);
    }
    const span = h + 60;
    const runners = Math.max(ctx.i("runners"), 0);
    for (let i = 0; i < runners; i++) {
      const rate = 0.35 + 0.4 * rand(i, 51);
      const cycle = t * rate + rand(i, 52) * 10;
      const whole = Math.floor(cycle);
      const s = Math.min((cycle - whole) / 0.3, 1);
      const eased = s * s * (3 - 2 * s);
      const slipLength = 14 + 10 * rand(i, 53);
      const travel = (whole + eased) * slipLength;
      const y = fract((rand(i, 54) * span + travel) / span) * span - 30;
      const radius = 4.5 + 3 * rand(i, 56);
      const head = runnerPoint(i, y, w);
      addDrop(p, head.x, head.y, radius);
      for (let q = 1; q <= 5; q++) {
        const pt = runnerPoint(i, y - q * 8, w);
        circle(p.bodies, pt.x, pt.y, radius * 0.35 * (1 - q * 0.15));
      }
    }
    for (const d of model.drops) {
      const age = t - d.born;
      addDrop(p, d.x + 3 * Math.sin(age * 9), d.y + 0.5 * 420 * age * age, 6.5);
    }
    g.fillStyle = "rgba(0,0,0,0.28)";
    g.fill(p.shadows);
    g.fillStyle = "rgba(255,255,255,0.14)";
    g.fill(p.bodies);
    g.fillStyle = "rgba(255,255,255,0.75)";
    g.fill(p.lights);
  });

  const tap = useTap((pt) => {
    haptics.tap("light");
    model.knock(pt);
  });

  useAutoplay(
    ctx.isPreview,
    () => {
      const { w } = sizeOf(root.current);
      model.knock({ x: randIn(30, Math.max(w - 30, 31)), y: randIn(20, 90) });
    },
    { every: 1.4, delay: 0.5 },
  );

  return (
    <Stage rootRef={root} background="linear-gradient(#1F2B4D, #5B4C7A, #C97B6E, #F2B27E)" handlers={tap}>
      <Layer canvasRef={city} />
      <Layer canvasRef={glass} />
      <SampleTitle title={ctx.t("Evening showers", "傍晚阵雨")} subtitle={ctx.t("Clearing after 8 PM", "20 点后转晴")} size={26} />
      <BgHint ctx={ctx} en="Tap the glass to knock a drop loose" zh="点击玻璃震落水滴" />
    </Stage>
  );
}
