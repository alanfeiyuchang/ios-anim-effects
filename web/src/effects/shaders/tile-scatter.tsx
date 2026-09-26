/** shader.tile-scatter · 方块散逸 (Shaders+WipeTransitions.swift, mlTileScatter) */
import { animate, useMotionValue } from "motion/react";
import { useRef } from "react";
import { anim, localPoint, useAutoplay, useHaptics, type DemoProps, type Point } from "../../kit";
import { ART_H, ART_W, LIB, LayerView, drawArtwork, randIn, swapVariant, useLayer } from "./_shared";
import { CenterStack } from "./_stage";
import { Shader } from "./_gl";

const FRAG = `
uniform vec2 u_origin;
uniform float u_progress;
uniform float u_tile;
uniform float u_spread;
${LIB}
void main() {
  vec2 position = v_uv * u_size;
  vec2 size = u_size;
  if (u_progress <= 0.0001) { gl_FragColor = S(position); return; }
  float s = max(u_tile, 4.0);
  vec2 cell = floor(position / s);
  vec2 center = (cell + 0.5) * s;
  float reach = max(length(size), 1.0);
  float delay = length(center - u_origin) / reach * u_spread;
  float local = clamp(u_progress * (1.0 + u_spread) - delay, 0.0, 1.0);
  float e = local * local * (3.0 - 2.0 * local);
  float scale = 1.0 - e;
  if (scale <= 0.002) { gl_FragColor = vec4(0.0); return; }
  float spin = (mlHash(cell + 7.1) - 0.5) * 2.4 * e * e;
  float cs = cos(spin);
  float sn = sin(spin);
  vec2 lp = position - center;
  vec2 q = vec2(cs * lp.x + sn * lp.y, -sn * lp.x + cs * lp.y) / scale;
  float hs = s * 0.5;
  if (abs(q.x) > hs || abs(q.y) > hs) { gl_FragColor = vec4(0.0); return; }
  vec4 c = S(center + q);
  float flash = smoothstep(0.0, 0.15, e) * (1.0 - smoothstep(0.15, 0.6, e));
  c.rgb = min(c.rgb + vec3(flash * 0.35) * c.a, vec3(c.a));
  c *= 1.0 - e * e;
  gl_FragColor = c;
}`;

export default function TileScatter({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const top = useLayer(ART_W, ART_H);
  const bottom = useLayer(ART_W, ART_H);
  const current = useRef(0);
  const progress = useMotionValue(0);
  const origin = useRef<Point>({ x: 130, y: 150 });
  const busy = useRef(false);

  const scatter = (from: Point) => {
    if (busy.current) return;
    busy.current = true;
    origin.current = from;
    haptics.tap("rigid");
    animate(progress, 1, {
      ...anim.easeInOut(ctx.n("duration")),
      onComplete: () => {
        current.current += 1;
        progress.set(0);
        busy.current = false;
      },
    });
  };
  useAutoplay(ctx.isPreview, () => scatter({ x: randIn(40, 220), y: randIn(40, 260) }), { every: ctx.n("duration") + 1.0, delay: 0.4 });

  return (
    <CenterStack ctx={ctx} en="Tap anywhere on the card" zh="点击卡片任意位置">
      <div onClick={(e) => scatter(localPoint(e, e.currentTarget))} style={{ position: "relative", width: ART_W, height: ART_H, flexShrink: 0, cursor: "pointer" }}>
        <LayerView layer={bottom} width={ART_W} height={ART_H} style={{ position: "absolute", inset: 0 }} />
        <Shader
          width={ART_W}
          height={ART_H}
          fragment={FRAG}
          source={top.canvas}
          fps={ctx.isPreview ? 30 : undefined}
          style={{ position: "absolute", inset: 0 }}
          uniforms={() => {
            const c = current.current;
            top.paint((g, k) => drawArtwork(g, k, swapVariant(c)));
            bottom.paint((g, k) => drawArtwork(g, k, swapVariant(c + 1)));
            return { u_origin: [origin.current.x, origin.current.y], u_progress: progress.get(), u_tile: ctx.n("tile"), u_spread: ctx.n("spread") };
          }}
        />
      </div>
    </CenterStack>
  );
}
