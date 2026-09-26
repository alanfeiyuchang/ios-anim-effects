/** buttons.gooey-split · 粘滞分裂 (Buttons+GooeySplit.swift) */
import { AnimatePresence, animate, motion, useMotionValue, useMotionValueEvent } from "motion/react";
import { Link, Share, Sparkles } from "lucide-react";
import { useEffect, useRef, useState } from "react";
import { DemoHint, Palette, anim, delayed, demoCard, glass, spring, useAutoplay, useHaptics, useTimeouts, type DemoProps } from "../../kit";
import { CheckCircleFill, useSvgID } from "./_a-kit";

const FRAME_W = 320;
const FRAME_H = 110;
const D = 56;
const PILL = 200;

function MessageFill({ size }: { size: number }) {
  return (
    <svg viewBox="0 0 24 24" width={size} height={size}>
      <path d="M12 3C6.8 3 2.6 6.6 2.6 11c0 2.5 1.3 4.7 3.4 6.1-.2 1.3-.9 2.6-1.9 3.5 2.1-.1 3.9-.8 5.2-1.9.9.2 1.8.3 2.7.3 5.2 0 9.4-3.6 9.4-8S17.2 3 12 3Z" fill="currentColor" />
    </svg>
  );
}
function EnvelopeFill({ size }: { size: number }) {
  return (
    <svg viewBox="0 0 24 24" width={size} height={size}>
      <rect x="2.5" y="5" width="19" height="14" rx="2.6" fill="currentColor" />
      <path d="M3.6 6.4 12 13l8.4-6.6" fill="none" stroke="rgb(135 115 255)" strokeWidth={1.6} strokeLinejoin="round" />
    </svg>
  );
}

const ACTIONS = [
  { Icon: MessageFill, side: -1, done: ["Sent to Messages", "已发送到信息"] },
  { Icon: ({ size }: { size: number }) => <Link size={size} strokeWidth={2.6} />, side: 0, done: ["Link copied", "链接已复制"] },
  { Icon: EnvelopeFill, side: 1, done: ["Mail draft created", "已创建邮件草稿"] },
] as const;

export default function GooeySplit({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const { after } = useTimeouts();
  const [open, setOpen] = useState(false);
  const openRef = useRef(false);
  const [confirmation, setConfirmation] = useState<number | null>(null);
  const progress = useMotionValue(0);
  const [p, setP] = useState(0);
  useMotionValueEvent(progress, "change", setP);
  const intro = useRef<(() => void) | null>(null);
  const confirmTimers = useRef<(() => void)[]>([]);
  const gradID = useSvgID("goo-grad");
  const filterID = useSvgID("goo");
  const damping = ctx.n("damping");
  const spread = ctx.n("spread");
  const goo = ctx.n("goo");

  const setOpenState = (v: boolean) => {
    openRef.current = v;
    setOpen(v);
    animate(progress, v ? 1 : 0, spring(0.55, damping));
  };
  const toggle = () => {
    haptics.tap(openRef.current ? "soft" : "light");
    setOpenState(!openRef.current);
  };
  const cancelIntro = () => {
    intro.current?.();
    intro.current = null;
  };
  useEffect(() => () => cancelIntro(), []);

  useAutoplay(ctx.isPreview, () => {
    if (ctx.isPreview) {
      toggle();
      return;
    }
    cancelIntro();
    if (!openRef.current) toggle();
    intro.current = after(1.4, () => {
      intro.current = null;
      setOpenState(false);
    });
  }, { every: 1.8, delay: 0.5 });

  const perform = (index: number) => {
    if (!openRef.current) return;
    haptics.success();
    setConfirmation(index);
    confirmTimers.current.forEach((c) => c());
    confirmTimers.current = [
      after(0.22, () => {
        setOpenState(false);
        confirmTimers.current.push(after(1.4, () => setConfirmation(null)));
      }),
    ];
  };

  // The metaball layer: pill shrinks (clamped) while the side drops follow the spring (may overshoot).
  const squeeze = Math.min(Math.max(p, 0), 1);
  const pillW = D + (PILL - D) * (1 - squeeze);
  const mid = { x: FRAME_W / 2, y: FRAME_H / 2 };
  const rects = [
    { x: mid.x - pillW / 2, w: pillW },
    ...[-1, 1].map((side) => ({ x: mid.x + side * spread * p - D / 2, w: D })),
  ];
  const bubbleT = open ? delayed(spring(0.55, damping), 0.08) : anim.easeIn(0.12);
  const zh = ctx.lang === "zh";

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center" }}>
      <div style={{ flex: 1 }} />
      <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 26 }}>
        <div style={{ ...demoCard(22), width: 240, padding: 12, display: "flex", flexDirection: "column", gap: 8 }}>
          <div style={{ position: "relative", height: 96, borderRadius: 14, background: Palette.aurora }}>
            <Sparkles size={19} strokeWidth={2.3} color="#fff" style={{ position: "absolute", left: 12, bottom: 12 }} />
          </div>
          <div style={{ fontSize: 15, lineHeight: "20px", fontWeight: 600, color: Palette.label }}>{zh ? "极光配色 · 第 12 期" : "Aurora palette · Issue 12"}</div>
        </div>
        <div
          onClick={() => {
            cancelIntro();
            toggle();
          }}
          style={{ position: "relative", width: FRAME_W, height: FRAME_H, marginBottom: 24, cursor: "pointer" }}
        >
          <svg width={FRAME_W} height={FRAME_H} style={{ position: "absolute", inset: 0, overflow: "visible", filter: "drop-shadow(0 8px 14px rgb(110 123 255 / 0.35))" }}>
            <defs>
              <linearGradient id={gradID} gradientUnits="userSpaceOnUse" x1="0" y1="0" x2={FRAME_W} y2="0">
                <stop offset="0" stopColor={Palette.indigo} />
                <stop offset="1" stopColor={Palette.violet} />
              </linearGradient>
              <filter id={filterID} x="-20%" y="-50%" width="140%" height="200%" colorInterpolationFilters="sRGB">
                <feGaussianBlur in="SourceGraphic" stdDeviation={goo} result="blur" />
                <feColorMatrix in="blur" type="matrix" values="0 0 0 0 1  0 0 0 0 1  0 0 0 0 1  0 0 0 40 -20" result="goo" />
                <feGaussianBlur in="goo" stdDeviation={0.7} />
              </filter>
              <mask id={filterID + "m"} maskUnits="userSpaceOnUse" x="-40" y="-60" width={FRAME_W + 80} height={FRAME_H + 120}>
                <g filter={`url(#${filterID})`}>
                  {rects.map((r, i) => (
                    <rect key={i} x={r.x} y={mid.y - D / 2} width={r.w} height={D} rx={D / 2} fill="#fff" />
                  ))}
                </g>
              </mask>
            </defs>
            <rect x={-40} y={-60} width={FRAME_W + 80} height={FRAME_H + 120} fill={`url(#${gradID})`} mask={`url(#${filterID}m)`} />
          </svg>
          <motion.div
            initial={false}
            animate={{ opacity: open ? 0 : 1, scale: open ? 0.7 : 1 }}
            transition={open ? anim.easeOut(0.12) : delayed(anim.easeOut(0.25), 0.2)}
            style={{
              position: "absolute",
              inset: 0,
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              gap: 8,
              color: "#fff",
              fontSize: 17,
              fontWeight: 600,
              pointerEvents: "none",
            }}
          >
            <Share size={18} strokeWidth={2.4} />
            <span>{zh ? "分享" : "Share"}</span>
          </motion.div>
          {ACTIONS.map((a, i) => (
            <motion.div
              key={i}
              initial={false}
              animate={{ x: open ? a.side * spread : 0, scale: open ? 1 : 0.3, opacity: open ? 1 : 0 }}
              transition={bubbleT}
              style={{ position: "absolute", left: mid.x - 26, top: mid.y - 26, width: 52, height: 52, pointerEvents: open ? "auto" : "none" }}
            >
              <Bubble
                onTap={() => {
                  cancelIntro();
                  perform(i);
                }}
              >
                <a.Icon size={21} />
              </Bubble>
            </motion.div>
          ))}
          <div style={{ position: "absolute", left: 0, right: 0, bottom: -30, display: "flex", justifyContent: "center", pointerEvents: "none" }}>
            <AnimatePresence>
              {confirmation !== null && (
                <motion.div
                  key={confirmation}
                  initial={{ y: -20, opacity: 0 }}
                  animate={{ y: 0, opacity: 1 }}
                  exit={{ y: -20, opacity: 0, transition: anim.easeOut(0.25) }}
                  transition={spring(0.35, 0.75)}
                  style={{
                    position: "absolute",
                    bottom: 0,
                    display: "flex",
                    alignItems: "center",
                    gap: 6,
                    padding: "7px 12px",
                    borderRadius: 999,
                    ...glass("regular"),
                    boxShadow: `inset 0 0 0 1px ${Palette.stroke}`,
                    fontSize: 13,
                    lineHeight: "18px",
                    fontWeight: 600,
                    color: Palette.label,
                    whiteSpace: "nowrap",
                  }}
                >
                  <CheckCircleFill size={15} color={Palette.green} />
                  {ctx.t(ACTIONS[confirmation].done[0], ACTIONS[confirmation].done[1])}
                </motion.div>
              )}
            </AnimatePresence>
          </div>
        </div>
      </div>
      <div style={{ flex: 1 }} />
      <DemoHint ctx={ctx} en="Tap Share, then pick a bubble" zh="点击分享，再选一个气泡" style={{ paddingBottom: 18 }} />
    </div>
  );
}

function Bubble({ onTap, children }: { onTap: () => void; children: React.ReactNode }) {
  const [pressed, setPressed] = useState(false);
  return (
    <motion.button
      type="button"
      onClick={(e) => {
        e.stopPropagation();
        onTap();
      }}
      onPointerDown={() => setPressed(true)}
      onPointerUp={() => setPressed(false)}
      onPointerLeave={() => setPressed(false)}
      animate={{ scale: pressed ? 0.86 : 1, backgroundColor: pressed ? "rgba(255,255,255,0.22)" : "rgba(255,255,255,0)" }}
      transition={spring(0.25, 0.6)}
      style={{ width: 52, height: 52, borderRadius: "50%", display: "grid", placeItems: "center", color: "#fff" }}
    >
      {children}
    </motion.button>
  );
}
