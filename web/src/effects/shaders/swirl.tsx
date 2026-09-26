/** shader.swirl · 漩涡扭转 (Shaders+Distortion.swift, mlSwirl) */
import { animate, useMotionValue } from "motion/react";
import { useRef } from "react";
import { anim, clamp, spring, useAutoplay, useHaptics, useTimeouts, type DemoProps, type Point } from "../../kit";
import { ART_H, ART_W, LIB, drawArtwork, useHoldDrag, useLayer } from "./_shared";
import { CenterStack } from "./_stage";
import { Shader } from "./_gl";

const FRAG = `
uniform vec2 u_center;
uniform float u_radius;
uniform float u_angle;
${LIB}
vec2 mlSwirl(vec2 position, vec2 center, float radius, float angle) {
  vec2 d = position - center;
  float dist = length(d);
  if (dist >= radius) return position;
  float t = 1.0 - dist / radius;
  float a = angle * t * t;
  float s = sin(a);
  float c = cos(a);
  return center + vec2(d.x * c - d.y * s, d.x * s + d.y * c);
}
void main() {
  vec2 position = v_uv * u_size;
  if (abs(u_angle) <= 0.001) { gl_FragColor = S(position); return; }
  gl_FragColor = S(mlSwirl(position, u_center, u_radius, u_angle));
}`;

export default function Swirl({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const layer = useLayer(ART_W, ART_H);
  const cx = useMotionValue(130);
  const cy = useMotionValue(150);
  const angle = useMotionValue(0);
  const generation = useRef(0);
  const stir = useRef<{ lastPoint: Point | null; lastHeading: Point | null; swept: number; direction: number }>({
    lastPoint: null,
    lastHeading: null,
    swept: 0,
    direction: 1,
  });
  const { after } = useTimeouts();

  const resetStir = () => {
    stir.current.lastPoint = null;
    stir.current.lastHeading = null;
    stir.current.swept = 0;
  };
  /** Accumulates how far the finger's heading has turned (sampled every ≥ 4 pt), with ±0.35 rad hysteresis. */
  const track = (point: Point) => {
    const s = stir.current;
    if (!s.lastPoint) {
      s.lastPoint = point;
      return;
    }
    const step = { x: point.x - s.lastPoint.x, y: point.y - s.lastPoint.y };
    if (Math.hypot(step.x, step.y) < 4) return;
    s.lastPoint = point;
    if (s.lastHeading) {
      const h = s.lastHeading;
      const cross = h.x * step.y - h.y * step.x;
      const dot = h.x * step.x + h.y * step.y;
      s.swept = clamp(s.swept + Math.atan2(cross, dot), -1, 1);
      if (s.swept > 0.35) s.direction = 1;
      else if (s.swept < -0.35) s.direction = -1;
    }
    s.lastHeading = step;
  };
  const unwind = () => {
    resetStir();
    if (angle.get() === 0) return;
    animate(angle, 0, spring(0.6, 0.5));
  };

  const hold = useHoldDrag(0.25, {
    onArm: () => {
      generation.current += 1;
      resetStir();
      haptics.tap("soft");
    },
    onDrag: ({ location, translation }) => {
      // The vortex rides under the finger; distance sets the twist, the stirring direction its sign.
      cx.set(location.x);
      cy.set(location.y);
      track(location);
      const maxAngle = ctx.n("maxAngle");
      const distance = Math.hypot(translation.x, translation.y);
      const target = clamp((-stir.current.direction * distance) / 60, -maxAngle, maxAngle);
      animate(angle, target, spring(0.18, 0.85));
    },
    onEnd: unwind,
  });

  /** Simulated stir: the vortex travels diagonally while twisting, then unwinds in place. */
  const autoStir = () => {
    generation.current += 1;
    const token = generation.current;
    cx.set(90);
    cy.set(110);
    animate(cx, 170, anim.easeInOut(0.6));
    animate(cy, 190, anim.easeInOut(0.6));
    animate(angle, ctx.n("maxAngle"), anim.easeInOut(0.6));
    after(0.7, () => {
      if (token !== generation.current) return;
      animate(angle, 0, spring(0.6, 0.5));
    });
  };
  useAutoplay(ctx.isPreview, autoStir, { every: 1.8, delay: 0.2 });

  return (
    <CenterStack ctx={ctx} en="Press, then stir around" zh="按住片刻再拖动搅动">
      <div {...hold} style={{ width: ART_W, height: ART_H, flexShrink: 0, ...hold.style }}>
        <Shader
          width={ART_W}
          height={ART_H}
          fragment={FRAG}
          source={layer.canvas}
          fps={ctx.isPreview ? 30 : undefined}
          uniforms={() => {
            layer.paint((g, k) => drawArtwork(g, k, 4));
            return { u_center: [cx.get(), cy.get()], u_radius: ctx.n("radius"), u_angle: angle.get() };
          }}
        />
      </div>
    </CenterStack>
  );
}
