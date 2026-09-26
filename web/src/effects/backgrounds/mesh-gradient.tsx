/** backgrounds.mesh-gradient · 流动网格渐变 (Backgrounds+MeshGradient.swift) */
import { useEffect, useRef } from "react";
import type { DemoProps, Point } from "../../kit";
import { MeshRenderer, acquire, release } from "./_gl";
import { BackgroundClock, BgHint, SampleTitle, Stage, clampv, rgb01, sizeOf, useBackgroundsTouch, useFrameLoop, useModel, useRatio } from "./_support";

const PALETTES: number[][] = [
  [0x0b1026, 0x1b2a6b, 0x3a1c71, 0x0fb5ae, 0x6e7bff, 0xa46bff, 0x21d4a8, 0x3ac4ff, 0xff5fa2],
  [0xffb36b, 0xff7a5c, 0xff5fa2, 0xffc247, 0xff6b6b, 0xb86bff, 0xff8a5b, 0xd9468f, 0x5b2a86],
  [0x0a2a5e, 0x1d4ed8, 0x0ea5e9, 0x1e3a8a, 0x22d3ee, 0x38bdf8, 0x0f766e, 0x14b8a6, 0x6366f1],
  [0xffd1e8, 0xffb5d8, 0xc9b8ff, 0xffe1c6, 0xff9ac9, 0xa7c7ff, 0xfff1b8, 0xb8f0e0, 0xd8b8ff],
];

class MeshModel {
  clock = new BackgroundClock();
  touch: Point | null = null;
  private cx = 0.5;
  private cy = 0.5;

  points(now: number, speed: number, a: number, w: number, h: number): number[] {
    const t = this.clock.advance(now, speed);
    let tx = 0.5;
    let ty = 0.5;
    if (this.touch && w > 0 && h > 0) {
      tx = clampv(this.touch.x / w, 0.08, 0.92);
      ty = clampv(this.touch.y / h, 0.08, 0.92);
    }
    const k = this.clock.follow(6);
    this.cx += (tx - this.cx) * k;
    this.cy += (ty - this.cy) * k;
    const cx = clampv(this.cx + a * 0.8 * Math.sin(t * 1.13), 0.12, 0.88);
    const cy = clampv(this.cy + a * 0.8 * Math.cos(t * 0.87), 0.12, 0.88);
    return [
      0, 0, 0.5 + a * Math.sin(t * 0.91), 0, 1, 0,
      0, 0.5 + a * Math.cos(t * 0.73 + 1.2), cx, cy, 1, 0.5 + a * Math.sin(t * 0.79 + 2.4),
      0, 1, 0.5 + a * Math.cos(t * 1.07 + 0.6), 1, 1, 1,
    ];
  }
}

export default function MeshGradient({ ctx }: DemoProps) {
  const root = useRef<HTMLDivElement>(null);
  const canvas = useRef<HTMLCanvasElement>(null);
  const renderer = useRef<MeshRenderer | null>(null);
  const model = useModel(() => new MeshModel());
  const ratio = useRatio(root);

  useEffect(() => {
    const el = canvas.current;
    if (!el) return;
    const r = acquire(el, () => new MeshRenderer(el));
    renderer.current = r;
    return () => {
      release(el, r);
      renderer.current = null;
    };
  }, []);

  useFrameLoop(root, ctx.isPreview, (now) => {
    const { w, h } = sizeOf(root.current);
    const pts = model.points(now, ctx.n("speed"), ctx.n("amplitude"), w, h);
    const palette = PALETTES[clampv(ctx.i("palette"), 0, 3)];
    renderer.current?.draw(w, h, Math.min(ratio(), 2), 3, 3, pts, palette.flatMap(rgb01));
  });

  const touch = useBackgroundsTouch(
    (p) => (model.touch = p),
    () => (model.touch = null),
  );

  return (
    <Stage rootRef={root} handlers={touch}>
      <canvas ref={canvas} style={{ position: "absolute", inset: 0, width: "100%", height: "100%", display: "block" }} />
      <SampleTitle
        title={ctx.t("Good evening", "晚上好")}
        subtitle={ctx.t("Your day, beautifully in motion", "让每一天都优雅流动")}
        color={ctx.i("palette") === 3 ? "rgb(0 0 0 / 0.72)" : "#fff"}
      />
      <BgHint ctx={ctx} en="Tap or drag sideways to pull the gradient" zh="点击或横向拖动以牵引渐变" />
    </Stage>
  );
}
