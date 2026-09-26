/** shader.liquid-glass-lens · 液态玻璃透镜 (Shaders+Glass.swift, mlLensDrop + droplet) */
import { animate, motion, useMotionValue, useTransform, type MotionValue } from "motion/react";
import { Camera, CloudLightning, Droplet, Flame, Heart, Leaf, MoonStar, Music, Sparkles, Star, Sun, Zap } from "lucide-react";
import { useRef, type ComponentType } from "react";
import { Palette, anim, spring, useAutoplay, useHaptics, useTimeouts, type DemoProps, type Point } from "../../kit";
import { LIB, drawIcon, iconImage, randIn, rgb, useHoldDrag, useLayer } from "./_shared";
import { BottomHint } from "./_stage";
import { Shader } from "./_gl";

const FRAG = `
uniform vec2 u_center;
uniform float u_radius;
uniform float u_strength;
uniform float u_heading;
uniform float u_stretch;
uniform float u_ripple;
${LIB}
vec2 mlLensDrop(vec2 position, vec2 center, float radius, float strength, float heading, float stretch, float ripple) {
  vec2 d = position - center;
  float c = cos(heading);
  float s = sin(heading);
  vec2 local = vec2(c * d.x + s * d.y, -s * d.x + c * d.y);
  vec2 axes = max(radius * vec2(1.0 + stretch, 1.0 - stretch * 0.6), vec2(1.0));
  float t = length(local / axes);
  vec2 source = local;
  if (t < 1.0) {
    source = local * mix(1.0 - strength, 1.0, t * t);
  }
  if (ripple > 0.001 && ripple < 0.999 && t < 1.4) {
    float band = t - ripple * 1.35;
    float wave = exp(-band * band * 40.0) * sin(band * 18.0) * (1.0 - ripple);
    float len = length(local);
    if (len > 0.001) {
      source += (local / len) * wave * 9.0;
    }
  }
  return center + vec2(c * source.x - s * source.y, s * source.x + c * source.y);
}
void main() {
  vec2 position = v_uv * u_size;
  gl_FragColor = S(mlLensDrop(position, u_center, u_radius, u_strength, u_heading, u_stretch, u_ripple));
}`;

const SYMBOLS: [unknown, boolean][] = [
  [Sun, true], [MoonStar, true], [CloudLightning, true], [Leaf, true], [Flame, true], [Droplet, true],
  [Sparkles, true], [Zap, true], [Heart, true], [Star, true], [Music, false], [Camera, true],
];

/** `LensBackdrop`: lilac gradient and a 4-column grid of gradient tiles with white glyphs. */
function drawBackdrop(g: CanvasRenderingContext2D, w: number, h: number) {
  const bg = g.createLinearGradient(0, 0, 0, h);
  bg.addColorStop(0, "#FDEBFF");
  bg.addColorStop(1, "#DDE6FF");
  g.fillStyle = bg;
  g.fillRect(0, 0, w, h);
  const cell = (w - 48 - 14 * 3) / 4;
  const gridH = cell * 3 + 14 * 2;
  const top = (h - gridH) / 2;
  SYMBOLS.forEach(([Icon, fill], i) => {
    const x = 24 + (i % 4) * (cell + 14);
    const y = top + Math.floor(i / 4) * (cell + 14);
    const color = Palette.spectrum[i % Palette.spectrum.length];
    // `Color.gradient`: a gentle top-to-bottom lift of the same hue.
    const grad = g.createLinearGradient(0, y, 0, y + cell);
    const [r, gg, b] = rgb(color).map((c) => Math.round((c * 0.82 + 0.18) * 255));
    grad.addColorStop(0, `rgb(${r},${gg},${b})`);
    grad.addColorStop(1, color);
    g.fillStyle = grad;
    g.beginPath();
    g.roundRect(x, y, cell, cell, 16);
    g.fill();
    const img = iconImage(Icon as ComponentType<Record<string, unknown>>, `lens-${i}`, fill ? { fill: "#fff", strokeWidth: 1.6 } : { strokeWidth: 2.4 });
    drawIcon(g, img, x + cell / 2, y + cell / 2, 27);
  });
}

export default function LiquidGlassLens({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const W = 340;
  const H = ctx.isPreview ? 340 : 400;
  const layer = useLayer(W, H);
  const diameter = ctx.n("size");
  const px = useMotionValue(W / 2);
  const py = useMotionValue(H / 2);
  const stretch = useMotionValue(0);
  const heading = useMotionValue(0);
  const pulse = useMotionValue(1);
  const ripples = useMotionValue(0);
  const grab = useRef<Point | null>(null);
  const origin = useRef<Point>({ x: 0, y: 0 });
  const { after } = useTimeouts();

  const release = () => {
    if (!grab.current && stretch.get() === 0) return;
    grab.current = null;
    animate(stretch, 0, spring(0.35, 0.6));
  };
  const flex = () => {
    haptics.tap("soft");
    animate(pulse, 1.12, spring(0.2, 0.5));
    animate(ripples, Math.floor(ripples.get()) + 1, anim.easeOut(0.75));
    after(0.18, () => animate(pulse, 1, spring(0.4, 0.45)));
  };
  const hold = useHoldDrag(0.1, {
    onArm: () => {
      origin.current = { x: px.get() - diameter / 2, y: py.get() - diameter / 2 };
    },
    onDrag: ({ start, location, velocity }) => {
      const o = origin.current;
      if (!grab.current) {
        const dx = px.get() - (start.x + o.x);
        const dy = py.get() - (start.y + o.y);
        grab.current = Math.hypot(dx, dy) <= diameter / 2 ? { x: dx, y: dy } : { x: 0, y: 0 };
      }
      const speed = Math.hypot(velocity.x, velocity.y);
      const t = spring(0.18, 0.8);
      animate(px, location.x + o.x + grab.current.x, t);
      animate(py, location.y + o.y + grab.current.y, t);
      animate(stretch, Math.min(speed / 3000, 0.12), t);
      if (speed > 60) {
        // Stretch is symmetric, so keep the angle in (-π/2, π/2] to avoid spinning through 180°.
        let angle = Math.atan2(velocity.y, velocity.x);
        if (angle > Math.PI / 2) angle -= Math.PI;
        if (angle <= -Math.PI / 2) angle += Math.PI;
        heading.set(angle);
      }
    },
    onEnd: release,
  });
  const down = useRef<Point | null>(null);

  /** Simulated drag: slide diagonally with a stretch, then relax. */
  const glide = () => {
    const target = { x: randIn(80, Math.max(81, W - 80)), y: randIn(80, Math.max(81, H - 80)) };
    let angle = Math.atan2(target.y - py.get(), target.x - px.get());
    if (angle > Math.PI / 2) angle -= Math.PI;
    if (angle <= -Math.PI / 2) angle += Math.PI;
    heading.set(angle);
    animate(px, target.x, spring(0.8, 0.65));
    animate(py, target.y, spring(0.8, 0.65));
    animate(stretch, 0.1, spring(0.25, 0.8));
    after(0.35, () => animate(stretch, 0, spring(0.35, 0.6)));
  };
  useAutoplay(ctx.isPreview, glide, { every: 1.6, delay: 0.2 });

  const left = useTransform(px, (x) => x - diameter / 2);
  const top = useTransform(py, (y) => y - diameter / 2);

  return (
    <div style={{ position: "absolute", inset: 0 }}>
      <Shader
        width={W}
        height={H}
        fragment={FRAG}
        source={layer.canvas}
        fps={ctx.isPreview ? 30 : undefined}
        uniforms={() => {
          layer.paint((g) => drawBackdrop(g, W, H));
          const r = ripples.get();
          return {
            u_center: [px.get(), py.get()],
            u_radius: diameter / 2,
            // Deliberately light (a thin water film, not a magnifier).
            u_strength: 0.2,
            u_heading: heading.get(),
            u_stretch: stretch.get(),
            u_ripple: r - Math.floor(r),
          };
        }}
      />
      <motion.div style={{ position: "absolute", left, top, width: diameter, height: diameter, pointerEvents: "none" }}>
        <DropletView diameter={diameter} tinted={ctx.b("tint")} stretch={stretch} heading={heading} pulse={pulse} />
      </motion.div>
      <motion.div
        {...hold}
        onPointerDown={(e) => {
          down.current = { x: e.clientX, y: e.clientY };
          hold.onPointerDown(e);
        }}
        onPointerUp={(e) => {
          const d = down.current;
          down.current = null;
          hold.onPointerUp(e);
          if (d && Math.hypot(e.clientX - d.x, e.clientY - d.y) < 10) flex();
        }}
        style={{ position: "absolute", left, top, width: diameter, height: diameter, borderRadius: "50%", cursor: "grab", touchAction: "none" }}
      />
      <BottomHint ctx={ctx} en="Hold and drag, or tap the droplet" zh="按住拖动，或点击水滴" bottom={12} />
    </div>
  );
}

/** The droplet: a clear Liquid Glass bead (rim light, inner hairline, specular), stretched along the heading. */
function DropletView({
  diameter,
  tinted,
  stretch,
  heading,
  pulse,
}: {
  diameter: number;
  tinted: boolean;
  stretch: MotionValue<number>;
  heading: MotionValue<number>;
  pulse: MotionValue<number>;
}) {
  const transform = useTransform([stretch, heading, pulse] as MotionValue<number>[], ([s, h, p]: number[]) => `scale(${p}) rotate(${h}rad) scale(${1 + s}, ${1 - s * 0.6}) rotate(${-h}rad)`);
  const d = diameter;
  return (
    <motion.div style={{ position: "absolute", inset: 0, transform, filter: "drop-shadow(0 8px 14px rgb(0 0 0 / 0.18))" }}>
      <div
        style={{
          position: "absolute",
          inset: 0,
          borderRadius: "50%",
          background: `radial-gradient(circle closest-side, transparent 0%, transparent 50%, rgb(255 255 255 / 0.22) 100%), ${tinted ? "rgb(164 107 255 / 0.18)" : "rgb(255 255 255 / 0.06)"}`,
          backdropFilter: "blur(1.5px) saturate(1.35) brightness(1.04)",
          WebkitBackdropFilter: "blur(1.5px) saturate(1.35) brightness(1.04)",
          boxShadow: "inset 0 1px 1.5px rgb(255 255 255 / 0.9), inset 0 -1px 2px rgb(255 255 255 / 0.45)",
        }}
      />
      <div style={{ position: "absolute", inset: 2.5, borderRadius: "50%", boxShadow: "inset 0 0 0 1px rgb(255 255 255 / 0.45)" }} />
      <svg width={d} height={d} style={{ position: "absolute", inset: 0, overflow: "visible" }}>
        <defs>
          <linearGradient id="ml-lens-rim" x1="0" y1="0" x2="1" y2="1">
            <stop offset="0" stopColor="#fff" stopOpacity={0.9} />
            <stop offset="0.5" stopColor="#fff" stopOpacity={0.15} />
            <stop offset="1" stopColor="#fff" stopOpacity={0.6} />
          </linearGradient>
        </defs>
        <circle cx={d / 2} cy={d / 2} r={d / 2 - 0.75} fill="none" stroke="url(#ml-lens-rim)" strokeWidth={1.5} />
      </svg>
      <div
        style={{
          position: "absolute",
          left: d * 0.18,
          top: d * 0.14,
          width: d * 0.32,
          height: d * 0.16,
          borderRadius: "50%",
          background: "rgb(255 255 255 / 0.55)",
          filter: "blur(4px)",
        }}
      />
    </motion.div>
  );
}
