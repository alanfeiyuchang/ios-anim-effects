/** shader.vhs · VHS 录像带 (Shaders+RetroTape.swift, mlVHS) */
import { useRef } from "react";
import { fonts, useAutoplay, useHaptics, type DemoProps } from "../../kit";
import { ART_H, ART_W, LIB, drawArtwork, nowSec, useLayer, useSpeedClock } from "./_shared";
import { CenterStack } from "./_stage";
import { Shader } from "./_gl";

const FRAG = `
uniform float u_t;
uniform float u_tracking;
uniform float u_wobble;
uniform float u_chroma;
${LIB}
void main() {
  vec2 position = v_uv * u_size;
  vec2 size = u_size;
  float time = u_t;
  float y = position.y;
  float dx = (mlNoise(vec2(y * 0.35, time * 18.0)) - 0.5) * u_wobble;
  float bandY = fract(time * 0.13) * (size.y + 80.0) - 40.0;
  float bw = 10.0 + 30.0 * u_tracking;
  float bd = (y - bandY) / bw;
  float inBand = exp(-bd * bd);
  float tear = mlHash(vec2(floor(y * 0.5), floor(fract(time) * 30.0))) - 0.5;
  dx += inBand * u_tracking * tear * 40.0;
  float head = smoothstep(size.y - 14.0, size.y, y);
  dx += head * 12.0 * sin(y * 0.9 + time * 40.0);
  vec2 p = position + vec2(dx, 0.0);
  vec4 base = S(p);
  vec4 cr = S(p + vec2(u_chroma, 0.0));
  vec4 cb = S(p + vec2(u_chroma * 2.0, 0.0));
  vec3 weights = vec3(0.299, 0.587, 0.114);
  float luma = dot(base.rgb, weights);
  vec3 shifted = vec3(cr.r, base.g, cb.b);
  vec3 col = shifted + (luma - dot(shifted, weights));
  vec2 snowSeed = position * 0.7 + vec2(fract(time * 7.3) * 100.0, fract(time * 3.1) * 100.0);
  float snow = mlHash(snowSeed);
  col = mix(col, vec3(snow), inBand * u_tracking * 0.55 * base.a);
  col *= 0.94 + 0.06 * sin(y * 3.14159);
  col = clamp(col, vec3(0.0), vec3(base.a));
  gl_FragColor = vec4(col, base.a);
}`;

const pad2 = (n: number) => String(n).padStart(2, "0");
function timecode(time: number) {
  const total = Math.floor(time) + 754;
  return `SP 0:${pad2(Math.floor(total / 60) % 60)}:${pad2(total % 60)}`;
}

/** `VHSFrame`: artwork plus the on-screen display. */
function drawFrame(g: CanvasRenderingContext2D, k: number, time: number, lost: boolean) {
  drawArtwork(g, k, 7);
  g.save();
  g.font = `700 15px ${fonts.mono}`;
  g.textAlign = "left";
  g.textBaseline = "middle";
  g.shadowColor = "rgba(0,0,0,0.5)";
  g.shadowOffsetX = k;
  g.shadowOffsetY = k;
  g.fillStyle = "#fff";
  g.fillText(lost ? "TRACKING" : "▶ PLAY", 20, 20 + 9);
  g.fillText(timecode(time), 20, ART_H - 20 - 9);
  g.restore();
}

export default function VHS({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const layer = useLayer(ART_W, ART_H);
  const clock = useSpeedClock();
  const burstStart = useRef(-100);

  const loseTracking = () => {
    haptics.tap("heavy");
    burstStart.current = nowSec();
  };
  useAutoplay(ctx.isPreview, loseTracking, { every: 3.2, delay: 0.8 });

  /** (1 − Δt/1.2)² for 1.2 s after a tap, else 0. */
  const burst = () => {
    const elapsed = nowSec() - burstStart.current;
    if (elapsed < 0 || elapsed >= 1.2) return 0;
    const k = 1 - elapsed / 1.2;
    return k * k;
  };

  return (
    <CenterStack ctx={ctx} en="Tap to lose tracking" zh="点击让画面失去跟踪">
      <div onClick={loseTracking} style={{ width: ART_W, height: ART_H, flexShrink: 0, borderRadius: 30, overflow: "hidden", cursor: "pointer", transform: "translateZ(0)" }}>
        <Shader
          width={ART_W}
          height={ART_H}
          fragment={FRAG}
          source={layer.canvas}
          fps={ctx.isPreview ? 30 : undefined}
          uniforms={() => {
            const time = clock.advance(nowSec(), 1);
            const b = burst();
            layer.paint((g, k) => drawFrame(g, k, time, b > 0.05));
            return { u_t: time, u_tracking: Math.min(1, ctx.n("tracking") + b), u_wobble: ctx.n("wobble"), u_chroma: ctx.n("chroma") };
          }}
        />
      </div>
    </CenterStack>
  );
}
