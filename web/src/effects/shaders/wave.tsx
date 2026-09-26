/** shader.wave · 旗帜波动 (Shaders+Distortion.swift, mlFlagWave) */
import { animate, useMotionValue } from "motion/react";
import { useRef } from "react";
import { spring, type DemoProps } from "../../kit";
import { LIB, drawArtwork, nowSec, useLayer, useSpeedClock, useStageTouch } from "./_shared";
import { BottomHint } from "./_stage";
import { Shader } from "./_gl";

const W = 300;
const H = 340;

const FRAG = `
uniform float u_t;
uniform float u_amplitude;
uniform float u_wavelength;
uniform float u_shade;
${LIB}
void main() {
  vec2 position = v_uv * u_size;
  float wl = max(u_wavelength, 1.0);
  float phaseX = u_t + position.x / wl;
  float phaseY = u_t * 0.8 + position.y / wl;
  vec2 p = position + vec2(cos(phaseY) * u_amplitude * 0.5, sin(phaseX) * u_amplitude);
  vec4 c = S(p);
  float slope = cos(phaseX) * u_amplitude / wl;
  float light = clamp(1.0 + u_shade * slope * 2.2, 0.55, 1.45);
  c.rgb = min(c.rgb * light, vec3(c.a));
  gl_FragColor = c;
}`;

export default function Wave({ ctx }: DemoProps) {
  const layer = useLayer(W, H);
  const clock = useSpeedClock();
  /** Extra amplitude factor from a sideways drag ("wind"), sprung back to 0 on release. */
  const gust = useMotionValue(0);
  const dragStartX = useRef<number | null>(null);

  const touch = useStageTouch(
    (p) => {
      const start = dragStartX.current ?? p.x;
      dragStartX.current = start;
      gust.stop();
      gust.set(Math.min(Math.abs(p.x - start) / 80, 1.5));
    },
    () => {
      dragStartX.current = null;
      animate(gust, 0, spring(0.8, 0.35));
    },
  );

  return (
    <div {...touch} style={{ position: "absolute", inset: 0, display: "grid", placeItems: "center", ...touch.style }}>
      <Shader
        width={W}
        height={H}
        fragment={FRAG}
        source={layer.canvas}
        fps={ctx.isPreview ? 30 : undefined}
        uniforms={() => {
          layer.paint((g, k) => drawArtwork(g, k, 7, 20, 20));
          return {
            u_t: clock.advance(nowSec(), ctx.n("speed")),
            u_amplitude: ctx.n("amplitude") * (1 + gust.get()),
            u_wavelength: ctx.n("wavelength"),
            u_shade: ctx.n("shade"),
          };
        }}
      />
      <BottomHint ctx={ctx} en="Drag sideways to blow wind" zh="横向拖动吹起风" bottom={4} />
    </div>
  );
}
