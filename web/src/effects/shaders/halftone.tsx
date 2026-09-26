/** shader.halftone · CMYK 半色调 (Shaders+Stylize.swift, mlHalftoneCMYK) */
import { animate, useMotionValue } from "motion/react";
import { useRef } from "react";
import { Palette, clamp, spring, type DemoProps, type Point } from "../../kit";
import { LIB, nowSec, useLayer, useSpeedClock, useStageTouch } from "./_shared";
import { CenterStack } from "./_stage";
import { Shader } from "./_gl";

const W = 270;
const H = 300;

const FRAG = `
uniform float u_cell;
uniform float u_angle;
uniform float u_gain;
${LIB}
void main() {
  vec2 position = v_uv * u_size;
  vec4 here = S(position);
  if (here.a < 0.01) { gl_FragColor = vec4(0.0); return; }
  float s = max(u_cell, 3.0);
  vec3 result = vec3(0.99, 0.97, 0.93);
  for (int k = 0; k < 4; k++) {
    float theta = u_angle + (k == 0 ? 0.2618 : (k == 1 ? 1.3090 : (k == 2 ? 0.0 : 0.7854)));
    float cs = cos(theta);
    float sn = sin(theta);
    vec2 rp = vec2(cs * position.x + sn * position.y, -sn * position.x + cs * position.y);
    vec2 rc = (floor(rp / s) + 0.5) * s;
    vec2 center = vec2(cs * rc.x - sn * rc.y, sn * rc.x + cs * rc.y);
    vec4 c = S(center);
    vec3 rgb = c.a > 0.001 ? c.rgb / c.a : vec3(1.0);
    float black = 1.0 - max(rgb.r, max(rgb.g, rgb.b));
    float denom = max(1.0 - black, 0.001);
    float amount = k == 0 ? (1.0 - rgb.r - black) / denom
                 : (k == 1 ? (1.0 - rgb.g - black) / denom
                 : (k == 2 ? (1.0 - rgb.b - black) / denom : black));
    amount = clamp(amount * u_gain, 0.0, 1.0);
    float radius = s * 0.7071 * sqrt(amount);
    float d = length(rp - rc);
    float coverage = 1.0 - smoothstep(radius - 0.6, radius + 0.6, d);
    vec3 ink = k == 0 ? vec3(0.0, 0.66, 0.93)
             : (k == 1 ? vec3(0.92, 0.05, 0.55)
             : (k == 2 ? vec3(1.0, 0.92, 0.05) : vec3(0.12, 0.12, 0.15)));
    result *= mix(vec3(1.0), ink, coverage * 0.94);
  }
  gl_FragColor = vec4(result, 1.0) * here.a;
}`;

function hill(g: CanvasRenderingContext2D, base: number, amplitude: number, frequency: number, phase: number, color: string) {
  g.beginPath();
  g.moveTo(0, H);
  for (let x = 0; x <= W + 6; x += 6) g.lineTo(x, H * base + amplitude * Math.sin((x / W) * frequency * 2 * Math.PI + phase));
  g.lineTo(W, H);
  g.closePath();
  g.fillStyle = color;
  g.fill();
}

/** `HalftonePoster`: warm sky, a drifting sun (or the finger's, blended by `hold`) and two scrolling hills. */
function drawPoster(g: CanvasRenderingContext2D, time: number, target: Point, hold: number) {
  const sky = g.createLinearGradient(0, 0, 0, H * 0.75);
  sky.addColorStop(0, "#3A2E8C");
  sky.addColorStop(0.5, Palette.pink);
  sky.addColorStop(1, Palette.amber);
  g.fillStyle = sky;
  g.fillRect(0, 0, W, H);
  const drift = { x: 0.5 + 0.18 * Math.cos(time * 0.4), y: 0.42 + 0.06 * Math.sin(time * 0.5) };
  const sun = { x: W * (drift.x + (target.x - drift.x) * hold), y: H * (drift.y + (target.y - drift.y) * hold) };
  g.fillStyle = "#FFE27A";
  g.beginPath();
  g.arc(sun.x, sun.y, 56, 0, Math.PI * 2);
  g.fill();
  hill(g, 0.66, 22, 1.6, time * 0.35, "#E2365B");
  hill(g, 0.8, 16, 2.3, -time * 0.5, "#14365A");
}

export default function Halftone({ ctx }: DemoProps) {
  const layer = useLayer(W, H);
  const clock = useSpeedClock();
  const sunTarget = useRef<Point>({ x: 0.5, y: 0.42 });
  /** 0 = free drift, 1 = held by the finger. */
  const hold = useMotionValue(0);
  const holdTarget = useRef(0);
  const touch = useStageTouch(
    (p) => {
      sunTarget.current = { x: clamp(p.x / W, 0, 1), y: clamp(p.y / H, 0, 1) };
      if (holdTarget.current !== 1) {
        holdTarget.current = 1;
        animate(hold, 1, spring(0.35, 0.8));
      }
    },
    () => {
      holdTarget.current = 0;
      animate(hold, 0, spring(0.9, 0.75));
    },
  );

  return (
    <CenterStack ctx={ctx} en="Drag the sun across the poster" zh="拖动太阳划过海报" gap={12}>
      <div {...touch} style={{ width: W, height: H, borderRadius: 30, boxShadow: "0 10px 18px rgb(0 0 0 / 0.18)", flexShrink: 0, ...touch.style }}>
        <div style={{ width: W, height: H, borderRadius: 30, overflow: "hidden", transform: "translateZ(0)" }}>
          <Shader
            width={W}
            height={H}
            fragment={FRAG}
            source={layer.canvas}
            fps={ctx.isPreview ? 30 : undefined}
            uniforms={() => {
              const time = clock.advance(nowSec(), 1);
              layer.paint((g) => drawPoster(g, time, sunTarget.current, hold.get()));
              return { u_cell: ctx.n("cell"), u_angle: (ctx.n("angle") * Math.PI) / 180, u_gain: ctx.n("gain") };
            }}
          />
        </div>
      </div>
    </CenterStack>
  );
}
