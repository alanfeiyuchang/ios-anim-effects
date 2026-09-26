/** shader.ripple · 触点涟漪 (Shaders+Distortion.swift, mlRipple) */
import { useRef } from "react";
import { localPoint, useAutoplay, useHaptics, type DemoProps } from "../../kit";
import { ART_H, ART_W, LIB, drawArtwork, nowSec, randIn, useLayer } from "./_shared";
import { CenterStack } from "./_stage";
import { Shader } from "./_gl";

const FRAG = `
uniform vec2 u_origin;
uniform float u_t;
uniform float u_on;
uniform float u_amplitude;
uniform float u_frequency;
uniform float u_decay;
uniform float u_speed;
${LIB}
void main() {
  vec2 position = v_uv * u_size;
  if (u_on < 0.5) { gl_FragColor = S(position); return; }
  float distance = length(position - u_origin);
  float delay = distance / u_speed;
  float t = max(0.0, u_t - delay);
  float rippleAmount = u_amplitude * sin(u_frequency * t) * exp(-u_decay * t);
  vec2 direction = distance > 0.0001 ? (position - u_origin) / distance : vec2(0.0);
  vec2 newPosition = position + rippleAmount * direction;
  vec4 color = S(newPosition);
  color.rgb += 0.3 * (rippleAmount / max(u_amplitude, 0.0001)) * color.a;
  gl_FragColor = color;
}`;

export default function Ripple({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const layer = useLayer(ART_W, ART_H);
  const wave = useRef({ origin: { x: 130, y: 150 }, start: -1 });

  const trigger = (x: number, y: number) => {
    wave.current = { origin: { x, y }, start: nowSec() };
  };
  useAutoplay(ctx.isPreview, () => trigger(randIn(60, 200), randIn(70, 230)), { every: 2.2, delay: 0.3 });

  return (
    <CenterStack ctx={ctx} en="Tap anywhere on the card" zh="点击卡片任意位置">
      <div
        onClick={(e) => {
          const p = localPoint(e, e.currentTarget);
          trigger(p.x, p.y);
          haptics.tap("soft");
        }}
        style={{ width: ART_W, height: ART_H, cursor: "pointer", flexShrink: 0 }}
      >
        <Shader
          width={ART_W}
          height={ART_H}
          fragment={FRAG}
          source={layer.canvas}
          fps={ctx.isPreview ? 30 : undefined}
          uniforms={() => {
            layer.paint((g, k) => drawArtwork(g, k, 2));
            const amplitude = ctx.n("amplitude");
            const speed = ctx.n("speed");
            const decay = ctx.n("decay");
            const { origin, start } = wave.current;
            // Wave reaches the farthest corner of the card, then decays to 1 % (e^-4.6).
            const far = Math.max(...[[0, 0], [ART_W, 0], [0, ART_H], [ART_W, ART_H]].map(([x, y]) => Math.hypot(x - origin.x, y - origin.y)));
            const duration = far / Math.max(speed, 1) + 4.6 / Math.max(decay, 0.5);
            const elapsed = start < 0 ? 0 : Math.min(nowSec() - start, duration);
            return {
              u_origin: [origin.x, origin.y],
              u_t: elapsed,
              u_on: elapsed > 0 && elapsed < duration ? 1 : 0,
              u_amplitude: amplitude,
              u_frequency: ctx.n("frequency"),
              u_decay: decay,
              u_speed: speed,
            };
          }}
        />
      </div>
    </CenterStack>
  );
}
