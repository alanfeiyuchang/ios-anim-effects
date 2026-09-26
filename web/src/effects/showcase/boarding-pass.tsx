/** showcase.boarding-pass · 登机牌撕票 (TravelBoardingPass.swift) */
import { AnimatePresence, motion, type Transition } from "motion/react";
import { ChevronsDown, Plane, Scissors } from "lucide-react";
import { useId, useRef, useState, type ReactNode } from "react";
import { DemoHint, anim, fonts, spring, useAutoplay, useHaptics, usePan, useTimeouts, type DemoProps } from "../../kit";
import { Signature, SignatureStage, signatureEyebrow, signatureNumber } from "./signature";

const W = 270;
const MAIN_H = 168;
const STUB_H = 74;
const INK = (a: number) => `rgb(11 11 13 / ${a})`;
const mono = fonts.mono;

type Pull = { x: number; y: number };
type Phase = "drag" | "release" | "tear" | "reset" | "auto";

export default function BoardingPass({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const { after } = useTimeouts();
  const zh = ctx.lang === "zh";
  const threshold = ctx.n("threshold");
  const flipDuration = ctx.n("flip");
  const [pull, setPull] = useState<Pull>({ x: 0, y: 0 });
  const [phase, setPhase] = useState<Phase>("release");
  const [armed, setArmed] = useState(false);
  const [torn, setTorn] = useState(false);
  const [regrowing, setRegrowing] = useState(false);
  const [flipped, setFlipped] = useState(false);
  const step = useRef(0);
  const state = useRef({ torn: false, regrowing: false, armed: false, flipped: false, pull: { x: 0, y: 0 } });
  state.current.flipped = flipped;

  const tear = (silent = false) => {
    if (!silent) haptics.success();
    state.current.torn = true;
    setPhase("tear");
    setTorn(true);
    after(1.3, () => {
      state.current = { ...state.current, torn: false, regrowing: true, armed: false, pull: { x: 0, y: 0 } };
      setPhase("reset");
      setRegrowing(true);
      setTorn(false);
      setPull({ x: 0, y: 0 });
      setArmed(false);
      after(0.04, () => {
        state.current.regrowing = false;
        setRegrowing(false);
      });
    });
  };

  const flip = () => {
    haptics.tap();
    setFlipped((f) => !f);
  };

  const pan = usePan({
    onChange: ({ translation }) => {
      const s = state.current;
      if (s.torn || s.regrowing) return;
      // While flipped the stub sits inside a 180° Y rotation, so un-mirror the horizontal drift.
      const dx = s.flipped ? -translation.x : translation.x;
      const next = { x: dx, y: Math.max(0, translation.y) * 0.85 };
      s.pull = next;
      setPhase("drag");
      setPull(next);
      const crossed = next.y > threshold;
      if (crossed !== s.armed) {
        s.armed = crossed;
        setArmed(crossed);
        haptics.tap("rigid");
      }
    },
    onEnd: () => {
      const s = state.current;
      if (s.torn || s.regrowing) return;
      if (s.pull.y > threshold) tear();
      else {
        setPhase("release");
        s.pull = { x: 0, y: 0 };
        setPull({ x: 0, y: 0 });
      }
      s.armed = false;
      setArmed(false);
    },
  });

  useAutoplay(
    ctx.isPreview,
    () => {
      if (step.current % 3 === 0) {
        setPhase("auto");
        const p = { x: 14, y: threshold * 0.75 };
        state.current.pull = p;
        setPull(p);
        after(0.5, () => tear(true));
      } else flip();
      step.current += 1;
    },
    { every: 2.6, delay: 0.5 },
  );

  const angle = torn ? ctx.n("spin") : (Math.min(pull.y, threshold) / Math.max(threshold, 1)) * 6 + pull.x * 0.04;
  const offX = torn ? pull.x * 0.3 + 30 : pull.x * 0.3;
  const offY = torn ? 420 : pull.y;
  const moveT: Transition =
    phase === "drag" || phase === "reset"
      ? { duration: 0 }
      : phase === "tear"
        ? anim.easeIn(0.6)
        : phase === "auto"
          ? spring(0.45, 0.8)
          : spring(0.4, 0.55);
  const regrowT: Transition = regrowing ? { duration: 0 } : spring(0.5, 0.7);

  return (
    <SignatureStage>
      <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center" }}>
        <div style={{ perspective: 450 }}>
          <motion.div
            initial={false}
            animate={{ rotateY: flipped ? 180 : 0 }}
            transition={anim.easeInOut(flipDuration)}
            style={{ display: "flex", flexDirection: "column", transformStyle: "flat" }}
          >
            <div onClick={flip} style={{ position: "relative", zIndex: 1, cursor: "pointer" }}>
              <TicketPiece height={MAIN_H} perforationOnTop={false} from={Signature.paper} to="#E6E2D9" shadow="drop-shadow(0 8px 8px rgb(0 0 0 / 0.4))">
                <Faces flipped={flipped} delay={flipDuration / 2} front={<MainFront zh={zh} />} back={<MainBack zh={zh} />} />
              </TicketPiece>
            </div>
            {/* stub: scale (anchor top) ∘ offset ∘ rotation (anchor top-leading) */}
            <motion.div
              initial={false}
              animate={{ scale: regrowing ? 0.9 : 1, opacity: regrowing ? 0 : 1 }}
              transition={regrowT}
              style={{ position: "relative", zIndex: 2, transformOrigin: "50% 0%" }}
            >
              <motion.div initial={false} animate={{ x: offX, y: offY }} transition={moveT}>
                <motion.div
                  initial={false}
                  animate={{ rotate: angle }}
                  transition={moveT}
                  {...pan}
                  style={{ transformOrigin: "0% 0%", touchAction: "none", cursor: "grab" }}
                >
                  <TicketPiece height={STUB_H} perforationOnTop from="#E9E5DC" to="#DDD8CD" shadow="drop-shadow(0 6px 6px rgb(0 0 0 / 0.35))">
                    <Faces flipped={flipped} delay={flipDuration / 2} front={<StubFront zh={zh} armed={armed} />} back={<StubBack zh={zh} />} />
                    <svg width={W - 32} height={2} style={{ position: "absolute", left: 16, top: -0.5 }}>
                      <line x1={0} y1={1} x2={W - 32} y2={1} stroke={INK(0.25)} strokeWidth={1.2} strokeDasharray="4 4" />
                    </svg>
                  </TicketPiece>
                </motion.div>
              </motion.div>
            </motion.div>
          </motion.div>
        </div>
        <DemoHint ctx={ctx} en="Pull the stub down · tap to flip" zh="下拉票根撕下 · 点击翻面" style={{ paddingTop: 16 }} />
      </div>
    </SignatureStage>
  );
}

/** Front and back faces, swapped exactly at the midpoint of the flip. */
function Faces({ flipped, delay, front, back }: { flipped: boolean; delay: number; front: ReactNode; back: ReactNode }) {
  const swap: Transition = { duration: 0.001, delay };
  return (
    <>
      <motion.div initial={false} animate={{ opacity: flipped ? 0 : 1 }} transition={swap} style={{ position: "absolute", inset: 0 }}>
        {front}
      </motion.div>
      <motion.div initial={false} animate={{ opacity: flipped ? 1 : 0 }} transition={swap} style={{ position: "absolute", inset: 0, transform: "scaleX(-1)" }}>
        {back}
      </motion.div>
    </>
  );
}

/** A ticket piece: square corners and half-notches on the perforated edge, 20 pt corners elsewhere. */
function TicketPiece({ height, perforationOnTop, from, to, shadow, children }: { height: number; perforationOnTop: boolean; from: string; to: string; shadow: string; children: ReactNode }) {
  const id = useId().replace(/:/g, "");
  const r = 20;
  const n = 11;
  const d = perforationOnTop
    ? `M0 0 H${W} V${height - r} Q${W} ${height} ${W - r} ${height} H${r} Q0 ${height} 0 ${height - r} Z`
    : `M${r} 0 H${W - r} Q${W} 0 ${W} ${r} V${height} H0 V${r} Q0 0 ${r} 0 Z`;
  const y = perforationOnTop ? 0 : height;
  return (
    <div style={{ position: "relative", width: W, height }}>
      <svg width={W} height={height} style={{ position: "absolute", inset: 0, overflow: "visible", filter: shadow }}>
        <defs>
          <linearGradient id={`g${id}`} x1="0" y1="0" x2="0" y2="1">
            <stop offset="0" stopColor={from} />
            <stop offset="1" stopColor={to} />
          </linearGradient>
          <mask id={`m${id}`}>
            <rect x={-20} y={-20} width={W + 40} height={height + 40} fill="#fff" />
            <circle cx={0} cy={y} r={n} fill="#000" />
            <circle cx={W} cy={y} r={n} fill="#000" />
          </mask>
        </defs>
        <path d={d} fill={`url(#g${id})`} mask={`url(#m${id})`} />
      </svg>
      {children}
    </div>
  );
}

function MainFront({ zh }: { zh: boolean }) {
  const detail = (title: string, value: string) => (
    <div style={{ display: "flex", flexDirection: "column", gap: 2 }}>
      <span style={signatureEyebrow(true)}>{title}</span>
      <span style={{ ...signatureNumber(15), color: Signature.ink }}>{value}</span>
    </div>
  );
  const airport = (code: string, city: string, end: boolean) => (
    <div style={{ display: "flex", flexDirection: "column", alignItems: end ? "flex-end" : "flex-start" }}>
      <span style={{ fontFamily: fonts.rounded, fontSize: 32, fontWeight: 800, color: Signature.ink, lineHeight: "38px" }}>{code}</span>
      <span style={{ fontFamily: fonts.text, fontSize: 11, fontWeight: 500, color: INK(0.5), lineHeight: "13px" }}>{city}</span>
    </div>
  );
  const dot = <span style={{ width: 4, height: 4, borderRadius: 2, background: INK(0.3) }} />;
  return (
    <div style={{ position: "absolute", inset: 0, padding: 18, display: "flex", flexDirection: "column", justifyContent: "center", gap: 14 }}>
      <div style={{ display: "flex", alignItems: "center" }}>
        <span style={signatureEyebrow(true)}>{zh ? "登机牌" : "Boarding pass"}</span>
        <span style={{ flex: 1 }} />
        <span style={{ fontFamily: mono, fontSize: 11, fontWeight: 700, color: Signature.accentHot }}>MU 7123</span>
      </div>
      <div style={{ display: "flex", alignItems: "center" }}>
        {airport("HGH", zh ? "杭州" : "Hangzhou", false)}
        <span style={{ flex: 1 }} />
        <span style={{ display: "flex", alignItems: "center", gap: 4, color: Signature.accent }}>
          {dot}
          <Plane size={15} fill="currentColor" strokeWidth={1.5} style={{ transform: "rotate(45deg)" }} />
          {dot}
        </span>
        <span style={{ flex: 1 }} />
        {airport("NCE", zh ? "尼斯" : "Nice", true)}
      </div>
      <div style={{ display: "flex", justifyContent: "space-between" }}>
        {detail(zh ? "登机口" : "Gate", "B12")}
        {detail(zh ? "登机" : "Boards", "09:40")}
        {detail(zh ? "座位" : "Seat", "12A")}
      </div>
    </div>
  );
}

const BAR_WIDTHS = [1, 3, 1, 2, 4, 1, 1, 3, 2, 1, 2, 3, 1, 4, 2, 1];

function MainBack({ zh }: { zh: boolean }) {
  return (
    <div style={{ position: "absolute", inset: 0, padding: 18, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 10 }}>
      <div style={{ display: "flex", gap: 1.5, height: 70 }}>
        {Array.from({ length: 48 }, (_, i) => (
          <div key={i} style={{ width: BAR_WIDTHS[i % BAR_WIDTHS.length], background: Signature.ink }} />
        ))}
      </div>
      <span style={{ fontFamily: mono, fontSize: 11, fontWeight: 600, color: INK(0.6) }}>{zh ? "登机口扫码 · 12A" : "Scan at gate · 12A"}</span>
    </div>
  );
}

function StubFront({ zh, armed }: { zh: boolean; armed: boolean }) {
  return (
    <div style={{ position: "absolute", inset: 0, padding: "0 18px", display: "flex", alignItems: "center" }}>
      <div style={{ display: "flex", flexDirection: "column", gap: 3 }}>
        <span style={signatureEyebrow(true)}>{zh ? "登机组别" : "Boarding group"}</span>
        <span style={{ fontFamily: fonts.rounded, fontSize: 16, fontWeight: 700, color: Signature.ink, lineHeight: "19px" }}>{zh ? "A 组 · 12A" : "Group A · 12A"}</span>
      </div>
      <span style={{ flex: 1 }} />
      <span style={{ position: "relative", width: 18, height: 18, display: "grid", placeItems: "center" }}>
        <AnimatePresence mode="popLayout" initial={false}>
          <motion.span
            key={armed ? "cut" : "down"}
            initial={{ scale: 0.4, opacity: 0, filter: "blur(3px)" }}
            animate={{ scale: 1, opacity: 1, filter: "blur(0px)" }}
            exit={{ scale: 0.4, opacity: 0, filter: "blur(3px)" }}
            transition={anim.snappyD(0.3)}
            style={{ display: "grid", color: armed ? Signature.accentHot : INK(0.4) }}
          >
            {armed ? <Scissors size={15} strokeWidth={2.6} /> : <ChevronsDown size={16} strokeWidth={2.8} />}
          </motion.span>
        </AnimatePresence>
      </span>
    </div>
  );
}

function StubBack({ zh }: { zh: boolean }) {
  return (
    <div style={{ position: "absolute", inset: 0, padding: "0 18px", display: "flex", alignItems: "center" }}>
      <span style={{ fontFamily: fonts.rounded, fontSize: 12, fontWeight: 600, color: INK(0.55) }}>{zh ? "请保留此票根" : "Keep this stub"}</span>
      <span style={{ flex: 1 }} />
      <span style={{ fontFamily: mono, fontSize: 12, fontWeight: 700, color: Signature.accentHot }}>SEQ 042</span>
    </div>
  );
}
