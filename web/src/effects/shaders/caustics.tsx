/** shader.caustics · 泳池焦散 (Shaders+Light.swift, mlCaustics) */
import { useRef } from "react";
import { localPoint, useAutoplay, useHaptics, type DemoProps } from "../../kit";
import { LIB, nowSec, randIn, useLayer, useSpeedClock } from "./_shared";
import { CenterStack } from "./_stage";
import { Shader } from "./_gl";

const W = 300;
const H = 320;

const FRAG = `
uniform float u_t;
uniform float u_intensity;
uniform float u_refraction;
uniform vec2 u_origin;
uniform float u_age;
${LIB}
float mlWaterHeight(vec2 p, float t, vec2 origin, float age) {
  float h = sin(p.x * 0.045 + t * 1.3) * 0.5
          + sin(p.y * 0.052 - t * 1.1) * 0.5
          + sin((p.x + p.y) * 0.031 + t * 0.9) * 0.6
          + (mlNoise(p * 0.03 + vec2(t * 0.35, -t * 0.2)) - 0.5) * 1.2;
  if (age >= 0.0 && age < 3.0) {
    float dist = length(p - origin);
    float front = age * 240.0;
    float envelope = exp(-abs(dist - front) / 34.0) * exp(-age * 1.6);
    h += sin((dist - front) * 0.11) * 3.2 * envelope;
  }
  return h;
}
float mlCausticNetwork(vec2 uv, float time) {
  vec2 p = uv * 6.2831853 - 250.0;
  vec2 i = p;
  float c = 1.0;
  float inten = 0.005;
  for (int n = 0; n < 5; n++) {
    float t = time * (1.0 - (3.5 / float(n + 1)));
    i = p + vec2(cos(t - i.x) + sin(t + i.y), sin(t - i.y) + cos(t + i.x));
    c += 1.0 / length(vec2(p.x / (sin(i.x + t) / inten), p.y / (cos(i.y + t) / inten)));
  }
  c /= 5.0;
  c = 1.17 - pow(c, 1.4);
  return pow(abs(c), 8.0);
}
void main() {
  vec2 position = v_uv * u_size;
  float e = 2.0;
  float h = mlWaterHeight(position, u_t, u_origin, u_age);
  float hx = mlWaterHeight(position + vec2(e, 0.0), u_t, u_origin, u_age);
  float hy = mlWaterHeight(position + vec2(0.0, e), u_t, u_origin, u_age);
  vec2 grad = vec2(hx - h, hy - h) / e;
  vec2 offset = grad * u_refraction * 6.0;
  vec4 floorColor = S(position + offset);
  float light = mlCausticNetwork((position + offset * 2.0) / 240.0, u_t * 0.5);
  vec3 rgb = floorColor.rgb * vec3(0.80, 0.93, 1.0);
  rgb += vec3(0.80, 0.96, 1.0) * light * u_intensity * floorColor.a;
  rgb = min(rgb, vec3(floorColor.a));
  gl_FragColor = vec4(rgb, floorColor.a);
}`;

/** `PoolFloor`: aqua tiles, white grout every 24 pt and a dark lane "T". */
function drawFloor(g: CanvasRenderingContext2D) {
  g.fillStyle = "#7FD8E8";
  g.fillRect(0, 0, W, H);
  g.fillStyle = "#16507A";
  g.beginPath();
  g.roundRect(W / 2 - 18, 36, 36, H - 72, 6);
  g.fill();
  g.beginPath();
  g.roundRect(W / 2 - 54, 36, 108, 22, 6);
  g.fill();
  g.strokeStyle = "rgba(255,255,255,0.55)";
  g.lineWidth = 1.5;
  g.beginPath();
  for (let x = 0; x <= W; x += 24) {
    g.moveTo(x, 0);
    g.lineTo(x, H);
  }
  for (let y = 0; y <= H; y += 24) {
    g.moveTo(0, y);
    g.lineTo(W, y);
  }
  g.stroke();
}

export default function Caustics({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const layer = useLayer(W, H);
  const clock = useSpeedClock();
  const drop = useRef({ origin: { x: 150, y: 160 }, at: -1 });
  const painted = useRef(false);

  const dropAt = (x: number, y: number) => {
    haptics.tap("soft");
    drop.current = { origin: { x, y }, at: nowSec() };
  };
  useAutoplay(ctx.isPreview, () => dropAt(randIn(70, 230), randIn(80, 240)), { every: 3, delay: 0.4 });

  return (
    <CenterStack ctx={ctx} en="Tap the water" zh="点击水面" gap={12}>
      <div
        onClick={(e) => {
          const p = localPoint(e, e.currentTarget);
          dropAt(p.x, p.y);
        }}
        style={{ position: "relative", width: W, height: H, flexShrink: 0, borderRadius: 30, boxShadow: "0 12px 22px rgb(58 196 255 / 0.35)", cursor: "pointer" }}
      >
        <div style={{ width: W, height: H, borderRadius: 30, overflow: "hidden", transform: "translateZ(0)" }}>
          <Shader
            width={W}
            height={H}
            fragment={FRAG}
            source={layer.canvas}
            fps={ctx.isPreview ? 30 : undefined}
            uniforms={() => {
              if (!painted.current) {
                layer.paint((g) => drawFloor(g));
                painted.current = true;
              }
              const { origin, at } = drop.current;
              return {
                u_t: clock.advance(nowSec(), ctx.n("speed")),
                u_intensity: ctx.n("intensity"),
                u_refraction: ctx.n("refraction"),
                u_origin: [origin.x, origin.y],
                u_age: at < 0 ? -1 : nowSec() - at,
              };
            }}
          />
        </div>
        <div style={{ position: "absolute", inset: 0, borderRadius: 30, boxShadow: "inset 0 0 0 1px rgb(255 255 255 / 0.25)", pointerEvents: "none" }} />
      </div>
    </CenterStack>
  );
}
