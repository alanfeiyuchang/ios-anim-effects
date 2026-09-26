/** shader.edge-scan · 霓虹边缘扫描 (Shaders+Optics.swift, mlEdgeScan) */
import { animate, motion, useMotionValue, useTransform } from "motion/react";
import { useRef } from "react";
import { Palette, anim, useAutoplay, useHaptics, useTimeouts, type DemoProps } from "../../kit";
import { ART_H, ART_W, LIB, drawArtwork, rgb, rgba, useLayer } from "./_shared";
import { CenterStack } from "./_stage";
import { Shader } from "./_gl";

const FRAG = `
uniform float u_scanY;
uniform float u_band;
uniform vec3 u_tint;
uniform float u_strength;
uniform float u_on;
${LIB}
float mlLuma(vec4 c) { return dot(c.rgb, vec3(0.299, 0.587, 0.114)); }
void main() {
  vec2 position = v_uv * u_size;
  vec4 base = S(position);
  if (u_on < 0.5) { gl_FragColor = base; return; }
  float s = 1.5;
  float tl = mlLuma(S(position + vec2(-s, -s)));
  float tc = mlLuma(S(position + vec2(0.0, -s)));
  float tr = mlLuma(S(position + vec2(s, -s)));
  float ml = mlLuma(S(position + vec2(-s, 0.0)));
  float mr = mlLuma(S(position + vec2(s, 0.0)));
  float bl = mlLuma(S(position + vec2(-s, s)));
  float bc = mlLuma(S(position + vec2(0.0, s)));
  float br = mlLuma(S(position + vec2(s, s)));
  float gx = (tr + 2.0 * mr + br) - (tl + 2.0 * ml + bl);
  float gy = (bl + 2.0 * bc + br) - (tl + 2.0 * tc + tr);
  float e = clamp(length(vec2(gx, gy)) * u_strength, 0.0, 1.0);
  vec4 dark = vec4(0.03, 0.04, 0.09, 1.0) * base.a;
  vec4 neon = dark + base * 0.08 + vec4(u_tint, 1.0) * e * base.a;
  float d = u_scanY - position.y;
  float reveal = smoothstep(-1.0, 1.0, d);
  float glow = exp(-abs(d) / max(u_band, 1.0));
  vec4 color = mix(base, neon, reveal);
  color += vec4(u_tint, 1.0) * (glow * 0.85) * base.a;
  color = min(color, vec4(1.0));
  color.rgb = min(color.rgb, vec3(color.a));
  gl_FragColor = color;
}`;

export default function EdgeScan({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const layer = useLayer(ART_W, ART_H);
  const band = ctx.n("band");
  /** 0 = parked above the card, 1 = parked below it (the animated `scanned` state). */
  const progress = useMotionValue(0);
  const scanned = useRef(false);
  const generation = useRef(0);
  const { after } = useTimeouts();
  const tint = ctx.i("tint") === 1 ? Palette.mint : ctx.i("tint") === 2 ? Palette.pink : "#4FE3FF";
  // Rest positions sit 3 glow-heights beyond the 300 pt card, where the glow is < 5 %.
  const restTop = -3 * band;
  const restBottom = 300 + 3 * band;

  const go = (on: boolean) => {
    scanned.current = on;
    animate(progress, on ? 1 : 0, anim.easeInOut(ctx.n("duration")));
  };
  const sweep = () => {
    generation.current += 1;
    haptics.tap("rigid");
    go(!scanned.current);
  };
  /** Autoplay / arrival intro: scan down, hold the wireframe briefly, then sweep back up. */
  const scanAndRestore = () => {
    const duration = ctx.n("duration");
    generation.current += 1;
    const token = generation.current;
    go(true);
    after(duration + 0.6, () => token === generation.current && go(false));
  };
  useAutoplay(ctx.isPreview, scanAndRestore, { every: ctx.n("duration") * 2 + 1.6, delay: 0.4 });

  const shadow = useTransform(progress, (p) => `drop-shadow(0 10px 22px ${rgba(tint, 0.15 + 0.3 * p)})`);

  return (
    <CenterStack ctx={ctx} en="Tap to scan / restore" zh="点击扫描 / 还原">
      <motion.div onClick={sweep} style={{ width: ART_W, height: ART_H, cursor: "pointer", flexShrink: 0, filter: shadow }}>
        <Shader
          width={ART_W}
          height={ART_H}
          fragment={FRAG}
          source={layer.canvas}
          fps={ctx.isPreview ? 30 : undefined}
          uniforms={() => {
            layer.paint((g, k) => drawArtwork(g, k, 6));
            const scanY = restTop + (restBottom - restTop) * progress.get();
            return { u_scanY: scanY, u_band: band, u_tint: rgb(tint), u_strength: 3.2, u_on: scanY > restTop + 1 ? 1 : 0 };
          }}
        />
      </motion.div>
    </CenterStack>
  );
}
