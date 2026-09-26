/** shader.voronoi-cells · 活体细胞 (Shaders+CellsTunnel.swift, mlVoronoiCells) */
import { useRef } from "react";
import { localPoint, useAutoplay, useHaptics, type DemoProps } from "../../kit";
import { LIB, nowSec, randIn, useSpeedClock } from "./_shared";
import { BottomHint } from "./_stage";
import { Shader } from "./_gl";

const FRAG = `
uniform float u_t;
uniform float u_density;
uniform vec2 u_touch;
uniform float u_pulse;
uniform float u_glow;
${LIB}
void main() {
  vec2 position = v_uv * u_size;
  vec2 size = u_size;
  vec2 fromTouch = position - u_touch;
  float dist = length(fromTouch);
  float split = 0.0;
  if (u_pulse >= 0.0) {
    float envelope = smoothstep(0.0, 0.35, u_pulse) * exp(-max(u_pulse - 0.6, 0.0) * 1.4);
    envelope *= 1.0 - smoothstep(2.6, 3.0, u_pulse);
    float x = dist / 110.0;
    split = envelope * exp(-x * x);
  }
  vec2 local = u_touch + fromTouch * (1.0 + split);
  vec2 uv = local / max(size.y, 1.0) * u_density;
  vec2 g = floor(uv);
  vec2 f = fract(uv);
  float d1 = 8.0;
  float d2 = 8.0;
  vec2 best = g;
  for (int j = -1; j <= 1; j++) {
    for (int i = -1; i <= 1; i++) {
      vec2 o = vec2(float(i), float(j));
      vec2 h = vec2(mlHash(g + o), mlHash(g + o + 17.31));
      vec2 pt = o + 0.5 + 0.38 * sin(u_t * (0.6 + h * 0.9) + 6.2831853 * h);
      float d = length(pt - f);
      if (d < d1) {
        d2 = d1;
        d1 = d;
        best = g + o;
      } else if (d < d2) {
        d2 = d;
      }
    }
  }
  float edge = d2 - d1;
  float tone = mlHash(best * 1.37 + 3.1);
  vec3 base = mix(vec3(0.10, 0.08, 0.28), vec3(0.20, 0.55, 0.95), tone);
  base = mix(base, vec3(1.0, 0.45, 0.65), smoothstep(0.72, 1.0, tone));
  float border = exp(-edge * 18.0) * u_glow;
  float core = (1.0 - smoothstep(0.0, 0.5, d1)) * 0.35;
  vec3 col = base * (0.55 + core);
  col += vec3(0.55, 0.85, 1.0) * border * (0.55 + split * 1.6);
  col += base * split * 0.5;
  col = clamp(col, vec3(0.0), vec3(1.0));
  gl_FragColor = vec4(col, 1.0);
}`;

export default function VoronoiCells({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const H = ctx.isPreview ? 340 : 400;
  const clock = useSpeedClock();
  const pulse = useRef({ touch: { x: 170, y: 170 }, start: -100 });

  const emit = (x: number, y: number) => {
    pulse.current = { touch: { x, y }, start: nowSec() };
  };
  useAutoplay(ctx.isPreview, () => emit(randIn(0.25, 0.75) * 340, randIn(0.25, 0.75) * H), { every: 2.6, delay: 0.5 });

  return (
    <div
      onClick={(e) => {
        const p = localPoint(e, e.currentTarget);
        haptics.tap("soft");
        emit(p.x, p.y);
      }}
      style={{ position: "absolute", inset: 0, cursor: "pointer" }}
    >
      <Shader
        width={340}
        height={H}
        fragment={FRAG}
        fps={ctx.isPreview ? 30 : undefined}
        uniforms={() => {
          const { touch, start } = pulse.current;
          const age = nowSec() - start;
          return {
            u_t: clock.advance(nowSec(), ctx.n("speed")),
            u_density: ctx.n("density"),
            u_touch: [touch.x, touch.y],
            u_pulse: age >= 0 && age < 3 ? age : -1,
            u_glow: ctx.n("glow"),
          };
        }}
      />
      <BottomHint ctx={ctx} en="Tap to make the cells divide" zh="点击让细胞分裂" bottom={14} dark />
    </div>
  );
}
