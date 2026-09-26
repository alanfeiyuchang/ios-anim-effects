/** buttons.elastic-blob · 弹性果冻条 (Buttons+ElasticBlob.swift) */
import { animate, motion, useMotionValue, useMotionValueEvent, useTransform } from "motion/react";
import { Search } from "lucide-react";
import { useRef, useState } from "react";
import { DemoHint, Palette, alpha, anim, black, clamp, glass, spring, useAutoplay, useHaptics, usePan, useTimeouts, type DemoProps } from "../../kit";
import { Bounce } from "./_b-kit";
import { CameraFill, HouseFill, PersonCircleFill } from "./_b-icons";

const W = 288;
const H = 64;
const SLOT = W / 4;
const PREVIEW_ORDER = [2, 0, 3, 1];
const center = (i: number) => SLOT * (i + 0.5);

export default function ElasticBlob({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const { after } = useTimeouts();
  const blobX = useMotionValue(center(0));
  const stretch = useMotionValue(0);
  const [leftward, setLeftward] = useState(false);
  const [bounces, setBounces] = useState([0, 0, 0, 0]);
  const [hovered, setHovered] = useState(0);
  const selected = useRef(0);
  const generation = useRef(0);
  const step = useRef(0);
  const relax = useRef(0);

  useMotionValueEvent(blobX, "change", (x) => {
    const index = [0, 1, 2, 3].find((i) => Math.abs(x - center(i)) < SLOT / 2) ?? -1;
    setHovered(index);
  });

  const userSpring = spring(ctx.n("response"), ctx.n("damping"));
  const bounce = (i: number) => setBounces((b) => b.map((v, k) => (k === i ? v + 1 : v)));

  const track = (x: number, velocity: number) => {
    const cx = clamp(x, 30, W - 30);
    const amount = Math.min(Math.abs(velocity) / 1500, 1) * ctx.n("stretch");
    generation.current += 1;
    const tag = generation.current;
    animate(blobX, cx, userSpring);
    animate(stretch, amount, userSpring);
    if (Math.abs(velocity) > 40) setLeftward(velocity < 0);
    window.clearTimeout(relax.current);
    relax.current = window.setTimeout(() => {
      if (tag === generation.current) animate(stretch, 0, userSpring);
    }, 120);
  };

  const snap = (x: number) => {
    const index = clamp(Math.floor(x / SLOT), 0, 3);
    window.clearTimeout(relax.current);
    generation.current += 1;
    animate(blobX, center(index), spring(0.4, 0.6));
    animate(stretch, 0, spring(0.4, 0.6));
    bounce(index);
    selected.current = index;
    haptics.selection();
  };

  const previewStep = () => {
    const target = PREVIEW_ORDER[step.current % PREVIEW_ORDER.length];
    step.current += 1;
    const to = center(target);
    setLeftward(to < blobX.get());
    animate(stretch, ctx.n("stretch") * 0.7, spring(0.3, 0.7));
    animate(blobX, to, spring(0.3, 0.7));
    after(0.2, () => {
      animate(stretch, 0, spring(0.4, 0.55));
      bounce(target);
      selected.current = target;
    });
  };
  useAutoplay(ctx.isPreview, previewStep, { every: 1.0, delay: 0.3 });

  const pan = usePan({
    onChange: ({ location, velocity }) => track(location.x, velocity.x),
    onEnd: ({ location }) => snap(location.x),
  });

  const blobLeft = useTransform(blobX, (x) => x - 30);
  const scaleX = useTransform(stretch, (s) => 1 + s);
  const scaleY = useTransform(stretch, (s) => 1 - s * 0.3);
  const icons = [HouseFill, null, CameraFill, PersonCircleFill];

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center" }}>
      <div style={{ flex: 1 }} />
      <div
        {...pan}
        style={{
          position: "relative",
          width: W,
          height: H,
          flexShrink: 0,
          borderRadius: H / 2,
          ...glass("regular"),
          boxShadow: `inset 0 0 0 1px ${Palette.stroke}, 0 10px 18px ${black(0.14)}`,
          touchAction: "none",
          cursor: "pointer",
        }}
      >
        <motion.div
          style={{
            position: "absolute",
            top: (H - 48) / 2,
            left: blobLeft,
            width: 60,
            height: 48,
            borderRadius: 24,
            background: `linear-gradient(90deg, ${alpha(Palette.indigo, 0.9)}, ${alpha(Palette.violet, 0.9)})`,
            boxShadow: `0 4px 10px ${alpha(Palette.violet, 0.4)}`,
            scaleX,
            scaleY,
            transformOrigin: leftward ? "0% 50%" : "100% 50%",
          }}
        />
        <div style={{ position: "absolute", inset: 0, display: "flex", pointerEvents: "none" }}>
          {icons.map((Icon, i) => {
            const on = hovered === i;
            return (
              <div key={i} style={{ width: SLOT, height: H, display: "grid", placeItems: "center" }}>
                <motion.div
                  initial={false}
                  animate={{ scale: on ? 1.12 : 1 }}
                  transition={anim.snappyD(0.2)}
                  style={{ display: "grid", color: on ? "#ffffff" : Palette.secondaryLabel, transition: "color 0.2s ease-out" }}
                >
                  <Bounce trigger={bounces[i]}>{Icon ? <Icon size={23} /> : <Search size={22} strokeWidth={3} />}</Bounce>
                </motion.div>
              </div>
            );
          })}
        </div>
      </div>
      <div style={{ flex: 1 }} />
      <DemoHint ctx={ctx} en="Slide along the bar, then let go" zh="沿按钮条滑动后松手" style={{ paddingBottom: 18 }} />
    </div>
  );
}
