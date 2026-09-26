/** showcase.get-started · 立即开始 (TravelGetStarted.swift) */
import { AnimatePresence, motion } from "motion/react";
import { ArrowRight, CalendarDays, Search, Users, X } from "lucide-react";
import { useLayoutEffect, useRef, useState } from "react";
import {
  DemoHint,
  black,
  delayed,
  ease,
  fonts,
  progress,
  spring,
  springAt,
  useAutoplay,
  useClock,
  useHaptics,
  useLatest,
  useTimeouts,
  white,
  type DemoProps,
} from "../../kit";
import { LandscapeArt, Signature, SignatureRim, SignatureStage, signatureCard, signatureEyebrow } from "./signature";

const CARD_W = 300;
const CARD_H = 320;
const PILL_H = 56;
const PILL_TOP = CARD_H - 24 - PILL_H;
/** Sheet: 18 padding, 26 header, 3 × 36 fields, 42 CTA, 12 spacing. */
const SHEET_H = 18 * 2 + 26 + 12 * 4 + 36 * 3 + 42;
const SHEET_TOP = CARD_H - 12 - SHEET_H;
const TITLE_LH = 22;
const SQUASH = spring(0.16, 0.7);

export default function GetStarted({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const { after, clearAll } = useTimeouts();
  const zh = ctx.lang === "zh";
  const sp = spring(ctx.n("response"), ctx.n("damping"));
  const [squeezed, setSqueezed] = useState(false);
  const [pressed, setPressed] = useState(false);
  const [expanded, setExpanded] = useState(false);
  const [showBody, setShowBody] = useState(false);
  const generation = useRef(0);
  const expandedRef = useLatest(expanded);
  const intro = useRef<(() => void) | null>(null);

  // Pill width follows its label (leading 26 + label + 14 + 44 badge + trailing 6).
  const labelRef = useRef<HTMLSpanElement>(null);
  const [labelW, setLabelW] = useState(zh ? 68 : 96);
  useLayoutEffect(() => {
    if (labelRef.current) setLabelW(labelRef.current.offsetWidth);
  }, [zh]);
  const pillW = 26 + labelW + 14 + 44 + 6;
  const pillLeft = (CARD_W - pillW) / 2;

  const cancelIntro = () => {
    intro.current?.();
    intro.current = null;
  };

  const morph = (silent: boolean) => {
    if (expandedRef.current) return;
    if (!silent) haptics.tap("medium");
    generation.current += 1;
    const gen = generation.current;
    setSqueezed(false);
    setExpanded(true);
    expandedRef.current = true;
    // `completion:` of the morph spring, then the body fades in.
    after(ctx.n("response") * 1.05, () => {
      if (gen === generation.current && expandedRef.current) setShowBody(true);
    });
  };

  const collapse = () => {
    generation.current += 1;
    const gen = generation.current;
    setShowBody(false);
    after(0.12, () => {
      if (gen !== generation.current) return;
      setExpanded(false);
      expandedRef.current = false;
    });
  };

  const toggle = (silent: boolean) => {
    if (expandedRef.current) {
      if (!silent) haptics.tap();
      collapse();
    } else {
      setSqueezed(true);
      after(0.2, () => morph(silent));
    }
  };

  const playIntro = () => {
    cancelIntro();
    if (!expandedRef.current) toggle(true);
    intro.current = after(2.6, () => {
      if (expandedRef.current) collapse();
      intro.current = null;
    });
  };

  useAutoplay(ctx.isPreview, () => (ctx.isPreview ? toggle(true) : playIntro()), { every: 2.4 });

  const userToggle = () => {
    cancelIntro();
    toggle(false);
  };
  const userExpand = () => {
    cancelIntro();
    clearAll();
    morph(false);
  };

  const down = (pressed || squeezed) && !expanded;
  const stretch = ctx.n("stretch");
  const surface = expanded
    ? { left: 12, top: SHEET_TOP, width: CARD_W - 24, height: SHEET_H, borderRadius: 24 }
    : { left: pillLeft, top: PILL_TOP, width: pillW, height: PILL_H, borderRadius: 28 };
  const title = expanded ? { x: 30, y: SHEET_TOP + 18 + 13 - TITLE_LH / 2 } : { x: pillLeft + 26, y: PILL_TOP + PILL_H / 2 - TITLE_LH / 2 };
  const fade = { initial: { opacity: 0 }, animate: { opacity: 1 }, exit: { opacity: 0 }, transition: sp };

  return (
    <SignatureStage>
      <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 12 }}>
        <div style={{ ...signatureCard(30), width: CARD_W, height: CARD_H, flexShrink: 0 }}>
          <div style={{ position: "absolute", inset: 0, borderRadius: 30, overflow: "hidden" }}>
            <Backdrop zh={zh} dimmed={expanded} transition={sp} />
            {/* Morphing layer: the squash applies around the pill's centre. */}
            <motion.div
              initial={false}
              animate={{ scaleX: down ? 1 + stretch : 1, scaleY: down ? 1 - stretch * 0.6 : 1 }}
              transition={SQUASH}
              style={{ position: "absolute", inset: 0, transformOrigin: `${CARD_W / 2}px ${PILL_TOP + PILL_H / 2}px`, pointerEvents: "none" }}
            >
              <motion.div initial={false} animate={surface} transition={sp} style={{ position: "absolute" }}>
                <motion.div
                  initial={false}
                  animate={{ opacity: expanded ? 0 : 1 }}
                  transition={sp}
                  style={{ position: "absolute", inset: 0, borderRadius: "inherit", background: Signature.paper, boxShadow: `0 8px 18px rgb(255 138 31 / 0.35)` }}
                />
                <motion.div
                  initial={false}
                  animate={{ opacity: expanded ? 1 : 0 }}
                  transition={sp}
                  style={{ position: "absolute", inset: 0, borderRadius: "inherit", background: Signature.paper, boxShadow: `0 10px 20px ${black(0.4)}` }}
                />
              </motion.div>
              <AnimatePresence initial={false}>
                {!expanded && (
                  <motion.div key="badge" {...fade} style={{ position: "absolute", left: pillLeft + pillW - 6 - 44, top: PILL_TOP + 6 }}>
                    <ArrowBadge fps={ctx.isPreview ? 30 : undefined} />
                  </motion.div>
                )}
              </AnimatePresence>
              <motion.div initial={false} animate={title} transition={sp} style={{ position: "absolute", left: 0, top: 0, height: TITLE_LH }}>
                <ShimmerTitle
                  text={zh ? "立即开始" : "Get Started"}
                  shimmer={ctx.b("shimmer") && !expanded}
                  fps={ctx.isPreview ? 30 : undefined}
                  labelRef={labelRef}
                />
              </motion.div>
            </motion.div>
            {/* Pill hit area */}
            {!expanded && (
              <div
                onPointerDown={() => setPressed(true)}
                onPointerUp={() => setPressed(false)}
                onPointerLeave={() => setPressed(false)}
                onPointerCancel={() => setPressed(false)}
                onClick={userExpand}
                style={{ position: "absolute", left: pillLeft, top: PILL_TOP, width: pillW, height: PILL_H, borderRadius: 28, cursor: "pointer" }}
              />
            )}
            {/* Sheet body */}
            <AnimatePresence initial={false}>
              {expanded && (
                <motion.div key="close" {...fade} style={{ position: "absolute", right: 12 + 18, top: SHEET_TOP + 18 }}>
                  <button
                    type="button"
                    onClick={userToggle}
                    style={{ width: 26, height: 26, borderRadius: "50%", background: black(0.08), display: "grid", placeItems: "center", color: Signature.ink, cursor: "pointer" }}
                  >
                    <X size={12} strokeWidth={3.2} />
                  </button>
                </motion.div>
              )}
            </AnimatePresence>
            {expanded && (
              <div style={{ position: "absolute", left: 12 + 18, width: CARD_W - 24 - 36, top: SHEET_TOP + 18 + 26 + 12, display: "flex", flexDirection: "column", gap: 12, pointerEvents: "none" }}>
                {FIELDS.map((f, index) => (
                  <motion.div
                    key={index}
                    initial={{ opacity: 0, y: 10 }}
                    animate={{ opacity: showBody ? 1 : 0, y: showBody ? 0 : 10 }}
                    transition={delayed(spring(0.4, 0.8), index * 0.05)}
                  >
                    <Field icon={f.icon} title={zh ? f.zh : f.en} />
                  </motion.div>
                ))}
                <motion.div
                  initial={{ opacity: 0, y: 10 }}
                  animate={{ opacity: showBody ? 1 : 0, y: showBody ? 0 : 10 }}
                  transition={delayed(spring(0.4, 0.8), 0.15)}
                  style={{ height: 42, borderRadius: 21, background: Signature.accentGradient, display: "grid", placeItems: "center", fontFamily: fonts.rounded, fontSize: 14, fontWeight: 700, color: "#fff" }}
                >
                  {zh ? "开始规划" : "Start planning"}
                </motion.div>
              </div>
            )}
          </div>
          <SignatureRim radius={30} />
        </div>
        <DemoHint ctx={ctx} en="Tap Get Started, then ✕ to close" zh="点击「立即开始」，再点 ✕ 收起" />
      </div>
    </SignatureStage>
  );
}

const FIELDS = [
  { icon: Search, en: "Where to?", zh: "想去哪里？" },
  { icon: CalendarDays, en: "Jul 8 – Jul 12", zh: "7月8日 – 7月12日" },
  { icon: Users, en: "2 travelers", zh: "2 位旅客" },
];

function Field({ icon: Icon, title }: { icon: typeof Search; title: string }) {
  return (
    <div style={{ height: 36, borderRadius: 12, background: black(0.05), display: "flex", alignItems: "center", gap: 10, padding: "0 12px" }}>
      <span style={{ width: 18, display: "grid", placeItems: "center", color: Signature.accentHot }}>
        <Icon size={13} strokeWidth={2.6} fill={Icon === Users ? "currentColor" : "none"} />
      </span>
      <span style={{ fontFamily: fonts.text, fontSize: 13, fontWeight: 500, color: "rgb(11 11 13 / 0.75)" }}>{title}</span>
    </div>
  );
}

function Backdrop({ zh, dimmed, transition }: { zh: boolean; dimmed: boolean; transition: ReturnType<typeof spring> }) {
  return (
    <motion.div
      initial={false}
      animate={{ scale: dimmed ? 1.06 : 1, filter: dimmed ? "blur(6px) brightness(0.8)" : "blur(0px) brightness(1)" }}
      transition={transition}
      style={{ position: "absolute", inset: 0 }}
    >
      <LandscapeArt seed={0} />
      <div style={{ position: "absolute", inset: 0, background: `linear-gradient(transparent, ${black(0.88)})` }} />
      <div style={{ position: "absolute", inset: 0, padding: 22, paddingBottom: 106, display: "flex", flexDirection: "column", gap: 8 }}>
        <div style={signatureEyebrow()}>{zh ? "旅行 · 2026" : "Travel · 2026"}</div>
        <div style={{ flex: 1 }} />
        <div style={{ fontFamily: fonts.rounded, fontSize: 26, fontWeight: 700, color: "#fff", lineHeight: "31px", whiteSpace: "pre-line" }}>
          {zh ? "探索世界，\n按你的方式" : "Explore the world,\nyour way"}
        </div>
        <div style={{ fontFamily: fonts.text, fontSize: 13, fontWeight: 500, color: white(0.65), lineHeight: "16px" }}>
          {zh ? "规划路线、收藏灵感、随时出发。" : "Plan routes, save spots, go anytime."}
        </div>
      </div>
    </motion.div>
  );
}

/** The label with an orange band sweeping across it every 2.2 s. */
function ShimmerTitle({ text, shimmer, fps, labelRef }: { text: string; shimmer: boolean; fps?: number; labelRef: React.RefObject<HTMLSpanElement | null> }) {
  const t = useClock(shimmer, fps);
  const phase = (t % 2.2) / 2.2;
  const x = (-0.4 + 1.8 * phase) * 100;
  const style: React.CSSProperties = { fontFamily: fonts.rounded, fontSize: 17, fontWeight: 700, lineHeight: `${TITLE_LH}px`, whiteSpace: "nowrap" };
  return (
    <span style={{ position: "relative", display: "inline-block" }}>
      <span ref={labelRef} style={{ ...style, color: Signature.ink, display: "inline-block" }}>
        {text}
      </span>
      <AnimatePresence>
        {shimmer && (
          <motion.span
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            style={{
              ...style,
              position: "absolute",
              inset: 0,
              color: "transparent",
              backgroundImage: `linear-gradient(90deg, transparent ${x - 30}%, ${Signature.accent} ${x}%, transparent ${x + 30}%)`,
              WebkitBackgroundClip: "text",
              backgroundClip: "text",
            }}
          >
            {text}
          </motion.span>
        )}
      </AnimatePresence>
    </span>
  );
}

/** Lime badge whose arrow nudges right (ease-out) and springs back, forever (phaseAnimator). */
function ArrowBadge({ fps }: { fps?: number }) {
  const t = useClock(true, fps);
  const period = 0.35 + 0.65;
  const p = t % period;
  const x = p < 0.35 ? -2 + 6 * ease.out(progress(p, 0, 0.35)) : 4 - 6 * springAt(p - 0.35, 0.5, 0.55);
  return (
    <div style={{ width: 44, height: 44, borderRadius: "50%", background: Signature.lime, display: "grid", placeItems: "center", color: "#000" }}>
      <ArrowRight size={18} strokeWidth={3} style={{ transform: `translateX(${x}px)` }} />
    </div>
  );
}
