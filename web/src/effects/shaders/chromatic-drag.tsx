/** shader.chromatic-drag · 色散拖影 (Shaders+Optics.swift, mlChromatic) */
import { useRef } from "react";
import { clamp, useAutoplay, useHaptics, useTimeouts, type DemoProps, type Point } from "../../kit";
import { ART_H, ART_W, LIB, drawArtwork, nowSec, randIn, useLayer } from "./_shared";
import { CenterStack } from "./_stage";
import { Shader } from "./_gl";

const FRAG = `
uniform vec2 u_shift;
uniform float u_radial;
${LIB}
void main() {
  vec2 position = v_uv * u_size;
  vec2 center = u_size * 0.5;
  vec2 fromCenter = (position - center) / max(u_size.x, 1.0);
  vec2 offset = u_shift + fromCenter * u_radial;
  vec4 g = S(position);
  vec4 r = S(position + offset);
  vec4 b = S(position - offset);
  float a = max(g.a, max(r.a, b.a));
  gl_FragColor = vec4(r.r, g.g, b.b, a);
}`;

/** `ChromaticModel`: a spring-driven card position whose velocity feeds the RGB split. */
class ChromaticModel {
  target: Point = { x: 0, y: 0 };
  position: Point = { x: 0, y: 0 };
  velocity: Point = { x: 0, y: 0 };
  private last: number | null = null;
  step(now: number, response: number, damping: number) {
    const raw = this.last === null ? 0 : now - this.last;
    this.last = now;
    const dt = Math.min(Math.max(raw, 0), 1 / 20);
    if (dt <= 0) return;
    const omega = (2 * Math.PI) / Math.max(response, 0.05);
    const stiffness = omega * omega;
    const friction = 2 * damping * omega;
    const h = dt / 4;
    for (let i = 0; i < 4; i++) {
      this.velocity.x += (stiffness * (this.target.x - this.position.x) - friction * this.velocity.x) * h;
      this.velocity.y += (stiffness * (this.target.y - this.position.y) - friction * this.velocity.y) * h;
      this.position.x += this.velocity.x * h;
      this.position.y += this.velocity.y * h;
    }
  }
}

export default function ChromaticDrag({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const layer = useLayer(ART_W, ART_H);
  const model = useRef(new ChromaticModel()).current;
  const card = useRef<HTMLDivElement>(null);
  const flip = useRef(false);
  const { after } = useTimeouts();
  const drag = useRef<{ id: number; x: number; y: number; scale: number; engaged: boolean } | null>(null);

  const release = () => {
    const d = drag.current;
    drag.current = null;
    if (!d?.engaged) return;
    model.target = { x: 0, y: 0 };
    haptics.tap("soft");
  };

  /** Simulated flick: throw the card out, then let the spring pull it home. */
  const autoSwipe = () => {
    flip.current = !flip.current;
    const side = flip.current ? 1 : -1;
    model.target = { x: side * randIn(70, 100), y: randIn(-50, 50) };
    after(0.35, () => (model.target = { x: 0, y: 0 }));
  };
  useAutoplay(ctx.isPreview, autoSwipe, { every: 1.2, delay: 0.3 });

  return (
    <CenterStack ctx={ctx} en="Drag or flick the card" zh="拖动或甩动卡片" gap={12} style={{ paddingBottom: 8 }}>
      <div style={{ position: "relative", flex: 1, alignSelf: "stretch", display: "grid", placeItems: "center" }}>
        <div ref={card} style={{ width: ART_W, height: ART_H, filter: "drop-shadow(0 14px 22px rgb(164 107 255 / 0.3))", willChange: "transform" }}>
          <Shader
            width={ART_W}
            height={ART_H}
            fragment={FRAG}
            source={layer.canvas}
            fps={ctx.isPreview ? 30 : undefined}
            uniforms={() => {
              model.step(nowSec(), ctx.n("response"), 0.6);
              layer.paint((g, k) => drawArtwork(g, k, 5));
              const k = ctx.n("strength") / 60;
              const raw = { x: model.velocity.x * k, y: model.velocity.y * k };
              const length = Math.hypot(raw.x, raw.y);
              const scale = length > 18 ? 18 / length : 1;
              const tilt = clamp(model.velocity.x / 90, -8, 8);
              // The lens fringe blooms with motion too, so a card at rest is perfectly clean.
              const radial = ctx.n("fringe") * Math.min(length / 6, 1);
              if (card.current) card.current.style.transform = `translate(${model.position.x}px, ${model.position.y}px) rotate(${tilt}deg)`;
              return { u_shift: [raw.x * scale, raw.y * scale], u_radial: radial };
            }}
          />
        </div>
        {/* Hit area = the card at rest; engages after 10 pt of mostly horizontal travel. */}
        <div
          onPointerDown={(e) => {
            if (drag.current) return;
            e.currentTarget.setPointerCapture(e.pointerId);
            const el = e.currentTarget;
            drag.current = { id: e.pointerId, x: e.clientX, y: e.clientY, scale: el.getBoundingClientRect().width / el.offsetWidth || 1, engaged: false };
          }}
          onPointerMove={(e) => {
            const d = drag.current;
            if (!d || d.id !== e.pointerId) return;
            const t = { x: (e.clientX - d.x) / d.scale, y: (e.clientY - d.y) / d.scale };
            if (!d.engaged) {
              if (Math.hypot(t.x, t.y) < 10 || Math.abs(t.x) <= Math.abs(t.y)) return;
              d.engaged = true;
            }
            model.target = t;
          }}
          onPointerUp={release}
          onPointerCancel={release}
          style={{ position: "absolute", left: "50%", top: "50%", width: ART_W, height: ART_H, marginLeft: -ART_W / 2, marginTop: -ART_H / 2, touchAction: "none", cursor: "grab" }}
        />
      </div>
    </CenterStack>
  );
}
