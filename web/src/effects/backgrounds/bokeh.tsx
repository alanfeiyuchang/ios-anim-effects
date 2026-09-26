/** backgrounds.bokeh · 散景光斑 (Backgrounds+Bokeh.swift) */
import { PartyPopper } from "lucide-react";
import { useRef } from "react";
import { Palette, fonts, glass, type DemoProps } from "../../kit";
import { BackgroundClock, BgHint, Layer, Stage, circle, clampv, fract, prep, rand, rgba, sizeOf, useBackgroundsTouch, useFrameLoop, useModel, useRatio } from "./_support";

const PALETTES = [
  [0xffc247, 0xff7a5c, 0xff5fa2, 0xffe0a3],
  [0x3ac4ff, 0x6e7bff, 0x21d4a8, 0xa46bff],
  [0xff3cac, 0x2bd9fe, 0xa46bff, 0xffe45e],
];

/** Focal plane in depth units (0 far … 2 near), eased toward the finger's horizontal position. */
class Focus {
  touchX: number | null = null;
  width = 340;
  private plane = 2;
  step(k: number) {
    const target = this.touchX === null ? 2 : 2 * clampv(this.touchX / Math.max(this.width, 1), 0, 1);
    this.plane += (target - this.plane) * k;
    return this.plane;
  }
}

function drawDisc(g: CanvasRenderingContext2D, i: number, depth: number, w: number, h: number, t: number, palette: number[]) {
  const side = Math.min(w, h);
  const radius = side * [0.035, 0.065, 0.11][depth] * (0.7 + 0.6 * rand(i, 1));
  const rise = [0.035, 0.05, 0.08][depth] * (0.8 + 0.4 * rand(i, 2));
  const span = h + radius * 2;
  const y = h + radius - fract(rand(i, 3) + t * rise) * span;
  const x = rand(i, 4) * w + 14 * Math.sin(t * (0.25 + 0.2 * rand(i, 5)) + i);
  const pulse = 0.65 + 0.35 * Math.sin(t * (0.9 + 0.6 * rand(i, 6)) + i * 1.7);
  const strength = [0.45, 0.7, 1.0][depth] * pulse;
  const color = palette[i % palette.length];
  const gr = g.createRadialGradient(x, y, 0, x, y, radius);
  gr.addColorStop(0, rgba(color, 0.12 * strength));
  gr.addColorStop(0.8, rgba(color, 0.3 * strength));
  gr.addColorStop(0.94, rgba(color, 0.62 * strength));
  gr.addColorStop(1, rgba(color, 0));
  g.fillStyle = gr;
  g.beginPath();
  circle(g, x, y, radius);
  g.fill();
}

export default function Bokeh({ ctx }: DemoProps) {
  const root = useRef<HTMLDivElement>(null);
  const layers = [useRef<HTMLCanvasElement>(null), useRef<HTMLCanvasElement>(null), useRef<HTMLCanvasElement>(null)];
  const clock = useModel(() => new BackgroundClock());
  const focus = useModel(() => new Focus());
  const ratio = useRatio(root);

  useFrameLoop(root, ctx.isPreview, (now) => {
    const { w, h } = sizeOf(root.current);
    focus.width = w;
    const k = ratio();
    const t = clock.advance(now, ctx.n("speed"));
    const plane = focus.step(clock.follow(7));
    const count = Math.max(ctx.i("count"), 0);
    const palette = PALETTES[clampv(ctx.i("palette"), 0, 2)];
    const blur = ctx.n("blur");
    for (let depth = 0; depth < 3; depth++) {
      const canvas = layers[depth].current;
      const g = prep(canvas, w, h, k);
      if (!g || !canvas) continue;
      // 0.5× at the focal plane, +0.65× per plane away.
      const layerBlur = blur * (0.5 + 0.65 * Math.abs(depth - plane));
      canvas.style.filter = layerBlur > 0.1 ? `blur(${layerBlur.toFixed(2)}px)` : "";
      g.globalCompositeOperation = "lighter";
      for (let i = depth; i < count; i += 3) drawDisc(g, i, depth, w, h, t, palette);
    }
  });

  const touch = useBackgroundsTouch(
    (p) => (focus.touchX = p.x),
    () => (focus.touchX = null),
  );

  return (
    <Stage rootRef={root} background="linear-gradient(#120A1C, #2A1330, #1A0B16)" handlers={touch}>
      {layers.map((ref, i) => (
        <Layer key={i} canvasRef={ref} />
      ))}
      <div style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center", pointerEvents: "none" }}>
        <div
          style={{
            width: 250,
            padding: 14,
            display: "flex",
            alignItems: "center",
            gap: 12,
            borderRadius: 20,
            ...glass("ultraThin", "dark"),
            boxShadow: "inset 0 0 0 1px rgb(255 255 255 / 0.15)",
          }}
        >
          <div
            style={{ width: 44, height: 44, flexShrink: 0, borderRadius: 12, background: "rgb(255 255 255 / 0.12)", display: "grid", placeItems: "center", color: Palette.amber }}
          >
            <PartyPopper size={24} strokeWidth={2} />
          </div>
          <div style={{ display: "flex", flexDirection: "column", gap: 3, minWidth: 0 }}>
            <div style={{ fontFamily: fonts.text, fontSize: 17, lineHeight: "22px", fontWeight: 600, color: "#fff" }}>{ctx.t("Friday Night", "周五夜聚")}</div>
            <div style={{ fontFamily: fonts.text, fontSize: 15, lineHeight: "20px", color: "rgb(235 235 245 / 0.6)", whiteSpace: "nowrap" }}>
              {ctx.t("8 guests · Rooftop bar", "8 位来宾 · 天台酒吧")}
            </div>
          </div>
        </div>
      </div>
      <BgHint ctx={ctx} en="Drag sideways to rack focus" zh="左右拖动移焦" />
    </Stage>
  );
}
