/** shader.jelly-press · 果冻按压 (Shaders+JellyPress.swift, mlJellyPress) */
import { animate, useMotionValue } from "motion/react";
import { useRef } from "react";
import { clamp, localPoint, spring, useAutoplay, useHaptics, useTimeouts, type DemoProps, type Point } from "../../kit";
import { ART_H, ART_W, LIB, drawArtwork, randIn, useLayer } from "./_shared";
import { CenterStack } from "./_stage";
import { Shader } from "./_gl";

const FRAG = `
uniform vec2 u_center;
uniform float u_radius;
uniform float u_strength;
uniform vec2 u_stretch;
${LIB}
void main() {
  vec2 position = v_uv * u_size;
  float rad = max(u_radius, 1.0);
  vec2 d = position - u_center;
  float dist = length(d);
  if (dist >= rad) { gl_FragColor = S(position); return; }
  float t = dist / rad;
  float fall = (1.0 - t * t) * (1.0 - t * t);
  vec2 p = position - d * u_strength * fall + u_stretch * fall;
  vec4 c = S(p);
  vec2 dir = dist > 0.001 ? d / dist : vec2(0.0);
  float slope = u_strength * 4.0 * t * (1.0 - t * t);
  float light = clamp(1.0 + 0.35 * slope * dot(dir, vec2(-0.6, -0.8)), 0.6, 1.4);
  c.rgb = min(c.rgb * light, vec3(c.a));
  gl_FragColor = c;
}`;

export default function JellyPress({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const layer = useLayer(ART_W, ART_H);
  const cx = useMotionValue(130);
  const cy = useMotionValue(150);
  const strength = useMotionValue(0);
  const sx = useMotionValue(0);
  const sy = useMotionValue(0);
  const { after } = useTimeouts();
  const s = useRef({ pressing: false, armToken: 0, armScheduled: false, vetoed: false, last: { x: 130, y: 150 } as Point });
  const touch = useRef<{ id: number; start: Point; client: Point; scale: number; lastT: number; lastP: Point; v: Point } | null>(null);

  const arm = (at: Point) => {
    const st = s.current;
    st.armToken += 1;
    st.pressing = true;
    cx.set(at.x);
    cy.set(at.y);
    haptics.tap("soft");
    animate(strength, ctx.n("depth"), spring(0.28, 0.62));
  };
  const scheduleArm = () => {
    const st = s.current;
    if (st.armScheduled) return;
    st.armScheduled = true;
    st.armToken += 1;
    const token = st.armToken;
    after(0.08, () => {
      if (token !== st.armToken || st.pressing || st.vetoed) return;
      arm(st.last);
    });
  };
  const release = () => {
    const t = spring(0.55, ctx.n("wobble"));
    animate(strength, 0, t);
    animate(sx, 0, t);
    animate(sy, 0, t);
  };
  /** Normal lift or cancellation: cancels a pending arm and wobbles out an armed dome. */
  const endTouch = () => {
    const st = s.current;
    st.armToken += 1;
    st.armScheduled = false;
    st.vetoed = false;
    if (st.pressing) {
      st.pressing = false;
      release();
    }
  };
  const poke = (at: Point) => {
    cx.set(at.x);
    cy.set(at.y);
    animate(strength, ctx.n("depth"), spring(0.28, 0.62));
    after(0.55, () => {
      if (s.current.pressing) return;
      release();
    });
  };
  useAutoplay(ctx.isPreview, () => poke({ x: randIn(70, 190), y: randIn(80, 220) }), { every: 2.2, delay: 0.3 });

  const changed = (location: Point, translation: Point, velocity: Point) => {
    const st = s.current;
    st.last = location;
    if (!st.pressing) {
      if (st.vetoed) return;
      const dx = Math.abs(translation.x);
      const dy = Math.abs(translation.y);
      if (dy > 6 && dy >= dx) {
        st.vetoed = true;
        st.armToken += 1;
        return;
      }
      if (dx > 6 && dx > dy) arm(location);
      else {
        scheduleArm();
        return;
      }
    }
    const t = spring(0.22, 0.78);
    animate(cx, location.x, t);
    animate(cy, location.y, t);
    animate(sx, clamp(velocity.x * 0.02, -28, 28), t);
    animate(sy, clamp(velocity.y * 0.02, -28, 28), t);
  };

  return (
    <CenterStack ctx={ctx} en="Press, hold and drag, then let go" zh="按住拖动，然后松手">
      <div
        onPointerDown={(e) => {
          if (touch.current) return;
          const el = e.currentTarget;
          el.setPointerCapture(e.pointerId);
          const p = localPoint(e, el);
          touch.current = { id: e.pointerId, start: p, client: { x: e.clientX, y: e.clientY }, scale: el.getBoundingClientRect().width / el.offsetWidth || 1, lastT: performance.now(), lastP: p, v: { x: 0, y: 0 } };
          changed(p, { x: 0, y: 0 }, { x: 0, y: 0 });
        }}
        onPointerMove={(e) => {
          const t = touch.current;
          if (!t || t.id !== e.pointerId) return;
          const p = { x: t.start.x + (e.clientX - t.client.x) / t.scale, y: t.start.y + (e.clientY - t.client.y) / t.scale };
          const now = performance.now();
          const dt = Math.max((now - t.lastT) / 1000, 1 / 240);
          t.v = { x: t.v.x * 0.6 + ((p.x - t.lastP.x) / dt) * 0.4, y: t.v.y * 0.6 + ((p.y - t.lastP.y) / dt) * 0.4 };
          t.lastT = now;
          t.lastP = p;
          changed(p, { x: p.x - t.start.x, y: p.y - t.start.y }, t.v);
        }}
        onPointerUp={(e) => {
          const t = touch.current;
          if (!t || t.id !== e.pointerId) return;
          touch.current = null;
          const dx = Math.abs(t.lastP.x - t.start.x);
          const dy = Math.abs(t.lastP.y - t.start.y);
          const st = s.current;
          const wasTap = !st.pressing && !st.vetoed && dx < 6 && dy < 6;
          endTouch();
          if (wasTap) {
            // A quick tap never reached the 80 ms arm: pop and release the dome now.
            haptics.tap("soft");
            poke(t.lastP);
          }
        }}
        onPointerCancel={() => {
          touch.current = null;
          endTouch();
        }}
        style={{ width: ART_W, height: ART_H, flexShrink: 0, touchAction: "none", cursor: "pointer" }}
      >
        <Shader
          width={ART_W}
          height={ART_H}
          fragment={FRAG}
          source={layer.canvas}
          fps={ctx.isPreview ? 30 : undefined}
          uniforms={() => {
            layer.paint((g, k) => drawArtwork(g, k, 1));
            return { u_center: [cx.get(), cy.get()], u_radius: ctx.n("radius"), u_strength: strength.get(), u_stretch: [sx.get(), sy.get()] };
          }}
        />
      </div>
    </CenterStack>
  );
}
