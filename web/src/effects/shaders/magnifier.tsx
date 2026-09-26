/** shader.magnifier · 球面折射透镜 (Shaders+Distortion.swift, mlGlassLens) */
import { animate, motion, useMotionValue, useTransform } from "motion/react";
import { useRef } from "react";
import { spring, useAutoplay, useHaptics, useTimeouts, type DemoProps, type Point } from "../../kit";
import { LIB, drawGridArtwork, randIn, useHoldDrag, useLayer } from "./_shared";
import { BottomHint } from "./_stage";
import { Shader } from "./_gl";

const FRAG = `
uniform vec2 u_center;
uniform float u_radius;
uniform float u_magnify;
uniform float u_dispersion;
${LIB}
void main() {
  vec2 position = v_uv * u_size;
  vec4 outside = S(position);
  vec2 d = position - u_center;
  float dist = length(d);
  float rad = max(u_radius, 1.0);
  if (dist >= rad) { gl_FragColor = outside; return; }
  float t = dist / rad;
  float z = sqrt(max(1.0 - t * t, 0.0));
  vec2 dir = dist > 0.001 ? d / dist : vec2(0.0);
  float core = dist * mix(1.0 - u_magnify, 1.0, t * t);
  float rim = (1.0 - z) * rad * 0.28;
  float spread = u_dispersion * (1.0 - z);
  vec4 g = S(u_center + dir * (core - rim));
  vec4 r = S(u_center + dir * (core - rim * (1.0 - spread)));
  vec4 b = S(u_center + dir * (core - rim * (1.0 + spread)));
  vec4 lens = vec4(r.r, g.g, b.b, max(g.a, max(r.a, b.a)));
  vec3 normal = normalize(vec3(d / rad, z));
  vec3 light = normalize(vec3(-0.45, -0.6, 0.66));
  float spec = pow(max(dot(normal, light), 0.0), 36.0);
  float shade = 0.9 + 0.1 * z;
  lens.rgb = lens.rgb * shade + spec * 0.75 * lens.a;
  lens = min(lens, vec4(1.0));
  lens.rgb = min(lens.rgb, vec3(lens.a));
  float blend = smoothstep(rad - 1.2, rad, dist);
  gl_FragColor = mix(lens, outside, blend);
}`;

export default function Magnifier({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const W = 340;
  const H = ctx.isPreview ? 340 : 400;
  const home = { x: W / 2, y: H / 2 };
  const layer = useLayer(W, H);
  const cx = useMotionValue(home.x);
  const cy = useMotionValue(home.y);
  const grab = useRef<Point | null>(null);
  const { after } = useTimeouts();
  const radius = ctx.n("radius");

  const moveTo = (p: Point, t: ReturnType<typeof spring>) => {
    animate(cx, p.x, t);
    animate(cy, p.y, t);
  };
  const release = () => {
    if (!grab.current) return;
    grab.current = null;
    moveTo(home, spring(0.45, 0.7));
  };
  /** Stage position of the lens handle's origin at touch-down (the handle moves with the lens). */
  const startOrigin = useRef<Point>({ x: 0, y: 0 });
  const hold = useHoldDrag(0.1, {
    onArm: () => {
      startOrigin.current = { x: cx.get() - radius, y: cy.get() - radius };
    },
    onDrag: ({ start, location }) => {
      const o = startOrigin.current;
      if (!grab.current) {
        // Grabbing the lens keeps the finger's offset, so it never jumps under the finger.
        const dx = cx.get() - (start.x + o.x);
        const dy = cy.get() - (start.y + o.y);
        grab.current = Math.hypot(dx, dy) <= radius ? { x: dx, y: dy } : { x: 0, y: 0 };
        haptics.tap("soft");
      }
      const target = {
        x: Math.min(Math.max(location.x + o.x + grab.current.x, 0), W),
        y: Math.min(Math.max(location.y + o.y + grab.current.y, 0), H),
      };
      moveTo(target, spring(0.18, 0.86));
    },
    onEnd: release,
  });
  /** Simulated drag: glide to a spot over the text, then spring home. */
  const glide = () => {
    const spot = { x: home.x + randIn(-90, 90), y: home.y + (Math.random() < 0.5 ? -40 : 30) };
    moveTo(spot, spring(0.7, 0.78));
    after(0.9, () => {
      if (grab.current) return;
      moveTo(home, spring(0.45, 0.7));
    });
  };
  useAutoplay(ctx.isPreview, glide, { every: 1.8, delay: 0.3 });

  const left = useTransform(cx, (x) => x - radius);
  const top = useTransform(cy, (y) => y - radius);

  return (
    <div style={{ position: "absolute", inset: 0 }}>
      <Shader
        width={W}
        height={H}
        fragment={FRAG}
        source={layer.canvas}
        fps={ctx.isPreview ? 30 : undefined}
        uniforms={() => {
          layer.paint((g) => drawGridArtwork(g, W, H));
          return { u_center: [cx.get(), cy.get()], u_radius: radius, u_magnify: ctx.n("strength"), u_dispersion: ctx.n("dispersion") };
        }}
      />
      <motion.div style={{ position: "absolute", left, top, width: radius * 2, height: radius * 2, pointerEvents: "none" }}>
        <svg width={radius * 2} height={radius * 2} style={{ overflow: "visible", filter: "drop-shadow(0 8px 12px rgb(0 0 0 / 0.35))" }}>
          <defs>
            <linearGradient id="ml-magnifier-rim" x1="0" y1="0" x2="1" y2="1">
              <stop offset="0" stopColor="#fff" stopOpacity={0.75} />
              <stop offset="0.5" stopColor="#fff" stopOpacity={0.1} />
              <stop offset="1" stopColor="#fff" stopOpacity={0.4} />
            </linearGradient>
          </defs>
          <circle cx={radius} cy={radius} r={radius - 0.5} fill="none" stroke="url(#ml-magnifier-rim)" strokeWidth={1} />
        </svg>
      </motion.div>
      <motion.div
        {...hold}
        style={{ position: "absolute", left, top, width: radius * 2, height: radius * 2, borderRadius: "50%", cursor: "grab", touchAction: "none" }}
      />
      <BottomHint ctx={ctx} en="Press the lens, then drag" zh="按住透镜片刻再拖动" bottom={14} dark />
    </div>
  );
}
