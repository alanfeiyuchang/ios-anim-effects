/** shader.tunnel · 超空间隧道 (Shaders+CellsTunnel.swift, mlTunnel) */
import { useRef } from "react";
import { fonts, glass, useHaptics, type DemoProps, type Point } from "../../kit";
import { SpeedClock, nowSec, useStageTouch } from "./_shared";
import { BottomHint } from "./_stage";
import { Shader } from "./_gl";

const FRAG = `
uniform float u_t;
uniform vec2 u_center;
uniform float u_twist;
uniform float u_lanes;
void main() {
  vec2 position = v_uv * u_size;
  vec2 d = (position - u_center) / max(u_size.y, 1.0);
  float r = max(length(d), 0.0001);
  float a = atan(d.y, d.x) / 6.2831853;
  float z = 0.28 / r + u_t;
  float u = a + u_twist * 0.05 * z;
  float n = max(floor(u_lanes), 3.0);
  float gu = fract(u * n);
  float gz = fract(z * 1.5);
  float lu = 1.0 - smoothstep(0.0, 0.07, min(gu, 1.0 - gu));
  float lz = 1.0 - smoothstep(0.0, 0.07, min(gz, 1.0 - gz));
  float line = max(lu, lz);
  vec3 hue = 0.5 + 0.5 * cos(6.2831853 * (z * 0.06 + vec3(0.0, 0.33, 0.67)));
  float fog = smoothstep(0.015, 0.22, r);
  vec3 col = vec3(0.02, 0.015, 0.06);
  col += hue * line * fog * 1.1;
  col += hue * 0.12 * fog;
  col += vec3(0.9, 0.85, 1.0) * exp(-r * 9.0) * 0.9;
  col = clamp(col, vec3(0.0), vec3(1.0));
  gl_FragColor = vec4(col, 1.0);
}`;

/** `TunnelModel`: warp-scaled time, a vanishing point easing toward the touch, and the warp factor itself. */
class TunnelModel {
  clock = new SpeedClock();
  touch: Point | null = null;
  pressing = false;
  center: Point | null = null;
  warp = 1;
  step(now: number, speed: number, w: number, h: number, preview: boolean) {
    const t = this.clock.advance(now, speed * this.warp);
    const home = { x: w / 2, y: h / 2 };
    let target = home;
    if (this.touch) target = this.touch;
    else if (preview) target = { x: home.x + 60 * Math.cos(now * 0.7), y: home.y + 40 * Math.sin(now * 0.9) };
    const current = this.center ?? home;
    const k = this.clock.follow(5);
    this.center = { x: current.x + (target.x - current.x) * k, y: current.y + (target.y - current.y) * k };
    const goal = this.touch || this.pressing ? 3.2 : 1;
    this.warp += (goal - this.warp) * this.clock.follow(2.5);
    return { time: t, center: this.center, warp: this.warp };
  }
}

export default function Tunnel({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const H = ctx.isPreview ? 340 : 400;
  const model = useRef(new TunnelModel()).current;
  const label = useRef<HTMLSpanElement>(null);
  const press = useRef<{ token: number; down: { x: number; y: number } | null }>({ token: 0, down: null });

  const touch = useStageTouch(
    (p) => (model.touch = p),
    () => (model.touch = null),
  );
  // A long press that never completes: `pressing` while the finger stays within 10 pt; warp and the haptic wait
  // for a 150 ms still hold.
  const setPressing = (pressing: boolean) => {
    press.current.token += 1;
    if (!pressing) {
      model.pressing = false;
      return;
    }
    const token = press.current.token;
    window.setTimeout(() => {
      if (token !== press.current.token || model.pressing) return;
      model.pressing = true;
      haptics.tap("medium");
    }, 150);
  };

  return (
    <div
      {...touch}
      onPointerDown={(e) => {
        touch.onPointerDown(e);
        press.current.down = { x: e.clientX, y: e.clientY };
        setPressing(true);
      }}
      onPointerMove={(e) => {
        touch.onPointerMove(e);
        const d = press.current.down;
        const scale = e.currentTarget.getBoundingClientRect().width / e.currentTarget.offsetWidth || 1;
        if (d && Math.hypot(e.clientX - d.x, e.clientY - d.y) / scale > 10) {
          press.current.down = null;
          setPressing(false);
        }
      }}
      onPointerUp={(e) => {
        touch.onPointerUp(e);
        if (press.current.down) {
          press.current.down = null;
          setPressing(false);
        }
      }}
      onPointerCancel={(e) => {
        touch.onPointerCancel(e);
        press.current.down = null;
        setPressing(false);
      }}
      style={{ position: "absolute", inset: 0, ...touch.style }}
    >
      <Shader
        width={340}
        height={H}
        fragment={FRAG}
        fps={ctx.isPreview ? 30 : undefined}
        scale={2}
        uniforms={() => {
          const s = model.step(nowSec(), ctx.n("speed"), 340, H, ctx.isPreview);
          if (label.current) label.current.textContent = `WARP ×${s.warp.toFixed(1)}`;
          return { u_t: s.time, u_center: [s.center.x, s.center.y], u_twist: ctx.n("twist"), u_lanes: ctx.n("lanes") };
        }}
      />
      <div style={{ position: "absolute", top: 16, left: 0, right: 0, display: "flex", justifyContent: "center", pointerEvents: "none" }}>
        <span
          ref={label}
          style={{
            fontFamily: fonts.mono,
            fontSize: 13,
            fontWeight: 700,
            lineHeight: "16px",
            fontVariantNumeric: "tabular-nums",
            color: "#fff",
            padding: "6px 12px",
            borderRadius: 999,
            ...glass("ultraThin", "dark"),
          }}
        >
          WARP ×1.0
        </span>
      </div>
      <BottomHint ctx={ctx} en="Hold to warp · drag sideways to steer at warp" zh="按住进入曲速 · 横向拖动边加速边转向" bottom={14} dark />
    </div>
  );
}
