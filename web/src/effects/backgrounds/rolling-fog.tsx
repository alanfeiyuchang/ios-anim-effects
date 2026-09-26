/** backgrounds.rolling-fog · 翻涌雾气 (Backgrounds+WeatherVariations.swift) */
import { useRef } from "react";
import { useAutoplay, useHaptics, type DemoProps } from "../../kit";
import { BackgroundClock, BgHint, Layer, SampleTitle, Stage, circle, clampv, ellipse, fract, nowSec, prep, rand, rgba, sizeOf, useFrameLoop, useModel, useRatio } from "./_support";

const smooth = (x: number) => {
  const c = clampv(x, 0, 1);
  return c * c * (3 - 2 * c);
};

class FogModel {
  clock = new BackgroundClock();
  partStart = -100;
  /** 0 = full fog, 1 = parted: ease down 1.2 s, hold 1 s, ease back 3 s. */
  parted(now: number) {
    const e = now - this.partStart;
    if (e < 0) return 0;
    if (e < 1.2) return smooth(e / 1.2);
    if (e < 2.2) return 1;
    if (e < 5.2) return 1 - smooth((e - 2.2) / 3);
    return 0;
  }
  part(now: number) {
    const e = now - this.partStart;
    if (e >= 0 && e < 1.2) return;
    if (e >= 1.2 && e < 2.2) {
      this.partStart = now - 1.2;
      return;
    }
    const current = clampv(this.parted(now), 0, 1);
    this.partStart = now - 1.2 * (0.5 - Math.sin(Math.asin(1 - 2 * current) / 3));
  }
}

const LOOKS = [
  { sky: "linear-gradient(#141A33, #2E3160, #6E6390)", ridges: [0x3b3f63, 0x2a2d4a, 0x171a2e], moon: 0xf5f1e3, fog: 0xe8ecff },
  { sky: "linear-gradient(#3B3D6E, #C98BA0, #F6C9A0)", ridges: [0x7c6a8e, 0x54496e, 0x2e2a48], moon: 0xffe7c2, fog: 0xfff1f0 },
];

function ridge(g: CanvasRenderingContext2D, w: number, h: number, layer: number, color: number) {
  const base = h * (0.52 + 0.14 * layer);
  const amplitude = 26 - 4 * layer;
  const frequency = 1.4 + 0.7 * layer;
  const offset = layer * 1.9;
  g.beginPath();
  g.moveTo(0, h);
  for (let x = 0; x <= w + 8; x += 8) {
    const u = x / Math.max(w, 1);
    const primary = Math.sin(u * frequency * Math.PI * 2 + offset);
    const detail = 0.35 * Math.sin(u * frequency * 5.3 * Math.PI + offset * 2);
    g.lineTo(x, base - amplitude * (primary + detail));
  }
  g.lineTo(w + 8, h);
  g.closePath();
  g.fillStyle = rgba(color);
  g.fill();
}

function fog(g: CanvasRenderingContext2D, w: number, h: number, layer: number, t: number, color: number, density: number) {
  const velocity = 8 + 10 * layer;
  const bandY = h * (0.56 + 0.14 * layer);
  g.fillStyle = rgba(color, density * (0.16 + 0.06 * layer));
  for (let i = 0; i < 6; i++) {
    const seed = layer * 10 + i;
    const width = 150 + 80 * rand(seed, 91);
    const height = 50 + 30 * rand(seed, 92);
    const wrap = w + width * 2;
    const x = fract(rand(seed, 93) + (t * velocity) / wrap) * wrap - width;
    const bob = 6 * Math.sin(t * 0.3 + i * 1.3);
    const y = bandY + bob + (rand(seed, 94) - 0.5) * 30;
    g.beginPath();
    ellipse(g, x, y - height / 2, width, height);
    g.fill();
  }
}

export default function RollingFog({ ctx }: DemoProps) {
  const root = useRef<HTMLDivElement>(null);
  // moon glow · moon + ridge 0 · fog 0 · ridge 1 · fog 1 · ridge 2 · fog 2
  const refs = [useRef<HTMLCanvasElement>(null), useRef<HTMLCanvasElement>(null), useRef<HTMLCanvasElement>(null), useRef<HTMLCanvasElement>(null), useRef<HTMLCanvasElement>(null), useRef<HTMLCanvasElement>(null), useRef<HTMLCanvasElement>(null)];
  const model = useModel(() => new FogModel());
  const haptics = useHaptics();
  const ratio = useRatio(root);
  const look = LOOKS[clampv(ctx.i("palette"), 0, 1)];

  useFrameLoop(root, ctx.isPreview, (now) => {
    const { w, h } = sizeOf(root.current);
    const k = ratio();
    const t = model.clock.advance(now, ctx.n("speed"));
    const parted = model.parted(now);
    const density = ctx.n("density") * (1 - 0.7 * parted);
    const mx = w * 0.72;
    const my = h * 0.24;
    const g0 = prep(refs[0].current, w, h, k);
    if (g0) {
      g0.fillStyle = rgba(look.moon, 0.3 + 0.3 * parted);
      g0.beginPath();
      circle(g0, mx, my, 60);
      g0.fill();
    }
    const g1 = prep(refs[1].current, w, h, k);
    if (g1) {
      g1.fillStyle = rgba(look.moon);
      g1.beginPath();
      circle(g1, mx, my, 20);
      g1.fill();
      ridge(g1, w, h, 0, look.ridges[0]);
    }
    for (let layer = 0; layer < 3; layer++) {
      if (layer > 0) {
        const gr = prep(refs[layer * 2 + 1].current, w, h, k);
        if (gr) ridge(gr, w, h, layer, look.ridges[layer]);
      }
      const gf = prep(refs[layer * 2 + 2].current, w, h, k);
      if (gf) fog(gf, w, h, layer, t, look.fog, density);
    }
  });

  const part = () => model.part(nowSec());
  useAutoplay(ctx.isPreview, part, { every: 6.5, delay: 1.5 });

  return (
    <Stage
      rootRef={root}
      background={look.sky}
      handlers={{
        onClick: () => {
          haptics.tap("soft");
          part();
        },
      }}
    >
      {refs.map((ref, i) => (
        <Layer key={i} canvasRef={ref} blur={i === 0 ? 28 : i % 2 === 0 ? 22 : undefined} />
      ))}
      <SampleTitle title={ctx.t("Mist", "薄雾")} subtitle={ctx.t("Visibility 800 m", "能见度 800 米")} size={34} top={34} />
      <BgHint ctx={ctx} en="Tap to part the fog" zh="点击拨开雾气" />
    </Stage>
  );
}
