/** shader.plasma · 等离子场 (Shaders+Stylize.swift, mlPlasma) */
import { useRef } from "react";
import { fonts, glass, textStyle, useAutoplay, useHaptics, type DemoProps } from "../../kit";
import { nowSec, useSpeedClock } from "./_shared";
import { BottomHint } from "./_stage";
import { Shader } from "./_gl";

const FRAG = `
uniform float u_t;
uniform float u_scale;
uniform float u_palette;
uniform float u_flash;
vec3 mlPlasmaRamp(float t) {
  vec3 cyan = vec3(0.16, 0.86, 1.0);
  vec3 violet = vec3(0.56, 0.30, 1.0);
  vec3 gold = vec3(1.0, 0.77, 0.30);
  float x = fract(t) * 3.0;
  vec3 a = x < 1.0 ? cyan : (x < 2.0 ? violet : gold);
  vec3 b = x < 1.0 ? violet : (x < 2.0 ? gold : cyan);
  return mix(a, b, smoothstep(0.0, 1.0, fract(x)));
}
void main() {
  vec2 uv = v_uv;
  float time = u_t;
  float scale = u_scale;
  float v = sin(uv.x * 6.0 * scale + time)
          + sin(uv.y * 7.0 * scale - time * 1.3)
          + sin((uv.x + uv.y) * 5.0 * scale + time * 0.7)
          + sin(length(uv - 0.5) * 12.0 * scale - time * 2.0);
  v *= 0.25;
  vec3 col = mlPlasmaRamp(v * 0.8 + time * 0.03 + u_palette);
  float shade = 0.62 + 0.38 * cos(v * 6.28318);
  shade = mix(shade, 1.0, clamp(u_flash, 0.0, 1.0) * 0.55);
  col = mix(vec3(0.05, 0.04, 0.17), col, shade);
  col = min(col * (1.0 + 0.25 * clamp(u_flash, 0.0, 1.0)), vec3(1.0));
  gl_FragColor = vec4(col, 1.0);
}`;

export default function Plasma({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const clock = useSpeedClock();
  const jump = useRef({ shifts: 0, at: 0 });
  const H = ctx.isPreview ? 340 : 400;

  const shift = () => {
    jump.current = { shifts: jump.current.shifts + 1, at: nowSec() };
  };
  useAutoplay(ctx.isPreview, shift, { every: 3.2, delay: 1.0 });

  /** The ramp moves one stop (1/3) with a cubic ease-out over 0.9 s; a flash rises in 120 ms and decays at ≈ 3.2/s. */
  const paletteJump = () => {
    const { shifts, at } = jump.current;
    if (shifts === 0) return { palette: 0, flash: 0 };
    const elapsed = Math.max(nowSec() - at, 0);
    const p = Math.min(elapsed / 0.9, 1);
    const eased = 1 - (1 - p) ** 3;
    const palette = (((shifts - 1) % 3) + eased) / 3;
    const flash = elapsed < 0.12 ? elapsed / 0.12 : Math.exp(-(elapsed - 0.12) * 3.2);
    return { palette, flash };
  };

  return (
    <div
      onClick={() => {
        haptics.tap("soft");
        shift();
      }}
      style={{ position: "absolute", inset: 0, cursor: "pointer" }}
    >
      <Shader
        width={340}
        height={H}
        fragment={FRAG}
        fps={ctx.isPreview ? 30 : undefined}
        scale={2}
        uniforms={() => {
          const j = paletteJump();
          return { u_t: clock.advance(nowSec(), ctx.n("speed")), u_scale: ctx.n("scale"), u_palette: j.palette, u_flash: j.flash };
        }}
      />
      <div style={{ position: "absolute", inset: 0, display: "grid", placeItems: "center", pointerEvents: "none" }}>
        <div
          style={{
            display: "flex",
            flexDirection: "column",
            alignItems: "center",
            gap: 6,
            padding: "18px 26px",
            borderRadius: 24,
            color: "#fff",
            ...glass("ultraThin", "dark"),
          }}
        >
          <span style={{ fontFamily: fonts.rounded, fontSize: 44, fontWeight: 800, lineHeight: "52px" }}>Pro</span>
          <span style={{ ...textStyle.subheadline, fontWeight: 600 }}>{ctx.t("Unlock every effect", "解锁全部动效")}</span>
        </div>
      </div>
      <BottomHint ctx={ctx} en="Tap to shift the palette" zh="点击切换色相" bottom={14} dark />
    </div>
  );
}
