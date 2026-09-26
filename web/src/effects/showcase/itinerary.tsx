/** showcase.itinerary · 行程时间线 (TravelItinerary.swift) */
import { motion } from "motion/react";
import { Car, ChevronDown, Footprints, PlaneLanding, Sailboat, type LucideIcon } from "lucide-react";
import { useLayoutEffect, useRef, useState } from "react";
import { DemoHint, anim, delayed, fonts, hex, spring, useAutoplay, useHaptics, white, type DemoProps } from "../../kit";
import { LandscapeArt, Signature, SignatureRim, SignatureStage, signatureCard, signatureEyebrow } from "./signature";

const STOPS: { en: string; zh: string; titleEn: string; titleZh: string; detailEn: string; detailZh: string; icon: LucideIcon; tint: string }[] = [
  { en: "Day 1", zh: "第 1 天", titleEn: "Land in Venice", titleZh: "抵达威尼斯", detailEn: "08:30 · MU 7123", detailZh: "08:30 · MU 7123", icon: PlaneLanding, tint: Signature.accent },
  { en: "Day 2", zh: "第 2 天", titleEn: "Drive to Braies", titleZh: "自驾前往布拉耶斯", detailEn: "3h 10m · 190 km", detailZh: "3 小时 10 分 · 190 公里", icon: Car, tint: "#5AC8FA" },
  { en: "Day 3", zh: "第 3 天", titleEn: "Sunrise rowboat", titleZh: "日出湖上划船", detailEn: "05:40 · Boathouse", detailZh: "05:40 · 船屋码头", icon: Sailboat, tint: Signature.lime },
  { en: "Day 4", zh: "第 4 天", titleEn: "Seceda ridge hike", titleZh: "塞切达山脊徒步", detailEn: "12 km · 5h", detailZh: "12 公里 · 5 小时", icon: Footprints, tint: Signature.accentSoft },
];
const COUNT = STOPS.length;

export default function Itinerary({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const zh = ctx.lang === "zh";
  const [open, setOpen] = useState(false);
  const rowsRef = useRef<HTMLDivElement>(null);
  const [rowsHeight, setRowsHeight] = useState(234);
  useLayoutEffect(() => {
    if (rowsRef.current) setRowsHeight(rowsRef.current.offsetHeight);
  }, [zh]);

  const stagger = ctx.n("stagger");
  const closeDuration = (COUNT - 1) * stagger * 0.6 + 0.2;
  const delayFor = (index: number) => (open || !ctx.b("reverse") ? index * stagger : (COUNT - 1 - index) * stagger * 0.6);

  const toggle = () => {
    haptics.tap();
    setOpen((o) => !o);
  };
  useAutoplay(ctx.isPreview, toggle, { every: 2.6, delay: 0.3 });

  const summaryT = delayed(anim.easeInOut(0.25), open ? 0 : closeDuration);
  const rowsT = delayed(spring(0.45, 0.86), open ? 0 : closeDuration);

  return (
    <SignatureStage>
      <div style={{ position: "absolute", inset: 0, paddingTop: ctx.isPreview ? 6 : 26, display: "flex", flexDirection: "column", alignItems: "center" }}>
        <div onClick={toggle} style={{ ...signatureCard(26), width: 290, padding: 18, flexShrink: 0, cursor: "pointer" }}>
          {/* header */}
          <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
            <div style={{ position: "relative", width: 44, height: 44, borderRadius: 12, overflow: "hidden", flexShrink: 0 }}>
              <LandscapeArt seed={2} />
            </div>
            <div style={{ display: "flex", flexDirection: "column", gap: 2 }}>
              <span style={signatureEyebrow()}>{zh ? "旅行手账" : "Trip journal"}</span>
              <span style={{ fontFamily: fonts.rounded, fontSize: 15, fontWeight: 700, color: "#fff", lineHeight: "19px" }}>{zh ? "布拉耶斯湖 · 4 天" : "Lago di Braies · 4 days"}</span>
            </div>
            <div style={{ flex: 1 }} />
            <motion.div
              initial={false}
              animate={{ rotate: open ? 180 : 0 }}
              transition={spring(0.4, 0.7)}
              style={{ width: 28, height: 28, borderRadius: "50%", background: white(0.1), display: "grid", placeItems: "center", color: "#fff", flexShrink: 0 }}
            >
              <ChevronDown size={14} strokeWidth={3} />
            </motion.div>
          </div>
          {/* collapsed summary */}
          <motion.div initial={false} animate={{ height: open ? 0 : 38 }} transition={summaryT} style={{ overflow: "hidden" }}>
            <motion.div
              initial={false}
              animate={{ opacity: open ? 0 : 1, y: open ? -38 : 0 }}
              transition={summaryT}
              style={{ paddingTop: 14, display: "flex", alignItems: "center", gap: 6 }}
            >
              {STOPS.map((stop, i) => (
                <span key={i} style={{ width: 24, height: 24, borderRadius: "50%", background: hex(stop.tint, 0.16), color: stop.tint, display: "grid", placeItems: "center", flexShrink: 0 }}>
                  <stop.icon size={11} strokeWidth={2.8} />
                </span>
              ))}
              <span style={{ paddingLeft: 4, fontFamily: fonts.rounded, fontSize: 12, fontWeight: 600, color: Signature.textSecondary, whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>
                {zh ? "4 站 · 威尼斯 → 塞切达" : "4 stops · Venice → Seceda"}
              </span>
            </motion.div>
          </motion.div>
          {/* timeline */}
          <motion.div initial={false} animate={{ height: open ? rowsHeight : 0 }} transition={rowsT} style={{ overflow: "hidden" }}>
            <div ref={rowsRef} style={{ paddingTop: 14, display: "flex", flexDirection: "column" }}>
              {STOPS.map((stop, index) => (
                <Row key={index} stop={stop} zh={zh} isLast={index === COUNT - 1} visible={open} delay={delayFor(index)} response={ctx.n("response")} />
              ))}
            </div>
          </motion.div>
          <SignatureRim radius={26} />
        </div>
        <div style={{ flex: 1 }} />
        <DemoHint ctx={ctx} en="Tap the card to fold or unfold" zh="点击卡片展开或收起" style={{ paddingBottom: 14 }} />
      </div>
    </SignatureStage>
  );
}

function Row({ stop, zh, isLast, visible, delay, response }: { stop: (typeof STOPS)[number]; zh: boolean; isLast: boolean; visible: boolean; delay: number; response: number }) {
  const pop = delayed(spring(response, 0.78), delay);
  const Icon = stop.icon;
  return (
    <div style={{ display: "flex", alignItems: "flex-start", gap: 12 }}>
      <div style={{ display: "flex", flexDirection: "column", alignItems: "center", flexShrink: 0 }}>
        <motion.div
          initial={false}
          animate={{ scale: visible ? 1 : 0.2, opacity: visible ? 1 : 0 }}
          transition={pop}
          style={{ width: 30, height: 30, borderRadius: "50%", background: hex(stop.tint, 0.18), boxShadow: `inset 0 0 0 1px ${hex(stop.tint, 0.4)}`, color: stop.tint, display: "grid", placeItems: "center" }}
        >
          <Icon size={13} strokeWidth={2.8} />
        </motion.div>
        {!isLast && (
          <motion.div
            initial={false}
            animate={{ scaleY: visible ? 1 : 0 }}
            transition={delayed(anim.easeOut(0.28), delay + 0.1)}
            style={{ width: 2, height: 24, margin: "2px 0", borderRadius: 1, transformOrigin: "50% 0%", background: `linear-gradient(${hex(stop.tint, 0.7)}, ${white(0.08)})` }}
          />
        )}
      </div>
      <motion.div
        initial={false}
        animate={{ opacity: visible ? 1 : 0, x: visible ? 0 : -14, filter: visible ? "blur(0px)" : "blur(4px)" }}
        transition={pop}
        style={{ display: "flex", flexDirection: "column", gap: 2, minWidth: 0 }}
      >
        <span style={signatureEyebrow()}>{zh ? stop.zh : stop.en}</span>
        <span style={{ fontFamily: fonts.rounded, fontSize: 14, fontWeight: 600, color: "#fff", lineHeight: "17px", whiteSpace: "nowrap" }}>{zh ? stop.titleZh : stop.titleEn}</span>
        <span style={{ fontFamily: fonts.text, fontSize: 11, fontWeight: 500, color: Signature.textSecondary, lineHeight: "13px", whiteSpace: "nowrap" }}>{zh ? stop.detailZh : stop.detailEn}</span>
      </motion.div>
    </div>
  );
}
