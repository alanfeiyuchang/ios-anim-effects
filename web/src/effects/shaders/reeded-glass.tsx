/** shader.reeded-glass · 长虹玻璃 (Shaders+ReededGlass.swift, mlReededGlass) */
import { animate, motion, useMotionValue, useTransform } from "motion/react";
import { useRef } from "react";
import { Palette, clamp, localPoint, spring, useAutoplay, useHaptics, type DemoProps } from "../../kit";
import { ART_H, ART_W, LIB, drawArtwork, nowSec, rgba, useLayer, useSpeedClock } from "./_shared";
import { CenterStack } from "./_stage";
import { Shader } from "./_gl";

const PANEL = 150;
const DETENTS = [85, 130, 175];

const FRAG = `
uniform float u_panelX;
uniform float u_panelWidth;
uniform float u_rib;
uniform float u_strength;
uniform float u_frost;
${LIB}
void main() {
  vec2 position = v_uv * u_size;
  float left = u_panelX - u_panelWidth * 0.5;
  float local = position.x - left;
  if (local < 0.0 || local > u_panelWidth) { gl_FragColor = S(position); return; }
  float w = max(u_rib, 2.0);
  float u = fract(local / w) - 0.5;
  vec2 p = position + vec2(u * w * u_strength, 0.0);
  float f = max(u_frost, 0.0);
  vec4 c = S(p) * 0.36
         + S(p + vec2(0.0, 2.0 * f)) * 0.2
         + S(p - vec2(0.0, 2.0 * f)) * 0.2
         + S(p + vec2(0.0, 4.0 * f)) * 0.12
         + S(p - vec2(0.0, 4.0 * f)) * 0.12;
  float shade = 0.9 + 0.1 * cos(u * 6.2831853);
  float su = u + 0.28;
  float spec = exp(-(su * su) / 0.004) * 0.32;
  float edge = min(local, u_panelWidth - local);
  spec += exp(-edge / 1.2) * 0.45;
  c.rgb = c.rgb * shade + spec * c.a;
  c.rgb += vec3(0.03, 0.035, 0.05) * c.a;
  c = min(c, vec4(1.0));
  c.rgb = min(c.rgb, vec3(c.a));
  gl_FragColor = c;
}`;

/** `ReededSource`: artwork plus a drifting warm orb behind the glass. */
function drawSource(g: CanvasRenderingContext2D, k: number, time: number) {
  drawArtwork(g, k, 4);
  const x = ART_W / 2 + 80 * Math.cos(time * 0.9);
  const y = ART_H / 2 + 70 * Math.sin(time * 0.7);
  const orb = g.createRadialGradient(x, y, 0, x, y, 50);
  orb.addColorStop(0, Palette.amber);
  orb.addColorStop(1, rgba(Palette.amber, 0));
  g.fillStyle = orb;
  g.beginPath();
  g.arc(x, y, 50, 0, Math.PI * 2);
  g.fill();
}

export default function ReededGlass({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const layer = useLayer(ART_W, ART_H);
  const clock = useSpeedClock();
  const panelX = useMotionValue(130);
  const detent = useRef(1);
  const drag = useRef<{ id: number; start: { x: number; y: number }; client: { x: number; y: number }; scale: number; engaged: boolean; grab: number | null; lastX: number; lastT: number; vx: number } | null>(null);

  const snap = (index: number) => {
    detent.current = index;
    animate(panelX, DETENTS[index], spring(0.5, 0.72));
  };
  const nearest = (x: number) => DETENTS.reduce((best, d, i) => (Math.abs(d - x) < Math.abs(DETENTS[best] - x) ? i : best), 0);

  /** Preview loop: hop between the detents like a quick flick. */
  useAutoplay(ctx.isPreview, () => snap((detent.current + 1) % DETENTS.length), { every: 1.6, delay: 0.4 });

  const frameX = useTransform(panelX, (x) => x - PANEL / 2);

  return (
    <CenterStack ctx={ctx} en="Drag the glass panel" zh="拖动玻璃面板">
      <div
        onPointerDown={(e) => {
          if (drag.current) return;
          const el = e.currentTarget;
          const p = localPoint(e, el);
          // Only the panel itself is draggable.
          if (Math.abs(p.x - panelX.get()) > PANEL / 2) return;
          el.setPointerCapture(e.pointerId);
          drag.current = { id: e.pointerId, start: p, client: { x: e.clientX, y: e.clientY }, scale: el.getBoundingClientRect().width / el.offsetWidth || 1, engaged: false, grab: null, lastX: p.x, lastT: performance.now(), vx: 0 };
        }}
        onPointerMove={(e) => {
          const d = drag.current;
          if (!d || d.id !== e.pointerId) return;
          const p = { x: d.start.x + (e.clientX - d.client.x) / d.scale, y: d.start.y + (e.clientY - d.client.y) / d.scale };
          const now = performance.now();
          d.vx = d.vx * 0.6 + ((p.x - d.lastX) / Math.max((now - d.lastT) / 1000, 1 / 240)) * 0.4;
          d.lastX = p.x;
          d.lastT = now;
          const tx = p.x - d.start.x;
          const ty = p.y - d.start.y;
          if (!d.engaged) {
            if (Math.hypot(tx, ty) < 10 || Math.abs(tx) <= Math.abs(ty)) return;
            d.engaged = true;
          }
          if (d.grab === null) {
            d.grab = panelX.get() - d.start.x;
            haptics.tap("soft");
          }
          panelX.stop();
          panelX.set(clamp(p.x + d.grab, -PANEL / 2 * 0.4, ART_W + (PANEL / 2) * 0.4));
        }}
        onPointerUp={(e) => {
          const d = drag.current;
          if (!d || d.id !== e.pointerId) return;
          drag.current = null;
          if (!d.engaged) return;
          if (performance.now() - d.lastT > 80) d.vx = 0;
          // Throw projected from the predicted end location.
          const projected = d.lastX + d.vx * 0.25 + (d.grab ?? 0);
          haptics.selection();
          snap(nearest(projected));
        }}
        onPointerCancel={() => {
          const d = drag.current;
          drag.current = null;
          if (d?.engaged) snap(nearest(panelX.get()));
        }}
        style={{ position: "relative", width: ART_W, height: ART_H, flexShrink: 0, borderRadius: 30, overflow: "hidden", touchAction: "none", transform: "translateZ(0)" }}
      >
        <Shader
          width={ART_W}
          height={ART_H}
          fragment={FRAG}
          source={layer.canvas}
          fps={ctx.isPreview ? 30 : undefined}
          uniforms={() => {
            const time = clock.advance(nowSec(), 1);
            layer.paint((g, k) => drawSource(g, k, time));
            return { u_panelX: panelX.get(), u_panelWidth: PANEL, u_rib: ctx.n("rib"), u_strength: ctx.n("strength"), u_frost: ctx.n("frost") };
          }}
        />
        <motion.div style={{ position: "absolute", top: -2, x: frameX, left: 0, width: PANEL, height: ART_H + 4, boxShadow: "inset 0 0 0 1px rgb(255 255 255 / 0.28)", pointerEvents: "none", cursor: "grab" }} />
      </div>
    </CenterStack>
  );
}
