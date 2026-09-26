/** backgrounds.grain-gradient · 颗粒质感渐变 (Backgrounds+GrainGradient.swift, mlGrainGradient in Shaders.metal) */
import { useEffect, useRef } from "react";
import type { DemoProps, Point } from "../../kit";
import { QuadRenderer, acquire, release } from "./_gl";
import { BackgroundClock, BgHint, SampleTitle, Stage, clampv, rgb01, sizeOf, useBackgroundsTouch, useFrameLoop, useModel, useRatio } from "./_support";

const PALETTES = [
  [0x1b1036, 0xff5fa2, 0x6e7bff, 0xffb36b],
  [0xff7a45, 0xffc247, 0xff4d7a, 0xffe7c2],
  [0x03182b, 0x21d4a8, 0x3ac4ff, 0xa46bff],
];

class GrainModel {
  clock = new BackgroundClock();
  /** Touch in unit coordinates, null when idle. */
  touch: Point | null = null;
  focus = { x: 0.5, y: 0.5 };
  time = 100;
  step(now: number, speed: number) {
    const t = this.clock.advance(now, speed);
    const orbit = { x: 0.5 + 0.28 * Math.cos(t * 0.37), y: 0.55 + 0.22 * Math.sin(t * 0.53) };
    const target = this.touch ?? orbit;
    const k = this.clock.follow(this.touch ? 6 : 1.4);
    this.focus.x += (target.x - this.focus.x) * k;
    this.focus.y += (target.y - this.focus.y) * k;
    this.time = t;
  }
}

const FRAGMENT = `
uniform float u_t;
uniform float u_grain;
uniform vec3 u_c0;
uniform vec3 u_c1;
uniform vec3 u_c2;
uniform vec3 u_c3;
uniform vec2 u_focus;
uniform float u_pixelScale;

float mlHash(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
float mlNoise(vec2 p) {
  vec2 i = floor(p);
  vec2 f = fract(p);
  float a = mlHash(i);
  float b = mlHash(i + vec2(1.0, 0.0));
  float c = mlHash(i + vec2(0.0, 1.0));
  float d = mlHash(i + vec2(1.0, 1.0));
  vec2 u = f * f * (3.0 - 2.0 * f);
  return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}
float mlFbm(vec2 p) {
  float value = 0.0;
  float amplitude = 0.5;
  for (int k = 0; k < 4; k++) {
    value += amplitude * mlNoise(p);
    p *= 2.0;
    amplitude *= 0.5;
  }
  return value;
}
void main() {
  vec2 position = v_uv * u_size;
  vec2 uv = v_uv;
  vec2 aspect = vec2(u_size.x / max(u_size.y, 1.0), 1.0);
  vec2 warp = vec2(mlFbm(uv * 2.2 + vec2(u_t * 0.07, 0.0)), mlFbm(uv * 2.2 + vec2(5.2, u_t * 0.06)));
  vec2 q = uv + 0.14 * (warp - 0.5);
  vec2 p1 = vec2(0.78 + 0.14 * cos(u_t * 0.23), 0.28 + 0.16 * sin(u_t * 0.35));
  vec2 p2 = vec2(0.28 + 0.18 * cos(u_t * 0.19 + 1.7), 0.78 + 0.12 * sin(u_t * 0.29));
  vec2 d1 = (q - p1) * aspect;
  vec2 d2 = (q - p2) * aspect;
  vec2 d3 = (q - u_focus) * aspect;
  float w1 = exp(-dot(d1, d1) * 4.5);
  float w2 = exp(-dot(d2, d2) * 4.0);
  float w3 = exp(-dot(d3, d3) * 7.0);
  vec3 col = u_c0;
  col = mix(col, u_c1, w1);
  col = mix(col, u_c2, w2);
  col = mix(col, u_c3, w3);
  float n = mlHash(floor(position * max(u_pixelScale, 1.0))) - 0.5;
  col += n * u_grain * 0.16;
  gl_FragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}`;

export default function GrainGradient({ ctx }: DemoProps) {
  const root = useRef<HTMLDivElement>(null);
  const model = useModel(() => new GrainModel());
  const size = useRef({ w: 340, h: ctx.isPreview ? 340 : 400 });
  const canvas = useRef<HTMLCanvasElement>(null);
  const renderer = useRef<QuadRenderer | null>(null);
  const ratio = useRatio(root);

  useEffect(() => {
    const el = canvas.current;
    if (!el) return;
    const r = acquire(el, () => new QuadRenderer(el, FRAGMENT));
    renderer.current = r;
    return () => {
      release(el, r);
      renderer.current = null;
    };
  }, []);

  useFrameLoop(root, ctx.isPreview, (now) => {
    const { w, h } = sizeOf(root.current);
    size.current = { w, h };
    model.step(now, ctx.n("speed"));
    const palette = PALETTES[clampv(ctx.i("palette"), 0, 2)].map(rgb01);
    const k = Math.min(ratio(), 2);
    renderer.current?.draw(w, h, k, {
      u_t: model.time,
      u_grain: ctx.n("grain"),
      u_c0: palette[0],
      u_c1: palette[1],
      u_c2: palette[2],
      u_c3: palette[3],
      u_focus: [model.focus.x, model.focus.y],
      // One grain value per canvas pixel (the app hashes per device pixel via displayScale).
      u_pixelScale: k,
    });
  });

  const touch = useBackgroundsTouch(
    (p) => {
      const { w, h } = size.current;
      model.touch = { x: clampv(p.x / Math.max(w, 1), 0, 1), y: clampv(p.y / Math.max(h, 1), 0, 1) };
    },
    () => (model.touch = null),
  );

  return (
    <Stage rootRef={root} handlers={touch}>
      <canvas ref={canvas} style={{ position: "absolute", inset: 0, width: "100%", height: "100%", display: "block" }} />
      <SampleTitle title={ctx.t("Made to feel", "为感受而生")} subtitle={ctx.t("Spring collection · 2026", "春季系列 · 2026")} size={28} />
      <BgHint ctx={ctx} en="Tap or drag sideways to steer the glow" zh="点击或横向拖动以引导光晕" />
    </Stage>
  );
}
