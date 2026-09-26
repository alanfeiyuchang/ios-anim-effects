/** shader.dither · 有序抖动 (Shaders+RetroTape.swift, mlDither) */
import { animate, useMotionValue } from "motion/react";
import { useRef } from "react";
import { anim, fonts, spring, useAutoplay, useHaptics, useTimeouts, type DemoProps } from "../../kit";
import { ART_H, ART_W, LIB, nowSec, rgb, useLayer, useSpeedClock } from "./_shared";
import { CenterStack } from "./_stage";
import { Shader } from "./_gl";

const FRAG = `
uniform float u_pixel;
uniform float u_levels;
uniform vec3 u_dark;
uniform vec3 u_light;
${LIB}
void main() {
  vec2 position = v_uv * u_size;
  float s = max(u_pixel, 1.0);
  vec2 cell = max(floor(position / s), vec2(0.0));
  vec4 c = S((cell + 0.5) * s);
  if (c.a < 0.01) { gl_FragColor = vec4(0.0); return; }
  vec3 rgb = c.rgb / c.a;
  float l = dot(rgb, vec3(0.299, 0.587, 0.114));
  // 4×4 Bayer index from the cell's low bits (no bitwise ops in GLSL ES 1.0).
  float x = mod(cell.x, 4.0);
  float y = mod(cell.y, 4.0);
  float x0 = mod(x, 2.0);
  float y0 = mod(y, 2.0);
  float x1 = floor(x / 2.0);
  float y1 = floor(y / 2.0);
  float bayer = 4.0 * (abs(x0 - y0) * 2.0 + y0) + (abs(x1 - y1) * 2.0 + y1);
  float threshold = (bayer + 0.5) / 16.0;
  float n = max(floor(u_levels), 2.0) - 1.0;
  float q = clamp(floor(l * n + threshold) / n, 0.0, 1.0);
  vec3 col = mix(u_dark, u_light, q);
  gl_FragColor = vec4(col, 1.0) * c.a;
}`;

const PALETTES: [number, number][] = [
  [0x0f380f, 0x9bbc0f],
  [0x111111, 0xf2f2f2],
  [0x1a0c00, 0xffb000],
  [0x0a2463, 0xbfe3ff],
];

const grey = (w: number) => `rgb(${Math.round(w * 255)},${Math.round(w * 255)},${Math.round(w * 255)})`;

function drawMoon(g: CanvasRenderingContext2D, x: number, y: number) {
  const r = 16;
  const grad = g.createRadialGradient(x - 5, y - 5, 0, x - 5, y - 5, r * 1.6);
  grad.addColorStop(0, "#fff");
  grad.addColorStop(1, grey(0.3));
  g.fillStyle = grad;
  g.beginPath();
  g.arc(x, y, r, 0, Math.PI * 2);
  g.fill();
}

/** `DitherScene`: a lit planet with a ring, an orbiting moon and a gradient sky. */
function drawScene(g: CanvasRenderingContext2D, time: number) {
  const w = ART_W;
  const h = ART_H;
  const sky = g.createLinearGradient(0, 0, 0, h);
  sky.addColorStop(0, grey(0.05));
  sky.addColorStop(1, grey(0.45));
  g.fillStyle = sky;
  g.fillRect(0, 0, w, h);
  const cx = w / 2;
  const cy = h * 0.46;
  const moonAngle = time * 0.8;
  const mx = cx + 112 * Math.cos(moonAngle);
  const my = cy + 34 * Math.sin(moonAngle);
  const behind = Math.sin(moonAngle) < 0;
  if (behind) drawMoon(g, mx, my);
  const radius = 78;
  const lx = cx + 50 * Math.cos(time * 0.5);
  const ly = cy - 30 + 12 * Math.sin(time * 0.5);
  const disc = g.createRadialGradient(lx, ly, 0, lx, ly, radius * 1.7);
  disc.addColorStop(0, "#fff");
  disc.addColorStop(0.5, grey(0.55));
  disc.addColorStop(1, grey(0.08));
  g.fillStyle = disc;
  g.beginPath();
  g.arc(cx, cy, radius, 0, Math.PI * 2);
  g.fill();
  g.strokeStyle = grey(0.8);
  g.lineWidth = 3;
  g.beginPath();
  g.ellipse(cx, cy, radius * 1.5, 12, 0, 0, Math.PI * 2);
  g.stroke();
  if (!behind) drawMoon(g, mx, my);
  g.fillStyle = "#fff";
  g.font = `800 15px ${fonts.mono}`;
  g.textAlign = "center";
  g.textBaseline = "middle";
  g.fillText("PLANET·01", w / 2, h - 30);
}

export default function Dither({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const layer = useLayer(ART_W, ART_H);
  const clock = useSpeedClock();
  const palette = useRef(0);
  const crunch = useMotionValue(0);
  const { after } = useTimeouts();

  /** Pixel crunch: swell for 80 ms, swap the palette at the peak, spring back. */
  const cycle = () => {
    haptics.tap("rigid");
    animate(crunch, 10, anim.easeOut(0.08));
    after(0.08, () => {
      palette.current += 1;
      animate(crunch, 0, spring(0.45, 0.8));
    });
  };
  useAutoplay(ctx.isPreview, cycle, { every: 2.4, delay: 0.6 });

  return (
    <CenterStack ctx={ctx} en="Tap to swap the palette" zh="点击切换配色">
      <div onClick={cycle} style={{ width: ART_W, height: ART_H, flexShrink: 0, borderRadius: 30, overflow: "hidden", cursor: "pointer", transform: "translateZ(0)" }}>
        <Shader
          width={ART_W}
          height={ART_H}
          fragment={FRAG}
          source={layer.canvas}
          fps={ctx.isPreview ? 30 : undefined}
          uniforms={() => {
            const time = clock.advance(nowSec(), 1);
            const sceneTime = ctx.b("stopMotion") ? Math.floor(time * 12) / 12 : time;
            layer.paint((g) => drawScene(g, sceneTime));
            const [dark, light] = PALETTES[palette.current % PALETTES.length];
            return { u_pixel: Math.max(ctx.n("pixel") + crunch.get(), 1), u_levels: ctx.n("levels"), u_dark: rgb(dark), u_light: rgb(light) };
          }}
        />
      </div>
    </CenterStack>
  );
}
