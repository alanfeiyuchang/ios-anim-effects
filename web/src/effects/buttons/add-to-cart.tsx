/** buttons.add-to-cart · 加入购物袋 (Buttons+AddToCart.swift) */
import { AnimatePresence, motion } from "motion/react";
import { Check, Headphones, Star } from "lucide-react";
import { useCallback, useRef, useState } from "react";
import {
  NumericText,
  Palette,
  alpha,
  black,
  demoCard,
  fonts,
  spring,
  springAt,
  useAutoplay,
  useHaptics,
  useTimeouts,
  white,
  type DemoProps,
} from "../../kit";
import { At, Bounce, cub, lin, move, track, useKeyframes } from "./_b-kit";

const BAG = { x: 104, y: -122 };
const BUTTON = { x: 0, y: 62 };
const THUMB = { x: -97, y: -30 };

/** Product image stand-in: a warm gradient tile with a glyph and a glossy top edge. */
function ProductThumb({ side }: { side: number }) {
  const r = side * 0.26;
  return (
    <div
      style={{
        position: "relative",
        width: side,
        height: side,
        flexShrink: 0,
        borderRadius: r,
        background: `linear-gradient(135deg, ${Palette.amber}, ${Palette.coral}, ${Palette.pink})`,
        boxShadow: `inset 0 0 0 1px ${white(0.3)}, 0 ${side * 0.08}px ${side * 0.15}px ${alpha(Palette.coral, 0.3)}`,
        display: "grid",
        placeItems: "center",
        color: "#fff",
      }}
    >
      <Headphones size={side * 0.5} strokeWidth={2.4} />
    </div>
  );
}

/** SF `bag.fill`. */
function BagFill({ size }: { size: number }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24">
      <path d="M8 8V6.5a4 4 0 0 1 8 0V8" fill="none" stroke="currentColor" strokeWidth={2} strokeLinecap="round" />
      <path d="M5.2 7h13.6a1.5 1.5 0 0 1 1.5 1.4l.8 11.1A2.3 2.3 0 0 1 18.8 22H5.2a2.3 2.3 0 0 1-2.3-2.5l.8-11.1A1.5 1.5 0 0 1 5.2 7Z" fill="currentColor" />
    </svg>
  );
}

/** SF `bag.badge.plus`. */
function BagPlus({ size }: { size: number }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={1.9} strokeLinecap="round" strokeLinejoin="round">
      <path d="M13 8H5.6a1.4 1.4 0 0 0-1.4 1.3l-.9 10.3A2.2 2.2 0 0 0 5.5 22h12.3a2.2 2.2 0 0 0 2.2-2.4l-.4-5" />
      <path d="M7.5 8V6.8A3.8 3.8 0 0 1 12 3.1" />
      <path d="M18.5 2.5v7M15 6h7" />
    </svg>
  );
}

export default function AddToCart({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const { after } = useTimeouts();
  const [added, setAdded] = useState(false);
  const [count, setCount] = useState(2);
  const [flights, setFlights] = useState(0);
  const addedRef = useRef(false);
  const zh = ctx.lang === "zh";
  const response = ctx.n("response");
  const morph = spring(response, 0.75);

  const add = useCallback((auto = false) => {
    if (addedRef.current) return;
    addedRef.current = true;
    const hold = ctx.n("hold");
    const fly = ctx.b("fly");
    haptics.tap();
    setAdded(true);
    if (fly) setFlights((f) => f + 1);
    // Captured now: autoplay (and the detail intro) mute haptics only for the synchronous part.
    const silent = auto;
    after(fly ? 0.6 : 0.2, () => {
      setCount((c) => c + 1);
      if (!silent) haptics.success();
      after(hold, () => {
        setAdded(false);
        addedRef.current = false;
      });
    });
  }, [ctx, haptics, after]);

  useAutoplay(ctx.isPreview, () => add(true), { every: ctx.n("hold") + 1.6, delay: 0.4 });

  return (
    <div style={{ position: "absolute", inset: 0 }}>
      <At y={16}>
        <div style={{ ...demoCard(26), width: 292, height: 210, flexShrink: 0 }} />
      </At>
      <At y={THUMB.y}>
        <div style={{ width: 258, display: "flex", alignItems: "center", gap: 14, flexShrink: 0 }}>
          <ProductThumb side={64} />
          <div style={{ display: "flex", flexDirection: "column", gap: 4, minWidth: 0 }}>
            <div style={{ fontSize: 15, lineHeight: "20px", fontWeight: 600, color: Palette.label, whiteSpace: "nowrap" }}>
              {zh ? "降噪头戴耳机" : "Studio Headphones"}
            </div>
            <div style={{ display: "flex", alignItems: "center", gap: 3, fontSize: 11, lineHeight: "13px", fontWeight: 600 }}>
              <Star size={10} fill={Palette.amber} color={Palette.amber} strokeWidth={0} />
              <span style={{ color: Palette.secondaryLabel }}>4.9 · 2.1k</span>
            </div>
            <div style={{ fontFamily: fonts.rounded, fontSize: 17, lineHeight: "22px", fontWeight: 600, fontVariantNumeric: "tabular-nums", color: Palette.label }}>
              {zh ? "¥1,299" : "$199"}
            </div>
          </div>
        </div>
      </At>
      <At x={BAG.x} y={BAG.y}>
        <Bag count={count} />
      </At>
      <At x={BUTTON.x} y={BUTTON.y}>
        <motion.button
          type="button"
          onClick={() => add()}
          initial={false}
          animate={{
            width: added ? 60 : 220,
            backgroundColor: added ? Palette.green : Palette.indigo,
            boxShadow: `0 8px 14px ${alpha(added ? Palette.green : Palette.indigo, 0.35)}`,
          }}
          transition={morph}
          style={{ position: "relative", height: 60, borderRadius: 30, flexShrink: 0, color: "#fff" }}
        >
          <AnimatePresence initial={false}>
            {added ? (
              <motion.span
                key="check"
                initial={{ scale: 0.3, opacity: 0 }}
                animate={{ scale: 1, opacity: 1 }}
                exit={{ scale: 0.3, opacity: 0 }}
                transition={morph}
                style={{ position: "absolute", inset: 0, display: "grid", placeItems: "center" }}
              >
                <Check size={26} strokeWidth={3.4} />
              </motion.span>
            ) : (
              <motion.span
                key="label"
                initial={{ scale: 0.8, opacity: 0 }}
                animate={{ scale: 1, opacity: 1 }}
                exit={{ scale: 0.8, opacity: 0 }}
                transition={morph}
                style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center", gap: 8, fontSize: 17, fontWeight: 600, whiteSpace: "nowrap" }}
              >
                <BagPlus size={20} />
                {zh ? "加入购物袋" : "Add to Bag"}
              </motion.span>
            )}
          </AnimatePresence>
        </motion.button>
      </At>
      {ctx.b("fly") && <Flight trigger={flights} />}
    </div>
  );
}

function Bag({ count }: { count: number }) {
  const t = useKeyframes(count, 0.57);
  const scale = t < 0 ? 1 : t < 0.12 ? track(t, [cub(1.45, 0.12)], 1) : 1.45 + (1 - 1.45) * springAt(t - 0.12, 0.3, 0.45);
  return (
    <div
      style={{
        position: "relative",
        width: 56,
        height: 56,
        borderRadius: "50%",
        background: Palette.elevated,
        boxShadow: `inset 0 0 0 1px ${Palette.stroke}, 0 5px 10px ${black(0.1)}`,
        display: "grid",
        placeItems: "center",
        color: Palette.label,
      }}
    >
      <Bounce trigger={count}>
        <BagFill size={28} />
      </Bounce>
      <div
        style={{
          position: "absolute",
          top: -4,
          right: -4,
          minWidth: 22,
          height: 22,
          padding: "0 6px",
          borderRadius: 11,
          background: Palette.pink,
          color: "#fff",
          fontSize: 12,
          fontWeight: 700,
          display: "grid",
          placeItems: "center",
          transform: `scale(${scale})`,
        }}
      >
        <NumericText value={count} />
      </div>
    </div>
  );
}

/** A copy of the product image hops from the card into the bag (KeyframeAnimator, 0.6 s). */
function Flight({ trigger }: { trigger: number }) {
  const t = useKeyframes(trigger, 0.6);
  if (t < 0) return null;
  const x = track(t, [move(THUMB.x), cub(BAG.x, 0.6)], 0);
  const y = track(t, [move(THUMB.y), cub(BAG.y - 44, 0.34), cub(BAG.y, 0.26)], 0);
  const scale = track(t, [move(1), cub(1.08, 0.1), cub(0.3, 0.5)], 1);
  const spin = track(t, [move(0), cub(18, 0.6)], 0);
  const opacity = t >= 0.6 ? 0 : track(t, [move(1), lin(1, 0.52), lin(0, 0.08)], 0);
  return (
    <At x={x} y={y} style={{ pointerEvents: "none", opacity }}>
      <div style={{ transform: `rotate(${spin}deg) scale(${scale})` }}>
        <ProductThumb side={64} />
      </div>
    </At>
  );
}
