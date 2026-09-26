/** shader.dissolve · 燃烧溶解 (Shaders+Stylize.swift, mlDissolve) */
import { animate, useMotionValue } from "motion/react";
import { useRef } from "react";
import { Palette, anim, useAutoplay, useHaptics, useTimeouts, type DemoProps } from "../../kit";
import { ART_H, ART_W, LIB, drawArtwork, rgb, useLayer } from "./_shared";
import { CenterStack } from "./_stage";
import { Shader } from "./_gl";

const FRAG = `
uniform float u_progress;
uniform float u_scale;
uniform vec3 u_edge;
${LIB}
void main() {
  vec2 position = v_uv * u_size;
  vec4 color = S(position);
  if (u_progress <= 0.0001 || color.a < 0.001) { gl_FragColor = color; return; }
  float n = mlFbm(position / max(u_scale, 1.0));
  float threshold = u_progress * 1.2 - 0.1;
  float d = n - threshold;
  float alpha = smoothstep(-0.006, 0.006, d);
  if (alpha <= 0.0) { gl_FragColor = vec4(0.0); return; }
  vec3 rgb = color.rgb / color.a;
  vec3 edge = u_edge;
  float t = clamp(d / 0.1, 0.0, 1.0);
  vec3 hot = mix(vec3(1.0, 0.97, 0.84), edge, smoothstep(0.0, 0.3, t));
  vec3 burnt = mix(hot, edge * 0.28, smoothstep(0.3, 0.62, t));
  vec3 outColor = mix(burnt, rgb, smoothstep(0.55, 1.0, t));
  float a = color.a * alpha;
  gl_FragColor = vec4(outColor * a, a);
}`;

export default function Dissolve({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const layer = useLayer(ART_W, ART_H);
  const progress = useMotionValue(0);
  const gone = useRef(false);
  const generation = useRef(0);
  const { after } = useTimeouts();
  const edge = ctx.i("edge") === 1 ? Palette.violet : ctx.i("edge") === 2 ? Palette.sky : "#FF8A3D";

  const toggle = () => {
    generation.current += 1;
    haptics.tap("rigid");
    gone.current = !gone.current;
    animate(progress, gone.current ? 1 : 0, anim.easeInOut(ctx.n("duration")));
  };

  /** Preview loop: burn away, hold ~0.3 s, then re-materialize. */
  const autoplayCycle = () => {
    const duration = ctx.n("duration");
    generation.current += 1;
    const token = generation.current;
    gone.current = true;
    animate(progress, 1, anim.easeInOut(duration));
    after(duration + 0.3, () => {
      if (token !== generation.current) return;
      gone.current = false;
      animate(progress, 0, anim.easeInOut(duration));
    });
  };
  useAutoplay(ctx.isPreview, autoplayCycle, { every: ctx.n("duration") * 2 + 1.0, delay: 0.4 });

  return (
    <CenterStack ctx={ctx} en="Tap to burn / restore" zh="点击溶解 / 复原">
      <div onClick={toggle} style={{ width: ART_W, height: ART_H, cursor: "pointer", flexShrink: 0 }}>
        <Shader
          width={ART_W}
          height={ART_H}
          fragment={FRAG}
          source={layer.canvas}
          fps={ctx.isPreview ? 30 : undefined}
          uniforms={() => {
            layer.paint((g, k) => drawArtwork(g, k, 3));
            return { u_progress: progress.get(), u_scale: ctx.n("scale"), u_edge: rgb(edge) };
          }}
        />
      </div>
    </CenterStack>
  );
}
