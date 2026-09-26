/** shader.kaleidoscope · 万花筒 (Shaders+Optics.swift, mlKaleidoscope) */
import { useRef } from "react";
import { Palette, useAutoplay, type DemoProps } from "../../kit";
import { LIB, nowSec, rgba, useLayer, useSpeedClock, useStageTouch } from "./_shared";
import { CenterStack } from "./_stage";
import { Shader } from "./_gl";

const SIZE = 280;

const FRAG = `
uniform float u_segments;
uniform float u_rotation;
uniform float u_spin;
uniform float u_zoom;
${LIB}
void main() {
  vec2 position = v_uv * u_size;
  vec2 size = u_size;
  vec2 c = size * 0.5;
  vec2 d = position - c;
  float r = length(d) / max(u_zoom, 1.0);
  float seg = 6.2831853 / max(floor(u_segments), 2.0);
  float a = atan(d.y, d.x) + u_rotation;
  a = a - seg * floor(a / seg);
  a = abs(a - seg * 0.5);
  vec2 p = c + vec2(cos(a + u_spin), sin(a + u_spin)) * r;
  p = clamp(p, vec2(0.5), size - 0.5);
  gl_FragColor = S(p);
}`;

const COLORS = [Palette.amber, Palette.mint, Palette.pink, "#FFFFFF", Palette.sky, Palette.coral, Palette.violet];

/** style 0: dots, 1: petals, 2: rotated bars. */
function ring(g: CanvasRenderingContext2D, cx: number, cy: number, radius: number, count: number, size: number, style: number, phase: number, time: number) {
  for (let i = 0; i < count; i++) {
    const angle = (i / count) * 2 * Math.PI + phase;
    const x = cx + Math.cos(angle) * radius;
    const y = cy + Math.sin(angle) * radius;
    const color = COLORS[(i + style * 2) % COLORS.length];
    const w = size * (0.7 + 0.3 * (i % 3));
    g.save();
    if (style === 1) {
      g.translate(x, y);
      g.rotate(angle + Math.PI / 2);
      g.fillStyle = rgba(color, 0.92);
      g.beginPath();
      g.ellipse(0, 0, w * 0.35, w * 0.8, 0, 0, Math.PI * 2);
      g.fill();
    } else if (style === 2) {
      g.translate(x, y);
      g.rotate(angle * 1.5 + time * 0.4);
      g.fillStyle = color;
      g.beginPath();
      g.roundRect(-w * 0.18, -w, w * 0.36, w * 2, w * 0.18);
      g.fill();
    } else {
      g.fillStyle = color;
      g.beginPath();
      g.arc(x, y, w / 2, 0, Math.PI * 2);
      g.fill();
      g.fillStyle = "rgba(27,20,100,0.55)";
      g.beginPath();
      g.arc(x, y, w * 0.2, 0, Math.PI * 2);
      g.fill();
    }
    g.restore();
  }
}

/** `KaleidoSource`: a turning angular gradient, a soft white core and four rings of motifs. */
function drawSource(g: CanvasRenderingContext2D, time: number) {
  const c = SIZE / 2;
  const conic = g.createConicGradient((time * 12 * Math.PI) / 180, c, c);
  const stops = [Palette.indigo, Palette.pink, Palette.amber, Palette.mint, Palette.sky, Palette.violet, Palette.indigo];
  stops.forEach((s, i) => conic.addColorStop(i / (stops.length - 1), s));
  g.fillStyle = conic;
  g.fillRect(0, 0, SIZE, SIZE);
  const glow = g.createRadialGradient(c, c, 0, c, c, 70);
  glow.addColorStop(0, "rgba(255,255,255,0.55)");
  glow.addColorStop(1, "rgba(255,255,255,0)");
  g.fillStyle = glow;
  g.fillRect(0, 0, SIZE, SIZE);
  ring(g, c, c, 46 + 6 * Math.sin(time * 0.8), 7, 18, 0, time * 0.2, time);
  ring(g, c, c, 92 + 8 * Math.sin(time * 0.6 + 1), 9, 30, 1, -time * 0.15, time);
  ring(g, c, c, 138 + 10 * Math.cos(time * 0.5), 11, 24, 2, time * 0.1, time);
  ring(g, c, c, 180, 13, 16, 0, -time * 0.12, time);
}

export default function Kaleidoscope({ ctx }: DemoProps) {
  const layer = useLayer(SIZE, SIZE);
  const clock = useSpeedClock();
  const spin = useRef({ offset: 0, drag: 0, startX: null as number | null });
  const twist = useRef({ count: 0, start: 0 });

  const touch = useStageTouch(
    (p) => {
      const s = spin.current;
      if (s.startX === null) s.startX = p.x;
      s.drag = (p.x - s.startX) / 70;
    },
    () => {
      // Keeps the twist where the finger left it.
      const s = spin.current;
      s.offset += s.drag;
      s.drag = 0;
      s.startX = null;
    },
  );

  /** A flourish: each one adds 0.9 rad with a cubic ease-out over 1.2 s. */
  const introTwist = () => {
    twist.current = { count: twist.current.count + 1, start: nowSec() };
  };
  useAutoplay(ctx.isPreview, introTwist, { every: 4, delay: 0.2 });
  const scriptedTwist = () => {
    const { count, start } = twist.current;
    if (count === 0) return 0;
    const p = Math.min(Math.max((nowSec() - start) / 1.2, 0), 1);
    return 0.9 * (count - 1 + (1 - (1 - p) ** 3));
  };

  return (
    <CenterStack ctx={ctx} en="Drag sideways to turn the tube" zh="左右拖动以转动镜筒" gap={12}>
      <div
        {...touch}
        style={{
          position: "relative",
          width: SIZE,
          height: SIZE,
          borderRadius: "50%",
          boxShadow: "0 10px 24px rgb(164 107 255 / 0.35)",
          flexShrink: 0,
          cursor: "grab",
          ...touch.style,
        }}
      >
        <div style={{ width: SIZE, height: SIZE, borderRadius: "50%", overflow: "hidden", transform: "translateZ(0)" }}>
          <Shader
            width={SIZE}
            height={SIZE}
            fragment={FRAG}
            source={layer.canvas}
            fps={ctx.isPreview ? 30 : undefined}
            uniforms={() => {
              const time = clock.advance(nowSec(), ctx.n("speed"));
              layer.paint((g) => drawSource(g, time));
              const manual = spin.current.offset + spin.current.drag + scriptedTwist();
              return { u_segments: ctx.n("segments"), u_rotation: -time * 0.15, u_spin: time * 0.35 + manual, u_zoom: ctx.n("zoom") };
            }}
          />
        </div>
        <svg width={SIZE} height={SIZE} style={{ position: "absolute", inset: 0, pointerEvents: "none" }}>
          <defs>
            <linearGradient id="ml-kaleido-rim" x1="0" y1="0" x2="1" y2="1">
              <stop offset="0" stopColor="#fff" stopOpacity={0.7} />
              <stop offset="1" stopColor="#fff" stopOpacity={0.08} />
            </linearGradient>
          </defs>
          <circle cx={SIZE / 2} cy={SIZE / 2} r={SIZE / 2 - 0.75} fill="none" stroke="url(#ml-kaleido-rim)" strokeWidth={1.5} />
        </svg>
      </div>
    </CenterStack>
  );
}
