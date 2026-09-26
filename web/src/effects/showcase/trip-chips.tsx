/** showcase.trip-chips · 行程筛选标签 (TravelTripChips.swift) */
import { motion, type Transition } from "motion/react";
import { Earth, Footprints, MoonStar, Waves, type LucideIcon } from "lucide-react";
import { useCallback, useState } from "react";
import { DemoHint, NumericText, anim, delayed, fonts, spring, useAutoplay, useHaptics, white, black, type DemoProps } from "../../kit";
import { LandscapeArt, Signature, SignatureRim, SignatureStage, signatureCard, signatureNumber } from "./signature";

type Kind = 0 | 1 | 2 | 3; // all, trails, nights, lakes

const KINDS: { en: string; zh: string; icon: LucideIcon }[] = [
  { en: "All", zh: "全部", icon: Earth },
  { en: "Trails", zh: "步道", icon: Footprints },
  { en: "Nights", zh: "夜景", icon: MoonStar },
  { en: "Lakes", zh: "湖泊", icon: Waves },
];

const SPOTS: { id: string; en: string; zh: string; metaEn: string; metaZh: string; kind: Kind; seed: number }[] = [
  { id: "nordkette", en: "Nordkette", zh: "北链山", metaEn: "12 km · 5h", metaZh: "12 公里 · 5 小时", kind: 1, seed: 0 },
  { id: "azure", en: "Azure Coast", zh: "蔚蓝海岸", metaEn: "Sunset cruise", metaZh: "日落航线", kind: 2, seed: 1 },
  { id: "braies", en: "Lago di Braies", zh: "布拉耶斯湖", metaEn: "Rowboats", metaZh: "湖上划船", kind: 3, seed: 2 },
  { id: "canyon", en: "Red Canyon", zh: "红岩峡谷", metaEn: "8 km · 3h", metaZh: "8 公里 · 3 小时", kind: 1, seed: 3 },
  { id: "aurora", en: "Aurora Camp", zh: "极光营地", metaEn: "Stargazing", metaZh: "观星露营", kind: 2, seed: 4 },
  { id: "glacier", en: "Glacier Bay", zh: "冰川湾", metaEn: "Kayak · 2 days", metaZh: "皮划艇 · 2 天", kind: 3, seed: 7 },
];

const spotsFor = (kind: Kind) => (kind === 0 ? SPOTS : SPOTS.filter((s) => s.kind === kind));

const GRID_W = 278;
const GAP = 8;
const TILE_H = 92;
const TILE_W = (GRID_W - GAP * 2) / 3;
/** Chip width inside the 278 pt track (4 pt padding, 4 pt gaps). */
const CHIP_W = (GRID_W - 8 - 12) / 4;
const NO_ANIM: Transition = { duration: 0 };

export default function TripChips({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [selected, setSelected] = useState<Kind>(0);
  const [previous, setPrevious] = useState<Kind>(0);
  const zh = ctx.lang === "zh";
  const sp = spring(ctx.n("response"), ctx.n("damping"));
  const visible = spotsFor(selected);

  const select = useCallback(
    (kind: Kind) => {
      if (kind === selected) return;
      haptics.selection();
      setPrevious(selected);
      setSelected(kind);
    },
    [selected, haptics],
  );

  useAutoplay(ctx.isPreview, () => select(((selected + 1) % 4) as Kind), { every: 1.7 });

  const now = visible.map((s) => s.id);
  const before = spotsFor(previous).map((s) => s.id);

  return (
    <SignatureStage>
      <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center" }}>
        <div style={{ flex: 1 }} />
        <div style={{ ...signatureCard(26), width: 310, padding: 16, display: "flex", flexDirection: "column", gap: 14, flexShrink: 0 }}>
          {/* header */}
          <div style={{ display: "flex", alignItems: "center" }}>
            <div style={{ display: "flex", alignItems: "center", gap: 6 }}>
              <span style={{ fontFamily: fonts.rounded, fontSize: 19, fontWeight: 700, color: "#fff", lineHeight: "23px" }}>{zh ? "轻松规划" : "Plan Trips With"}</span>
              <span style={{ fontFamily: fonts.rounded, fontSize: 13, fontWeight: 800, color: "#000", padding: "3px 8px", borderRadius: 99, background: Signature.lime, lineHeight: "16px" }}>
                {zh ? "旅程" : "Ease"}
              </span>
            </div>
            <div style={{ flex: 1 }} />
            <span style={{ ...signatureNumber(13), color: Signature.textSecondary, display: "inline-flex", gap: zh ? 3 : 4 }}>
              <NumericText value={visible.length} />
              <span>{zh ? "处" : "spots"}</span>
            </span>
          </div>
          {/* chips */}
          {/* One pill glides behind the selected chip (matchedGeometryEffect; positioned analytically, see CHIP_W). */}
          <div style={{ position: "relative", display: "flex", gap: 4, padding: 4, borderRadius: 99, background: white(0.06) }}>
            <motion.div
              initial={false}
              animate={{ x: selected * (CHIP_W + 4) }}
              transition={sp}
              style={{ position: "absolute", left: 4, top: 4, width: CHIP_W, height: 30, borderRadius: 99, background: Signature.lime, boxShadow: `0 2px 8px rgb(200 245 96 / 0.35)` }}
            />
            {KINDS.map((k, i) => {
              const isSelected = i === selected;
              return (
                <button
                  key={i}
                  type="button"
                  onClick={() => select(i as Kind)}
                  style={{ position: "relative", flex: 1, minWidth: 0, height: 30, display: "grid", placeItems: "center", cursor: "pointer" }}
                >
                  <span
                    style={{
                      fontFamily: fonts.rounded,
                      fontSize: 13,
                      fontWeight: 600,
                      whiteSpace: "nowrap",
                      color: isSelected ? "#000" : Signature.textSecondary,
                      transition: "color 0.3s",
                    }}
                  >
                    {zh ? k.zh : k.en}
                  </span>
                </button>
              );
            })}
          </div>
          {/* grid */}
          <div style={{ position: "relative", width: GRID_W, height: TILE_H * 2 + GAP }}>
            {SPOTS.map((spot) => {
              const shown = now.includes(spot.id);
              const wasShown = before.includes(spot.id);
              const nowIdx = now.indexOf(spot.id);
              const slot = nowIdx >= 0 ? nowIdx : Math.max(before.indexOf(spot.id), 0);
              const x = (slot % 3) * (TILE_W + GAP);
              const y = Math.floor(slot / 3) * (TILE_H + GAP);
              const entering = shown && !wasShown;
              const visibility = shown ? (entering ? delayed(sp, 0.1 + slot * ctx.n("stagger")) : sp) : anim.easeOut(0.15);
              const movement = shown && wasShown ? delayed(sp, 0.06) : NO_ANIM;
              return (
                <motion.div
                  key={spot.id}
                  initial={false}
                  animate={{ x, y }}
                  transition={{ x: movement, y: movement }}
                  style={{ position: "absolute", left: 0, top: 0, width: TILE_W, pointerEvents: "none" }}
                >
                  <motion.div initial={false} animate={{ scale: shown ? 1 : 0.6, opacity: shown ? 1 : 0 }} transition={visibility}>
                    <Tile spot={spot} zh={zh} />
                  </motion.div>
                </motion.div>
              );
            })}
          </div>
          <SignatureRim radius={26} />
        </div>
        <div style={{ flex: 1 }} />
        <DemoHint ctx={ctx} en="Tap a filter chip" zh="点击筛选标签" style={{ paddingBottom: 14 }} />
      </div>
    </SignatureStage>
  );
}

function Tile({ spot, zh }: { spot: (typeof SPOTS)[number]; zh: boolean }) {
  const Icon = KINDS[spot.kind].icon;
  return (
    <div style={{ position: "relative", height: TILE_H, borderRadius: 16, overflow: "hidden" }}>
      <LandscapeArt seed={spot.seed} />
      <div style={{ position: "absolute", inset: 0, background: `linear-gradient(transparent 50%, ${black(0.65)})` }} />
      <div style={{ position: "absolute", top: 6, right: 6, width: 20, height: 20, borderRadius: "50%", background: black(0.3), display: "grid", placeItems: "center", color: "#fff" }}>
        <Icon size={10} strokeWidth={2.6} />
      </div>
      <div style={{ position: "absolute", left: 7, right: 7, bottom: 7, display: "flex", flexDirection: "column", gap: 1, whiteSpace: "nowrap", overflow: "hidden" }}>
        <span style={{ fontFamily: fonts.rounded, fontSize: 10.5, fontWeight: 700, color: "#fff", lineHeight: "13px", overflow: "hidden", textOverflow: "ellipsis" }}>{zh ? spot.zh : spot.en}</span>
        <span style={{ fontFamily: fonts.text, fontSize: 8.5, fontWeight: 500, color: white(0.7), lineHeight: "10px", overflow: "hidden", textOverflow: "ellipsis" }}>{zh ? spot.metaZh : spot.metaEn}</span>
      </div>
      <div style={{ position: "absolute", inset: 0, borderRadius: 16, boxShadow: `inset 0 0 0 1px ${Signature.hairline}` }} />
    </div>
  );
}
