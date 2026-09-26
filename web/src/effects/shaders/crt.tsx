/** shader.crt · CRT 显示器 (Shaders+Stylize.swift, mlCRT) */
import { useRef } from "react";
import { Palette, fonts, useAutoplay, useHaptics, type DemoProps } from "../../kit";
import { LIB, nowSec, rgba, useLayer, useSpeedClock } from "./_shared";
import { BottomHint } from "./_stage";
import { Shader } from "./_gl";

const FRAG = `
uniform float u_t;
uniform float u_curvature;
uniform float u_scanlines;
uniform float u_bleed;
${LIB}
void main() {
  vec2 position = v_uv * u_size;
  vec2 size = u_size;
  vec2 uv = position / max(size, vec2(1.0)) * 2.0 - 1.0;
  vec2 bend = uv.yx * uv.yx * u_curvature;
  uv = uv + uv * bend;
  if (abs(uv.x) > 1.0 || abs(uv.y) > 1.0) { gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0); return; }
  vec2 p = (uv * 0.5 + 0.5) * size;
  vec4 base = S(p);
  vec4 red = S(p + vec2(u_bleed, 0.0));
  vec4 blue = S(p - vec2(u_bleed, 0.0));
  vec4 smear = S(p - vec2(u_bleed * 2.0, 0.0));
  vec4 c = vec4(red.r, base.g, blue.b, base.a);
  c.rgb = mix(c.rgb, max(c.rgb, smear.rgb), 0.35 * clamp(u_bleed / 3.0, 0.0, 1.0));
  float scan = 1.0 - u_scanlines + u_scanlines * sin(p.y * 2.4 + u_t * 10.0);
  float roll = 0.96 + 0.04 * sin((p.y / size.y - u_t * 0.35) * 6.28318);
  float vignette = 1.0 - 0.28 * dot(uv, uv);
  c.rgb *= scan * roll * vignette;
  gl_FragColor = c;
}`;

const LINES: [string, string][] = [
  ["> BOOT MOTION.LEXICON", "> 启动 MOTION.LEXICON"],
  ["> LOADING SPRINGS…  OK", "> 载入弹簧……  完成"],
  ["> LOADING SHADERS… OK", "> 载入着色器…… 完成"],
  ["> MOTIONARY READY_", "> MOTIONARY 就绪_"],
];

/** `CRTScreen`: boot lines typing in and a scrolling mint meter on a deep green phosphor. */
function drawScreen(g: CanvasRenderingContext2D, k: number, w: number, h: number, time: number, zh: boolean) {
  g.fillStyle = "#06140F";
  g.fillRect(0, 0, w, h);
  g.shadowColor = rgba(Palette.mint, 0.8);
  g.shadowBlur = 6 * k;
  g.fillStyle = Palette.mint;
  g.font = `600 14px ${fonts.mono}`;
  g.textAlign = "left";
  g.textBaseline = "middle";
  const visible = Math.floor(time * 1.2) % (LINES.length + 2);
  LINES.forEach((line, i) => {
    if (i < visible) g.fillText(line[zh ? 1 : 0], 22, 22 + 8.5 + i * (17 + 8));
  });
  const n = 12;
  const cellW = (w - 44 - 4 * (n - 1)) / n;
  for (let i = 0; i < n; i++) {
    g.fillStyle = rgba(Palette.mint, ((i + Math.floor(time * 8)) % 12) / 12);
    g.beginPath();
    g.roundRect(22 + i * (cellW + 4), h - 22 - 10, cellW, 10, 2);
    g.fill();
  }
  g.shadowBlur = 0;
  g.shadowColor = "transparent";
}

export default function CRT({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const H = ctx.isPreview ? 340 : 400;
  const w = Math.min(340 - 48, 290);
  const h = Math.min(H - 48, 320);
  const layer = useLayer(w, h);
  const clock = useSpeedClock();
  const degaussAt = useRef(-100);

  useAutoplay(ctx.isPreview, () => (degaussAt.current = nowSec()), { every: 4.0, delay: 1.5 });

  /** Curvature wobble (±1) and fringe (0…1) for a degauss; both decay over ~0.9 s. */
  const degauss = () => {
    const age = nowSec() - degaussAt.current;
    if (age < 0 || age >= 1.2) return { bend: 0, fringe: 0 };
    const envelope = Math.exp(-age * 4);
    return { bend: Math.sin(age * 22) * envelope, fringe: envelope };
  };

  return (
    <div style={{ position: "absolute", inset: 0, display: "grid", placeItems: "center" }}>
      <div
        onClick={() => {
          degaussAt.current = nowSec();
          haptics.tap("heavy");
        }}
        style={{ width: w, height: h, borderRadius: 26, overflow: "hidden", cursor: "pointer", transform: "translateZ(0)" }}
      >
        <Shader
          width={w}
          height={h}
          fragment={FRAG}
          source={layer.canvas}
          fps={ctx.isPreview ? 30 : undefined}
          uniforms={() => {
            const time = clock.advance(nowSec(), 1);
            layer.paint((g, k) => drawScreen(g, k, w, h, time, ctx.lang === "zh"));
            const wobble = degauss();
            return {
              u_t: time,
              u_curvature: ctx.n("curvature") + 0.16 * wobble.bend,
              u_scanlines: ctx.n("scanlines"),
              u_bleed: ctx.n("bleed") + 5 * wobble.fringe,
            };
          }}
        />
      </div>
      <BottomHint ctx={ctx} en="Tap to degauss" zh="点击消磁" bottom={2} />
    </div>
  );
}
