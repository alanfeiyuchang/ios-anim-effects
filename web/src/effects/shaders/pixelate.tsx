/** shader.pixelate · 像素化切换 (Shaders+Stylize.swift, mlPixelate) */
import { animate, useMotionValue } from "motion/react";
import { useRef } from "react";
import { anim, useAutoplay, useTimeouts, type DemoProps } from "../../kit";
import { ART_H, ART_W, LIB, drawArtwork, useLayer } from "./_shared";
import { CenterStack } from "./_stage";
import { Shader } from "./_gl";

const FRAG = `
uniform float u_cell;
${LIB}
void main() {
  vec2 position = v_uv * u_size;
  if (u_cell <= 1.01) { gl_FragColor = S(position); return; }
  float s = max(u_cell, 1.0);
  vec2 cell = floor(position / s) * s + s * 0.5;
  gl_FragColor = S(cell);
}`;

export default function Pixelate({ ctx }: DemoProps) {
  const layer = useLayer(ART_W, ART_H);
  const size = useMotionValue(1);
  /** Opacity of the second scene (showSecond, cross-faded linearly over 80 ms). */
  const second = useMotionValue(0);
  const showSecond = useRef(false);
  const busy = useRef(false);
  const { after } = useTimeouts();

  const swapContent = () => {
    if (busy.current) return;
    busy.current = true;
    const half = ctx.n("duration") / 2;
    animate(size, ctx.n("maxSize"), anim.easeIn(half));
    after(half, () => {
      // Cross-fade under the coarsest mosaic so the swap never reads as a cut.
      showSecond.current = !showSecond.current;
      animate(second, showSecond.current ? 1 : 0, anim.linear(0.08));
      after(0.08, () => {
        animate(size, 1, anim.easeOut(half * 1.1));
        after(half * 1.1, () => (busy.current = false));
      });
    });
  };
  useAutoplay(ctx.isPreview, swapContent, { every: 2.0, delay: 0.4 });

  return (
    <CenterStack ctx={ctx} en="Tap to swap content" zh="点击切换内容">
      <div onClick={swapContent} style={{ width: ART_W, height: ART_H, cursor: "pointer", flexShrink: 0 }}>
        <Shader
          width={ART_W}
          height={ART_H}
          fragment={FRAG}
          source={layer.canvas}
          fps={ctx.isPreview ? 30 : undefined}
          uniforms={() => {
            const b = second.get();
            layer.paint((g, k) => {
              if (b < 1) drawArtwork(g, k, 0, 0, 0, 1 - b);
              if (b > 0) drawArtwork(g, k, 1, 0, 0, b);
            });
            return { u_cell: size.get() };
          }}
        />
      </div>
    </CenterStack>
  );
}
