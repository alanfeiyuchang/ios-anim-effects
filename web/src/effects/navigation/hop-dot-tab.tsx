/** navigation.hop-dot-tab · 跳跃圆点指示器 (Navigation+HopDotTab.swift) */
import { AnimatePresence, motion } from "motion/react";
import { Bookmark, CirclePlus, House, LayoutGrid, User } from "lucide-react";
import { useState, type ReactNode } from "react";
import { DemoHint, Palette, anim, black, ease, glass, mix, progress, springAt, useAutoplay, useHaptics, type DemoProps } from "../../kit";
import { NavigationScreenPlaceholder } from "./shared";
import { BookmarkFill, HouseFill, PersonFill, PlusCircleFill, SquareGrid2x2Fill, useSince } from "./groupA-kit";

const SLOT = 56;
const COUNT = 5;
const JUMPS = [2, 1, 4, 0, 3];

/** The outline symbol, or its `.fill` twin when selected (house, square.grid.2x2, plus.circle, bookmark, person). */
function Symbol({ index, filled }: { index: number; filled: boolean }): ReactNode {
  const s = 24;
  const w = 2.1;
  switch (index) {
    case 0:
      return filled ? <HouseFill size={s + 1} /> : <House size={s} strokeWidth={w} />;
    case 1:
      return filled ? <SquareGrid2x2Fill size={s - 1} /> : <LayoutGrid size={s - 1} strokeWidth={w} />;
    case 2:
      return filled ? <PlusCircleFill size={s} /> : <CirclePlus size={s} strokeWidth={w} />;
    case 3:
      return filled ? <BookmarkFill size={s} /> : <Bookmark size={s} strokeWidth={w} />;
    default:
      return filled ? <PersonFill size={s} /> : <User size={s} strokeWidth={w} />;
  }
}

/** `.bouncy` as a closed-form progress. */
const bouncy = (t: number) => springAt(t, 0.5, 0.7);

export default function HopDotTab({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [selected, setSelected] = useState(0);
  const [hops, setHops] = useState(0);
  const [distance, setDistance] = useState(1);
  const duration = ctx.n("duration");

  const select = (index: number) => {
    if (index === selected) return;
    haptics.selection();
    setDistance(Math.abs(index - selected));
    setHops((h) => h + 1);
    setSelected(index);
  };

  useAutoplay(ctx.isPreview, () => select(JUMPS[hops % JUMPS.length]), { every: 1.1 });

  // One clock for every keyframe track, restarted by each hop (`keyframeAnimator(trigger: hops)`).
  const e = useSince(hops, duration + 0.42);

  // Dot: lift, then squash on landing.
  const apex = ctx.n("height") + Math.max(distance - 1, 0) * 4;
  const squash = ctx.n("squash");
  let lift = 0;
  let scaleX = 1;
  let scaleY = 1;
  if (e >= 0) {
    lift = e < duration * 0.5 ? mix(0, apex, ease.inOut(progress(e, 0, duration * 0.5))) : mix(apex, 0, ease.in(progress(e, duration * 0.5, duration * 0.5)));
    const squashTrack = (stretch: number, land: number) => {
      if (e < duration * 0.3) return mix(1, stretch, ease.inOut(progress(e, 0, duration * 0.3)));
      if (e < duration * 0.9) return stretch;
      if (e < duration) return mix(stretch, land, ease.inOut(progress(e, duration * 0.9, duration * 0.1)));
      if (e < duration + 0.35) return mix(land, 1, bouncy(e - duration));
      return 1;
    };
    scaleX = squashTrack(0.8, 1 + squash);
    scaleY = squashTrack(1.25, 1 - squash);
  }
  // Icons: the landing spot dips 3 pt as the dot touches down.
  let dip = 0;
  if (e >= duration) dip = e < duration + 0.07 ? mix(0, 3, ease.inOut(progress(e, duration, 0.07))) : e < duration + 0.42 ? mix(3, 0, bouncy(e - duration - 0.07)) : 0;

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", gap: 28 }}>
      {ctx.isPreview && (
        <div style={{ paddingTop: 20 }}>
          <NavigationScreenPlaceholder />
        </div>
      )}
      <div style={{ flex: 1 }} />
      <div
        style={{
          position: "relative",
          padding: "10px 10px 16px",
          borderRadius: 26,
          ...glass("regular"),
          boxShadow: `inset 0 0 0 1px ${Palette.stroke}, 0 8px 18px ${black(0.12)}`,
          flexShrink: 0,
        }}
      >
        <div style={{ position: "relative", display: "flex" }}>
          {Array.from({ length: COUNT }, (_, index) => {
            const isSelected = index === selected;
            return (
              <div
                key={index}
                onClick={() => select(index)}
                style={{
                  position: "relative",
                  width: SLOT,
                  height: 40,
                  display: "grid",
                  placeItems: "center",
                  cursor: "pointer",
                  color: isSelected ? Palette.indigo : Palette.secondaryLabel,
                  transition: "color 0.3s",
                  transform: isSelected && dip ? `translateY(${dip}px)` : undefined,
                }}
              >
                <AnimatePresence mode="popLayout" initial={false}>
                  <motion.span
                    key={isSelected ? "fill" : "line"}
                    initial={{ scale: 0.5, opacity: 0, filter: "blur(3px)" }}
                    animate={{ scale: 1, opacity: 1, filter: "blur(0px)" }}
                    exit={{ scale: 0.5, opacity: 0, filter: "blur(3px)" }}
                    transition={anim.snappyD(0.3)}
                    style={{ display: "grid" }}
                  >
                    <Symbol index={index} filled={isSelected} />
                  </motion.span>
                </AnimatePresence>
              </div>
            );
          })}
          {/* dot */}
          <motion.div
            initial={false}
            animate={{ x: selected * SLOT + SLOT / 2 - 3.5 }}
            transition={anim.easeInOut(duration)}
            style={{ position: "absolute", left: 0, bottom: -10, width: 7, height: 7 }}
          >
            <div
              style={{
                width: 7,
                height: 7,
                borderRadius: "50%",
                background: Palette.indigo,
                transformOrigin: "50% 100%",
                transform: `translateY(${-lift}px) scale(${scaleX}, ${scaleY})`,
              }}
            />
          </motion.div>
        </div>
      </div>
      <DemoHint ctx={ctx} en="Tap an icon" zh="点击任一图标" />
      <div style={{ flex: 1 }} />
    </div>
  );
}
