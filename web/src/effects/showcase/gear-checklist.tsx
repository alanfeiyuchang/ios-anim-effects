/** showcase.gear-checklist · 装备清单 (Sport+GearChecklist.swift) */
import { AnimatePresence, animate, motion, useAnimationControls, useMotionValue, useMotionValueEvent } from "motion/react";
import { Backpack, Check, Coffee, Glasses, Hand, Radio, ShieldHalf, type LucideIcon } from "lucide-react";
import { useEffect, useRef, useState } from "react";
import { DemoHint, NumericText, anim, delayed, fonts, spring, springDB, useAutoplay, useHaptics, useTimeouts, white, type DemoProps } from "../../kit";
import { Signature, SignatureRim, SignatureStage, signatureCard, signatureNumber } from "./signature";
import { SportEyebrowRow, SportPress } from "./_a-sport";

const ITEMS: { id: number; icon: LucideIcon; fill: boolean; name: [string, string]; detail: [string, string] }[] = [
  { id: 0, icon: ShieldHalf, fill: false, name: ["Helmet", "头盔"], detail: ["Size M · MIPS", "M 码 · MIPS"] },
  { id: 1, icon: Glasses, fill: false, name: ["Goggles", "雪镜"], detail: ["Low-light lens", "弱光镜片"] },
  { id: 2, icon: Hand, fill: false, name: ["Gloves", "手套"], detail: ["Gore-Tex shell", "Gore-Tex 外层"] },
  { id: 3, icon: Radio, fill: false, name: ["Avalanche beacon", "雪崩信标"], detail: ["Battery 92%", "电量 92%"] },
  { id: 4, icon: Coffee, fill: false, name: ["Thermos", "保温壶"], detail: ["Hot ginger tea", "热姜茶"] },
];

/* Fixed layout (card coordinates): padding 14, a 52 pt header, 10 pt gap, 38 pt rows 2 pt apart. */
const tileCenter = (id: number) => ({ x: 14 + 8 + 14, y: 14 + 52 + 10 + id * 40 + 19 });
const RING_CENTER = { x: 292 - 14 - 4 - 26, y: 14 + 26 };

type Flight = { id: number; item: number };

export default function GearChecklist({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const { after } = useTimeouts();
  const [checked, setChecked] = useState<Set<number>>(() => new Set([1]));
  const [landed, setLanded] = useState<Set<number>>(() => new Set([1]));
  const [flights, setFlights] = useState<Flight[]>([]);
  const [hits, setHits] = useState(0);
  const serial = useRef(0);
  const checkedRef = useRef(checked);
  checkedRef.current = checked;
  const landedRef = useRef(landed);
  landedRef.current = landed;
  const zh = ctx.lang === "zh";
  const allPacked = landed.size === ITEMS.length;
  const duration = Math.max(ctx.n("flight"), 0.1);

  const launch = (id: number, muted: boolean) => {
    const flight = { id: ++serial.current, item: id };
    setFlights((f) => [...f, flight]);
    after(duration, () => {
      setFlights((f) => f.filter((x) => x.id !== flight.id));
      if (!checkedRef.current.has(id)) return;
      const wasPacked = landedRef.current.size === ITEMS.length;
      const next = new Set(landedRef.current);
      next.add(id);
      landedRef.current = next;
      setLanded(next);
      setHits((h) => h + 1);
      if (!muted && next.size === ITEMS.length && !wasPacked) haptics.success();
    });
  };

  const toggle = (id: number, muted = false) => {
    if (checkedRef.current.has(id)) {
      const c = new Set(checkedRef.current);
      c.delete(id);
      const l = new Set(landedRef.current);
      l.delete(id);
      checkedRef.current = c;
      landedRef.current = l;
      setChecked(c);
      setLanded(l);
    } else {
      const c = new Set(checkedRef.current);
      c.add(id);
      checkedRef.current = c;
      setChecked(c);
      launch(id, muted);
    }
    haptics.tap("light");
  };

  useAutoplay(
    ctx.isPreview,
    () => {
      const next = ITEMS.find((i) => !checkedRef.current.has(i.id));
      if (next) toggle(next.id, true);
      else {
        checkedRef.current = new Set();
        landedRef.current = new Set();
        setChecked(new Set());
        setLanded(new Set());
      }
    },
    { every: 1.1, delay: 0.6 },
  );

  return (
    <SignatureStage>
      <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center" }}>
        <div style={{ flex: 1 }} />
        <div style={{ ...signatureCard(), padding: 14, width: 292, display: "flex", flexDirection: "column", gap: 10 }}>
          <div style={{ display: "flex", alignItems: "center", gap: 12, padding: "0 4px", height: 52 }}>
            <div style={{ display: "flex", flexDirection: "column", gap: 4, flex: 1 }}>
              <SportEyebrowRow title={ctx.t("Summit kit", "登顶装备")} icon={<Backpack size={10} fill="currentColor" strokeWidth={1.5} />} />
              <div style={{ position: "relative", height: 23 }}>
                <AnimatePresence initial={false}>
                  <motion.span
                    key={allPacked ? "done" : "pack"}
                    initial={{ opacity: 0 }}
                    animate={{ opacity: 1 }}
                    exit={{ opacity: 0 }}
                    transition={spring(0.4, 0.75)}
                    style={{ position: "absolute", left: 0, top: 0, whiteSpace: "nowrap", fontFamily: fonts.rounded, fontSize: 19, fontWeight: 700, color: "#fff", lineHeight: "23px" }}
                  >
                    {allPacked ? (zh ? "装备齐全" : "All packed") : zh ? "整理装备" : "Pack your gear"}
                  </motion.span>
                </AnimatePresence>
              </div>
            </div>
            <Ring count={landed.size} total={ITEMS.length} hits={hits} />
          </div>
          <div style={{ display: "flex", flexDirection: "column", gap: 2 }}>
            {ITEMS.map((item) => {
              const on = checked.has(item.id);
              const Icon = item.icon;
              return (
                <SportPress key={item.id} scale={0.97} dim={0.04} radius={12} onClick={() => toggle(item.id)}>
                  <motion.div
                    initial={false}
                    animate={{ backgroundColor: white(on ? 0 : 0.035) }}
                    transition={spring(0.35, 0.7)}
                    style={{ display: "flex", alignItems: "center", gap: 11, padding: "0 8px", height: 38, borderRadius: 12 }}
                  >
                    <motion.span
                      initial={false}
                      animate={{ color: on ? Signature.accent : white(0.85), backgroundColor: white(on ? 0.04 : 0.08) }}
                      transition={spring(0.35, 0.7)}
                      style={{ width: 28, height: 28, borderRadius: 8, display: "grid", placeItems: "center", flexShrink: 0 }}
                    >
                      <Icon size={14} strokeWidth={2.4} fill={item.fill ? "currentColor" : "none"} />
                    </motion.span>
                    <div style={{ display: "flex", flexDirection: "column", gap: 1, flex: 1, minWidth: 0 }}>
                      <motion.span
                        initial={false}
                        animate={{ color: white(on ? 0.45 : 1) }}
                        transition={spring(0.35, 0.7)}
                        style={{
                          fontFamily: fonts.rounded,
                          fontSize: 14,
                          fontWeight: 600,
                          lineHeight: "17px",
                          whiteSpace: "nowrap",
                          textDecorationLine: ctx.b("strike") && on ? "line-through" : "none",
                          textDecorationColor: white(0.45),
                        }}
                      >
                        {item.name[zh ? 1 : 0]}
                      </motion.span>
                      <span style={{ fontFamily: fonts.rounded, fontSize: 10, fontWeight: 500, color: Signature.textSecondary, lineHeight: "12px" }}>{item.detail[zh ? 1 : 0]}</span>
                    </div>
                    <CheckMark checked={on} />
                  </motion.div>
                </SportPress>
              );
            })}
          </div>
          <div style={{ position: "absolute", inset: 0, pointerEvents: "none" }}>
            {flights.map((f) => (
              <Flyer key={f.id} item={f.item} duration={duration} arc={ctx.n("arc")} />
            ))}
          </div>
          <SignatureRim />
        </div>
        <div style={{ flex: 1 }} />
        <DemoHint ctx={ctx} en="Tap items to pack them" zh="点击物品即可打包" style={{ paddingBottom: 14 }} />
      </div>
    </SignatureStage>
  );
}

function Flyer({ item, duration, arc }: { item: number; duration: number; arc: number }) {
  const p = useMotionValue(0);
  const [t, setT] = useState(0);
  useMotionValueEvent(p, "change", setT);
  useEffect(() => {
    const a = animate(p, 1, anim.curve(0.3, 0, 0.2, 1, duration));
    return () => a.stop();
  }, [p, duration]);
  const from = tileCenter(item);
  const to = RING_CENTER;
  const c = { x: (from.x + to.x) / 2, y: Math.min(from.y, to.y) - arc };
  const u = 1 - t;
  const x = u * u * from.x + 2 * u * t * c.x + t * t * to.x;
  const y = u * u * from.y + 2 * u * t * c.y + t * t * to.y;
  const Icon = ITEMS[item].icon;
  return (
    <div
      style={{
        position: "absolute",
        left: x - 14,
        top: y - 14,
        width: 28,
        height: 28,
        borderRadius: 8,
        display: "grid",
        placeItems: "center",
        color: Signature.accent,
        background: "rgb(255 138 31 / 0.18)",
        boxShadow: "0 0 6px rgb(255 138 31 / 0.5)",
        transform: `scale(${1 - 0.5 * t})`,
        opacity: t > 0.92 ? (1 - t) / 0.08 : 1,
      }}
    >
      <Icon size={14} strokeWidth={2.4} fill={ITEMS[item].fill ? "currentColor" : "none"} />
    </div>
  );
}

function Ring({ count, total, hits }: { count: number; total: number; hits: number }) {
  const done = count === total;
  const frac = useMotionValue(count / total);
  const [f, setF] = useState(count / total);
  useMotionValueEvent(frac, "change", setF);
  useEffect(() => {
    animate(frac, count / total, spring(0.5, 0.75));
  }, [count, total, frac]);
  const gulp = useAnimationControls();
  const first = useRef(true);
  useEffect(() => {
    if (first.current) {
      first.current = false;
      return;
    }
    void (async () => {
      await gulp.start({ scale: 1.14, transition: { duration: 0.1, ease: [0.42, 0, 0.58, 1] } });
      await gulp.start({ scale: 1, transition: springDB(0.4, 0.3) });
    })();
  }, [hits, gulp]);
  const r = 26;
  const c = 2 * Math.PI * r;
  const color = done ? Signature.lime : "url(#gear-ring)";
  return (
    <motion.div animate={gulp} style={{ flexShrink: 0 }}>
      <motion.div animate={{ scale: done ? 1.08 : 1 }} transition={spring(0.4, 0.55)} style={{ position: "relative", width: 52, height: 52 }}>
        <svg width={52} height={52} style={{ position: "absolute", inset: 0, overflow: "visible" }}>
          <circle cx={26} cy={26} r={r} fill="none" stroke={white(0.1)} strokeWidth={5} />
        </svg>
        <svg
          width={52}
          height={52}
          style={{ position: "absolute", inset: 0, overflow: "visible", transform: "rotate(-90deg)", filter: `drop-shadow(0 0 5px ${done ? "rgb(200 245 96 / 0.6)" : "rgb(255 138 31 / 0.6)"})` }}
        >
          <defs>
            <linearGradient id="gear-ring" x1="0" y1="0" x2="1" y2="1">
              <stop offset="0" stopColor={Signature.accentSoft} />
              <stop offset="0.5" stopColor={Signature.accent} />
              <stop offset="1" stopColor={Signature.accentHot} />
            </linearGradient>
          </defs>
          {f > 0.002 && <circle cx={26} cy={26} r={r} fill="none" stroke={color} strokeWidth={5} strokeLinecap="round" strokeDasharray={`${Math.min(f, 1) * c} ${c}`} />}
        </svg>
        <AnimatePresence initial={false}>
          {done ? (
            <motion.div
              key="check"
              initial={{ scale: 0.3, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              exit={{ scale: 0.3, opacity: 0 }}
              transition={spring(0.4, 0.55)}
              style={{ position: "absolute", inset: 0, display: "grid", placeItems: "center", color: Signature.lime }}
            >
              <Check size={19} strokeWidth={4} />
            </motion.div>
          ) : (
            <motion.div
              key="count"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              transition={spring(0.4, 0.55)}
              style={{ position: "absolute", inset: 0, display: "grid", placeItems: "center" }}
            >
              <span style={{ ...signatureNumber(14), color: "#fff", display: "inline-flex" }}>
                <NumericText value={count} />/{total}
              </span>
            </motion.div>
          )}
        </AnimatePresence>
      </motion.div>
    </motion.div>
  );
}

function CheckMark({ checked }: { checked: boolean }) {
  const t = spring(0.35, 0.6);
  return (
    <div style={{ position: "relative", width: 22, height: 22, flexShrink: 0 }}>
      <motion.div
        initial={false}
        animate={{ boxShadow: `inset 0 0 0 1.5px ${white(checked ? 0 : 0.28)}` }}
        transition={t}
        style={{ position: "absolute", inset: 0, borderRadius: "50%" }}
      />
      <motion.div
        initial={false}
        animate={{ scale: checked ? 1 : 0.2, opacity: checked ? 1 : 0 }}
        transition={t}
        style={{ position: "absolute", inset: 0, borderRadius: "50%", background: Signature.accentGradient, boxShadow: "0 0 5px rgb(255 138 31 / 0.6)" }}
      />
      <svg width={10} height={8} viewBox="0 0 10 8" style={{ position: "absolute", left: 6, top: 7, overflow: "visible" }}>
        <motion.path
          d="M0 4 L3.8 8 L10 0"
          fill="none"
          stroke={Signature.ink}
          strokeWidth={2.2}
          strokeLinecap="round"
          strokeLinejoin="round"
          initial={false}
          animate={{ pathLength: checked ? 1 : 0, opacity: checked ? 1 : 0 }}
          transition={checked ? delayed(anim.easeOut(0.22), 0.08) : anim.easeIn(0.1)}
        />
      </svg>
    </div>
  );
}
