/** shader.progressive-blur · 渐进模糊 (Shaders+Light.swift, mlProgressiveBlur) */
import { animate, useMotionValue } from "motion/react";
import { Bird, ChevronRight, CloudRain, Flower2, Lamp, Sunrise, Waves } from "lucide-react";
import { useRef, type ComponentType } from "react";
import { Palette, fonts, localPoint, spring, useAutoplay, useHaptics, useTimeouts, type DemoProps } from "../../kit";
import { LIB, drawIcon, iconImage, nowSec, systemColors, useLayer, useSpeedClock } from "./_shared";
import { CenterStack } from "./_stage";
import { Shader } from "./_gl";

const W = 300;
const H = 330;
const ROW = 72;
const ROWS = 6;

const FRAG = `
uniform float u_maxRadius;
uniform float u_focusY;
uniform float u_band;
uniform float u_fade;
uniform float u_mode;
uniform float u_taps;
${LIB}
void main() {
  vec2 position = v_uv * u_size;
  float d = u_mode < 0.5 ? (u_focusY - position.y) : (abs(position.y - u_focusY) - u_band);
  float amount = smoothstep(0.0, max(u_fade, 1.0), d);
  float radius = u_maxRadius * amount;
  if (radius < 0.5) { gl_FragColor = S(position); return; }
  float jitter = mlHash(floor(position * 3.0)) * 6.2831853;
  float n = floor(clamp(u_taps, 1.0, 32.0));
  vec4 acc = vec4(0.0);
  float total = 0.0;
  for (int i = 0; i < 32; i++) {
    if (float(i) >= n) break;
    float fi = float(i) + 0.5;
    float rr = sqrt(fi / n) * radius;
    float th = fi * 2.3999632 + jitter;
    float w = 1.0 - 0.45 * (rr / radius);
    acc += S(position + vec2(cos(th), sin(th)) * rr) * w;
    total += w;
  }
  gl_FragColor = acc / total;
}`;

const TITLES: [string, string][] = [
  ["Morning Light", "晨光"], ["Tide Pools", "潮汐池"], ["Night Market", "夜市"],
  ["Paper Cranes", "纸鹤"], ["Neon Rain", "霓虹雨"], ["Desert Bloom", "沙漠花开"],
];
const SYMBOLS = [Sunrise, Waves, Lamp, Bird, CloudRain, Flower2] as unknown as ComponentType<Record<string, unknown>>[];

function drawFeed(g: CanvasRenderingContext2D, time: number, zh: boolean, scheme: "dark" | "light") {
  const sys = systemColors(scheme);
  g.fillStyle = sys.elevated;
  g.fillRect(0, 0, W, H);
  const offset = (time * 22) % (ROW * ROWS);
  const colors = Palette.spectrum;
  const chevron = iconImage(ChevronRight as unknown as ComponentType<Record<string, unknown>>, `pb-chevron-${scheme}`, { color: sys.label3, strokeWidth: 3.4 });
  for (let r = 0; r < ROWS * 2; r++) {
    const index = r % ROWS;
    const y = r * ROW - offset;
    if (y > H || y + ROW < 0) continue;
    const cy = y + ROW / 2;
    const grad = g.createLinearGradient(18, cy - 26, 70, cy + 26);
    grad.addColorStop(0, colors[index % colors.length]);
    grad.addColorStop(1, colors[(index + 2) % colors.length]);
    g.fillStyle = grad;
    g.beginPath();
    g.roundRect(18, cy - 26, 52, 52, 14);
    g.fill();
    const icon = iconImage(SYMBOLS[index], `pb-${index}`, { strokeWidth: 2.4 });
    drawIcon(g, icon, 44, cy, 26);
    g.textAlign = "left";
    g.textBaseline = "middle";
    g.fillStyle = sys.label;
    g.font = `600 15px ${fonts.text}`;
    g.fillText(TITLES[index][zh ? 1 : 0], 84, cy - 10);
    g.fillStyle = sys.label2;
    g.font = `400 12px ${fonts.text}`;
    g.fillText(zh ? `${12 + index * 7} 张照片` : `${12 + index * 7} photos`, 84, cy + 11);
    drawIcon(g, chevron, W - 18 - 5, cy, 14);
  }
}

export default function ProgressiveBlur({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const layer = useLayer(W, H);
  const clock = useSpeedClock();
  const tiltShift = ctx.i("mode") === 1;
  const restFocus = tiltShift ? 190 : 150;
  const focus = useMotionValue(restFocus);
  const custom = useRef(false);
  const generation = useRef(0);
  const { after } = useTimeouts();
  if (!custom.current && !focus.isAnimating() && focus.get() !== restFocus) focus.set(restFocus);

  /** Simulated tap: glide the focus line down, then back to rest. */
  const sweepFocus = () => {
    generation.current += 1;
    const token = generation.current;
    custom.current = true;
    animate(focus, restFocus + 90, spring(0.7, 0.8));
    after(1.1, () => {
      if (token !== generation.current) return;
      custom.current = false;
      animate(focus, restFocus, spring(0.7, 0.8));
    });
  };
  useAutoplay(ctx.isPreview, sweepFocus, { every: 2.4, delay: 0.3 });

  return (
    <CenterStack ctx={ctx} en="Tap to move the focus line" zh="点击移动对焦线" gap={12}>
      <div
        onClick={(e) => {
          generation.current += 1;
          custom.current = true;
          haptics.selection();
          animate(focus, localPoint(e, e.currentTarget).y, spring(0.5, 0.8));
        }}
        style={{
          position: "relative",
          width: W,
          height: H,
          flexShrink: 0,
          borderRadius: 28,
          overflow: "hidden",
          background: Palette.elevated,
          boxShadow: "0 10px 18px rgb(0 0 0 / 0.12)",
          cursor: "pointer",
          transform: "translateZ(0)",
        }}
      >
        <Shader
          width={W}
          height={H}
          fragment={FRAG}
          source={layer.canvas}
          fps={ctx.isPreview ? 30 : undefined}
          uniforms={() => {
            const time = clock.advance(nowSec(), 1);
            layer.paint((g) => drawFeed(g, time, ctx.lang === "zh", ctx.scheme));
            return {
              u_maxRadius: ctx.n("radius"),
              u_focusY: focus.get(),
              u_band: 20,
              u_fade: ctx.n("fade"),
              u_mode: tiltShift ? 1 : 0,
              u_taps: ctx.isPreview ? 16 : 32,
            };
          }}
        />
        {!tiltShift && (
          <div style={{ position: "absolute", left: 20, top: 22, fontFamily: fonts.rounded, fontSize: 30, fontWeight: 700, lineHeight: "36px", color: Palette.label, pointerEvents: "none" }}>
            {ctx.t("Library", "图库")}
          </div>
        )}
        <div style={{ position: "absolute", inset: 0, borderRadius: 28, boxShadow: `inset 0 0 0 1px ${Palette.stroke}`, pointerEvents: "none" }} />
      </div>
    </CenterStack>
  );
}
