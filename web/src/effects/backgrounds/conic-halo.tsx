/** backgrounds.conic-halo · 锥形光环 (Backgrounds+AmbientGradients.swift) */
import { useRef, type CSSProperties } from "react";
import { useAutoplay, useHaptics, type DemoProps } from "../../kit";
import { BackgroundClock, BgHint, SampleTitle, Stage, useFrameLoop, useModel } from "./_support";

class HaloModel {
  clock = new BackgroundClock();
  angle = 0;
  counter = 0;
  private boost = 0;
  /** Energy as drawn: eases toward the momentum-derived target (rate 14/s). */
  energy = 0;
  step(now: number, speed: number, friction: number) {
    this.clock.advance(now, 1);
    const dt = this.clock.delta;
    this.boost *= Math.exp(-dt * friction);
    const base = 0.35 * speed;
    this.angle += (base + this.boost) * dt;
    this.counter -= (base * 0.6 + this.boost * 0.45) * dt;
    const target = Math.min(this.boost / 9, 1);
    this.energy += (target - this.energy) * this.clock.follow(14);
  }
  kick() {
    this.boost = Math.min(this.boost + 7, 16);
  }
}

const OUTER = "conic-gradient(from 90deg, #6E7BFF, #FF5FA2, #FFC247, #21D4A8, #6E7BFF)";
const INNER = "conic-gradient(from 90deg, #A46BFF, #3AC4FF, #FF7A5C, #A46BFF)";

const disc = (size: number): CSSProperties => ({
  position: "absolute",
  left: "50%",
  top: "50%",
  width: size,
  height: size,
  marginLeft: -size / 2,
  marginTop: -size / 2,
  borderRadius: "50%",
});

export default function ConicHalo({ ctx }: DemoProps) {
  const root = useRef<HTMLDivElement>(null);
  const group = useRef<HTMLDivElement>(null);
  const outer = useRef<HTMLDivElement>(null);
  const inner = useRef<HTMLDivElement>(null);
  const ring = useRef<HTMLDivElement>(null);
  const model = useModel(() => new HaloModel());
  const haptics = useHaptics();
  const blur = ctx.n("blur");

  useFrameLoop(root, ctx.isPreview, (now) => {
    model.step(now, ctx.n("speed"), ctx.n("friction"));
    const e = model.energy;
    if (outer.current) outer.current.style.transform = `rotate(${model.angle}rad)`;
    if (inner.current) inner.current.style.transform = `rotate(${model.counter}rad)`;
    if (ring.current) {
      ring.current.style.transform = `rotate(${model.angle * 1.5}rad)`;
      ring.current.style.opacity = String(0.35 + 0.5 * e);
    }
    if (group.current) group.current.style.transform = `scale(${1 + 0.06 * e})`;
  });

  useAutoplay(ctx.isPreview, () => model.kick(), { every: 3.0, delay: 0.8 });

  return (
    <Stage
      rootRef={root}
      background="#07060F"
      handlers={{
        onClick: () => {
          haptics.tap("soft");
          model.kick();
        },
      }}
    >
      {/* drawingGroup renders the 300 pt ZStack offscreen, so the blurred glow is clipped to that square. */}
      <div style={{ ...disc(300), borderRadius: 0, overflow: "hidden", isolation: "isolate", pointerEvents: "none" }}>
      <div ref={group} style={{ position: "absolute", inset: 0 }}>
        <div style={{ ...disc(300), filter: `blur(${blur}px)`, opacity: 0.9 }}>
          <div ref={outer} style={{ position: "absolute", inset: 0, borderRadius: "50%", background: OUTER }} />
        </div>
        <div style={{ ...disc(190), filter: `blur(${blur * 0.6}px)`, mixBlendMode: "plus-lighter" }}>
          <div ref={inner} style={{ position: "absolute", inset: 0, borderRadius: "50%", background: INNER }} />
        </div>
        <div
          ref={ring}
          style={{
            ...disc(222),
            background: OUTER,
            padding: 1.5,
            WebkitMask: "linear-gradient(#000 0 0) content-box, linear-gradient(#000 0 0)",
            WebkitMaskComposite: "xor",
            mask: "linear-gradient(#000 0 0) content-box exclude, linear-gradient(#000 0 0)",
          }}
        />
        <div style={{ ...disc(118), background: "#07060F", filter: "blur(18px)" }} />
      </div>
      </div>
      <SampleTitle title={ctx.t("Focus", "专注")} subtitle={ctx.t("25:00 · Deep work", "25:00 · 深度工作")} size={30} />
      <BgHint ctx={ctx} en="Tap to spin up the halo" zh="点击让光环加速" />
    </Stage>
  );
}
