/** shader.glitch · RGB 故障 (Shaders+Stylize.swift, mlGlitch) */
import { useRef } from "react";
import { Palette, fonts, useAutoplay, useHaptics, type DemoProps } from "../../kit";
import { LIB, nowSec, useLayer, useSpeedClock } from "./_shared";
import { CenterStack } from "./_stage";
import { Shader } from "./_gl";

const SIZE = 260;

const FRAG = `
uniform float u_t;
uniform float u_intensity;
uniform float u_split;
uniform float u_block;
uniform float u_rate;
${LIB}
void main() {
  vec2 position = v_uv * u_size;
  float s = max(u_block, 4.0);
  vec2 cell = floor(position / s);
  float frame = floor(u_t * max(u_rate, 0.5));
  vec2 region = floor(cell / vec2(4.0, 2.0));
  float hit = step(1.0 - (0.04 + 0.22 * u_intensity), mlHash(region + vec2(frame * 0.713, frame * 0.291)));
  float h1 = mlHash(cell + vec2(frame * 1.37, 3.1));
  float h2 = mlHash(cell * 1.91 + vec2(7.7, frame * 0.53));
  vec2 p = position;
  if (hit > 0.5) {
    if (h1 < 0.55) {
      vec2 jump = floor(vec2(h1 / 0.55, h2) * 5.0) - 2.0;
      p += jump * s * 0.5;
    } else {
      p.y = cell.y * s + 0.5;
    }
  }
  float offset = u_split * (0.35 + u_intensity * 1.3);
  vec2 chroma = vec2(offset, offset * 0.5 * hit);
  vec4 base = S(p);
  vec4 red = S(p + chroma);
  vec4 blue = S(p - chroma);
  vec4 color = vec4(red.r, base.g, blue.b, max(base.a, max(red.a, blue.a)));
  if (hit > 0.5 && h2 > 0.7) {
    color.rgb = color.gbr;
  }
  float posterize = smoothstep(0.75, 1.0, u_intensity);
  if (posterize > 0.0 && color.a > 0.001) {
    vec3 rgb = color.rgb / color.a;
    vec3 stepped = floor(rgb * 3.0 + 0.5) / 3.0;
    color.rgb = mix(rgb, stepped, posterize) * color.a;
  }
  gl_FragColor = color;
}`;

/** `GlitchCard`: 260 × 260 ink card with "SYSTEM://", "NEON / DRIFT" and five spectrum capsules. */
function drawCard(g: CanvasRenderingContext2D) {
  g.fillStyle = "#0E0F1A";
  g.beginPath();
  g.roundRect(0, 0, SIZE, SIZE, 28);
  g.fill();
  // VStack(alignment: .leading, spacing: 10) centred vertically, padding 26:
  // 14 pt mono line (17) + two 54 pt lines at 58 pt pitch (64 + 58) + 6 pt capsules → 165 pt tall.
  const top = (SIZE - 165) / 2;
  g.textAlign = "left";
  g.textBaseline = "middle";
  g.fillStyle = Palette.mint;
  g.font = `700 14px ${fonts.mono}`;
  g.fillText("SYSTEM://", 26, top + 9);
  g.fillStyle = "#fff";
  g.font = `900 54px ${fonts.rounded}`;
  g.fillText("NEON", 24, top + 27 + 33);
  g.fillText("DRIFT", 24, top + 27 + 33 + 58);
  const y = top + 27 + 122 + 10;
  for (let i = 0; i < 5; i++) {
    g.fillStyle = Palette.spectrum[i];
    g.beginPath();
    g.roundRect(26 + i * 34, y, 28, 6, 3);
    g.fill();
  }
}

export default function Glitch({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const layer = useLayer(SIZE, SIZE);
  const clock = useSpeedClock();
  const burstUntil = useRef(0);

  const triggerBurst = () => {
    haptics.tap("heavy");
    burstUntil.current = nowSec() + 0.4;
  };
  useAutoplay(ctx.isPreview, triggerBurst, { every: 2.4, delay: 0.4 });

  return (
    <CenterStack ctx={ctx} en="Tap for a glitch burst" zh="点击触发强烈故障">
      <div onClick={triggerBurst} style={{ width: SIZE, height: SIZE, cursor: "pointer", flexShrink: 0 }}>
        <Shader
          width={SIZE}
          height={SIZE}
          fragment={FRAG}
          source={layer.canvas}
          fps={ctx.isPreview ? 30 : undefined}
          uniforms={() => {
            layer.paint((g) => drawCard(g));
            const now = nowSec();
            return {
              u_t: clock.advance(now, 1),
              u_intensity: now < burstUntil.current ? 1 : ctx.n("intensity"),
              u_split: ctx.n("split"),
              u_block: ctx.n("slice"),
              u_rate: ctx.n("rate"),
            };
          }}
        />
      </div>
    </CenterStack>
  );
}
