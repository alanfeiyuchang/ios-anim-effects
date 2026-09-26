/** backgrounds.wave-band · 斜切波带 (Backgrounds+AmbientGradients.swift) */
import { useEffect, useRef } from "react";
import { Palette, useAutoplay, useHaptics, type DemoProps } from "../../kit";
import { MeshRenderer, acquire, release } from "./_gl";
import { BackgroundClock, Stage, rgb01, sizeOf, useFrameLoop, useModel, useRatio } from "./_support";

const COLORS = [
  0x7a5cff, 0xff5fa2, 0xff7a45, 0xffc247,
  0x3ac4ff, 0xa46bff, 0xff4d7a, 0xff9a3d,
  0x21d4a8, 0x4f7cff, 0xb86bff, 0xff5fa2,
].flatMap(rgb01);

function points(t: number, amplitude: number): number[] {
  const out: number[] = [];
  for (let row = 0; row < 3; row++) {
    for (let col = 0; col < 4; col++) {
      let x = col / 3;
      let y = row / 2;
      if (col > 0 && col < 3) x += 0.07 * Math.sin(t * 0.8 + col * 1.9 + row);
      if (row === 1) y += amplitude * Math.sin(t * 1.3 - col * 1.4);
      out.push(x, y);
    }
  }
  return out;
}

class BandModel {
  clock = new BackgroundClock();
  /** Extra amplitude and its velocity: a damped oscillator (decay 2.4/s, 9 rad/s). */
  private ring = 0;
  private ringVelocity = 0;
  step(now: number, speed: number) {
    const t = this.clock.advance(now, speed);
    let remaining = this.clock.delta;
    while (remaining > 0) {
      const dt = Math.min(remaining, 1 / 240);
      this.ringVelocity += (-(81 + 5.76) * this.ring - 4.8 * this.ringVelocity) * dt;
      this.ring += this.ringVelocity * dt;
      remaining -= dt;
    }
    if (Math.abs(this.ring) < 0.0005 && Math.abs(this.ringVelocity) < 0.005) {
      this.ring = 0;
      this.ringVelocity = 0;
    }
    return { t, gain: Math.max(1 + this.ring, 0) };
  }
  hit() {
    this.ringVelocity += 1.91 * 9;
  }
}

export default function WaveBand({ ctx }: DemoProps) {
  const root = useRef<HTMLDivElement>(null);
  const canvas = useRef<HTMLCanvasElement>(null);
  const renderer = useRef<MeshRenderer | null>(null);
  const model = useModel(() => new BandModel());
  const haptics = useHaptics();
  const ratio = useRatio(root);

  useEffect(() => {
    const el = canvas.current;
    if (!el) return;
    const r = acquire(el, () => new MeshRenderer(el));
    renderer.current = r;
    return () => {
      release(el, r);
      renderer.current = null;
    };
  }, []);

  useFrameLoop(root, ctx.isPreview, (now) => {
    const { w, h } = sizeOf(root.current);
    const s = model.step(now, ctx.n("speed"));
    // Capped so the middle row can never cross rows 0 and 2 and fold the mesh.
    renderer.current?.draw(w, h, Math.min(ratio(), 2), 4, 3, points(s.t, Math.min(ctx.n("amplitude") * s.gain, 0.4)), COLORS);
  });

  useAutoplay(ctx.isPreview, () => model.hit(), { every: 3.2, delay: 0.8 });

  const slant = ctx.n("slant");
  const right = (0.6 - slant / 2) * 100;
  const left = (0.6 + slant / 2) * 100;
  return (
    <Stage
      rootRef={root}
      background={Palette.background}
      handlers={{
        onClick: () => {
          haptics.tap("soft");
          model.hit();
        },
      }}
    >
      <canvas
        ref={canvas}
        style={{
          position: "absolute",
          inset: 0,
          width: "100%",
          height: "100%",
          display: "block",
          clipPath: `polygon(0 0, 100% 0, 100% ${right}%, 0 ${left}%)`,
        }}
      />
      <div style={{ position: "absolute", left: 0, bottom: 0, padding: 22, display: "flex", flexDirection: "column", gap: 6, pointerEvents: "none" }}>
        <div style={{ fontSize: 26, lineHeight: "31px", fontWeight: 700, color: Palette.label }}>{ctx.t("Build what's next", "构建下一步")}</div>
        <div style={{ fontSize: 15, lineHeight: "20px", fontWeight: 500, color: Palette.secondaryLabel, opacity: ctx.isPreview ? 0 : 1 }}>
          {ctx.t("Tap the band to make it ring", "点击色带让它抖动起来")}
        </div>
      </div>
    </Stage>
  );
}
