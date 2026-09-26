/** shader.liquid-wipe · 液面擦除 (Shaders+WipeTransitions.swift, mlLiquidWipe) */
import { animate, useMotionValue } from "motion/react";
import { useRef } from "react";
import { anim, useAutoplay, useHaptics, type DemoProps } from "../../kit";
import { ART_H, ART_W, LIB, LayerView, drawArtwork, nowSec, swapVariant, useLayer, useSpeedClock } from "./_shared";
import { CenterStack } from "./_stage";
import { Shader } from "./_gl";

const FRAG = `
uniform float u_progress;
uniform float u_amplitude;
uniform float u_t;
${LIB}
void main() {
  vec2 position = v_uv * u_size;
  vec2 size = u_size;
  if (u_progress <= 0.0001) { gl_FragColor = S(position); return; }
  float pr = clamp(u_progress, 0.0, 1.0);
  float a = u_amplitude * sin(3.14159265 * pr);
  float span = size.y + u_amplitude * 4.0;
  float level = size.y + u_amplitude * 2.0 - pr * span;
  float wave = sin(position.x * 0.034 + u_t * 4.2) * a
             + sin(position.x * 0.079 - u_t * 2.7) * a * 0.45;
  float d = position.y - (level + wave);
  float above = max(-d, 0.0);
  float lens = exp(-above / 16.0);
  vec2 p = position - vec2(0.0, lens * a * 0.9);
  vec4 c = S(p);
  float keep = 1.0 - smoothstep(-0.8, 0.8, d);
  c *= keep;
  float mask = S(position).a;
  float live = smoothstep(0.0, 0.08, pr) * (1.0 - smoothstep(0.92, 1.0, pr));
  float rim = exp(-abs(d) / 2.2) * mask * live;
  c += vec4(vec3(rim * 0.9), rim * 0.9);
  c = min(c, vec4(1.0));
  c.rgb = min(c.rgb, vec3(c.a));
  gl_FragColor = c;
}`;

export default function LiquidWipe({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const top = useLayer(ART_W, ART_H);
  const bottom = useLayer(ART_W, ART_H);
  const clock = useSpeedClock();
  const currentRef = useRef(0);
  const progress = useMotionValue(0);
  const busy = useRef(false);

  const advance = () => {
    if (busy.current) return;
    busy.current = true;
    haptics.tap("soft");
    animate(progress, 1, {
      ...anim.easeInOut(ctx.n("duration")),
      onComplete: () => {
        // Swap the scenes without animation, ready for the next tap.
        currentRef.current += 1;
        progress.set(0);
        busy.current = false;
      },
    });
  };
  useAutoplay(ctx.isPreview, advance, { every: ctx.n("duration") + 1.0, delay: 0.4 });

  return (
    <CenterStack ctx={ctx} en="Tap to flood the card" zh="点击让卡片“进水”">
      <div onClick={advance} style={{ position: "relative", width: ART_W, height: ART_H, flexShrink: 0, cursor: "pointer" }}>
        <LayerView layer={bottom} width={ART_W} height={ART_H} style={{ position: "absolute", inset: 0 }} />
        <Shader
          width={ART_W}
          height={ART_H}
          fragment={FRAG}
          source={top.canvas}
          fps={ctx.isPreview ? 30 : undefined}
          style={{ position: "absolute", inset: 0 }}
          uniforms={() => {
            const c = currentRef.current;
            top.paint((g, k) => drawArtwork(g, k, swapVariant(c)));
            bottom.paint((g, k) => drawArtwork(g, k, swapVariant(c + 1)));
            // The waves only move while the wipe runs (the clock is paused at rest).
            const t = clock.advance(nowSec(), busy.current ? 1 : 0);
            return { u_progress: progress.get(), u_amplitude: ctx.n("amplitude"), u_t: t };
          }}
        />
      </div>
    </CenterStack>
  );
}
