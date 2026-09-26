/** showcase.spots-grid · 地点网格展开 (Sport+SpotsGrid.swift) */
import { animate, useMotionValue, useMotionValueEvent } from "motion/react";
import { Star } from "lucide-react";
import { useLayoutEffect, useRef, useState, type CSSProperties } from "react";
import { DemoHint, clamp, fonts, mix, spring, useAutoplay, useHaptics, useTimeouts, white, black, type DemoProps } from "../../kit";
import { LandscapeArt, Signature, SignatureRim, SignatureStage, signatureCard, signatureEyebrow } from "./signature";

const SPOTS = [
  { name: "Nordkette", seed: 0, altitude: "2,256 m", runs: 18, rating: "4.9" },
  { name: "Seegrube", seed: 2, altitude: "1,905 m", runs: 9, rating: "4.7" },
  { name: "Stubai", seed: 4, altitude: "3,210 m", runs: 26, rating: "4.8" },
  { name: "Axamer", seed: 1, altitude: "2,340 m", runs: 14, rating: "4.6" },
  { name: "Kühtai", seed: 3, altitude: "2,520 m", runs: 12, rating: "4.5" },
  { name: "Hafelekar", seed: 5, altitude: "2,334 m", runs: 7, rating: "4.8" },
];

type Rect = { x: number; y: number; w: number; h: number };

/** Layout rect of `el` inside `root` (offsets ignore transforms, like SwiftUI layout frames). */
function rectIn(el: HTMLElement, root: HTMLElement): Rect {
  let x = 0;
  let y = 0;
  let node: HTMLElement | null = el;
  while (node && node !== root) {
    x += node.offsetLeft;
    y += node.offsetTop;
    node = node.offsetParent as HTMLElement | null;
  }
  return { x, y, w: el.offsetWidth, h: el.offsetHeight };
}

export default function SpotsGrid({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const { after, clearAll } = useTimeouts();
  const s = useMotionValue(0);
  const [open, setOpen] = useState(0);
  useMotionValueEvent(s, "change", setOpen);
  const [selected, setSelected] = useState<number | null>(null);
  const [shown, setShown] = useState(0);
  const nextAuto = useRef(0);
  const selectedRef = useRef<number | null>(null);

  const root = useRef<HTMLDivElement>(null);
  const gridRef = useRef<HTMLDivElement>(null);
  const heroRef = useRef<HTMLDivElement>(null);
  const tileRefs = useRef<(HTMLDivElement | null)[]>([]);
  const [geo, setGeo] = useState<{ tiles: Rect[]; hero: Rect; grid: Rect } | null>(null);
  useLayoutEffect(() => {
    const r = root.current;
    if (!r || !heroRef.current || !gridRef.current) return;
    setGeo({
      tiles: tileRefs.current.map((t) => (t ? rectIn(t, r) : { x: 0, y: 0, w: 0, h: 0 })),
      hero: rectIn(heroRef.current, r),
      grid: rectIn(gridRef.current, r),
    });
  }, [ctx.isPreview, ctx.lang]);

  const select = (index: number | null, silent = false) => {
    if (index !== null) setShown(index);
    selectedRef.current = index;
    setSelected(index);
    animate(s, index === null ? 0 : 1, spring(ctx.n("response"), ctx.n("damping")));
    if (!silent) haptics.tap(index === null ? "soft" : "light");
  };

  useAutoplay(
    ctx.isPreview,
    () => {
      if (ctx.isPreview) {
        if (selectedRef.current === null) {
          select(nextAuto.current);
          nextAuto.current = (nextAuto.current + 1) % SPOTS.length;
        } else select(null);
      } else {
        // Detail intro: open one spot, hold so the details can be read, then fly it back.
        clearAll();
        select(1, true);
        after(2.0, () => selectedRef.current !== null && select(null, true));
      }
    },
    { every: 1.9, delay: 0.8 },
  );

  const isOpen = selected !== null;
  const flying = isOpen || open > 0.002 || open < -0.002;
  const gridScale = mix(1, 0.9, open);
  const blur = Math.max(0, 6 * open);
  const gridOpacity = clamp(1 - ctx.n("dim") * open);

  let flyRect: Rect | null = null;
  if (flying && geo) {
    const t = geo.tiles[shown];
    const cx = geo.grid.x + geo.grid.w / 2;
    const cy = geo.grid.y + geo.grid.h / 2;
    const tile = { x: cx + (t.x - cx) * gridScale, y: cy + (t.y - cy) * gridScale, w: t.w * gridScale, h: t.h * gridScale };
    flyRect = { x: mix(tile.x, geo.hero.x, open), y: mix(tile.y, geo.hero.y, open), w: mix(tile.w, geo.hero.w, open), h: mix(tile.h, geo.hero.h, open) };
  }

  return (
    <SignatureStage>
      <div ref={root} style={{ position: "absolute", inset: 0 }}>
        {/* grid */}
        <div style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center" }}>
          <div
            ref={gridRef}
            style={{
              ...signatureCard(),
              padding: 16,
              width: 300,
              display: "flex",
              flexDirection: "column",
              gap: 12,
              transform: `scale(${gridScale})`,
              opacity: gridOpacity,
              filter: blur > 0.01 ? `blur(${blur}px)` : undefined,
              pointerEvents: isOpen ? "none" : "auto",
            }}
          >
            <div style={{ display: "flex", alignItems: "baseline" }}>
              <span style={{ fontFamily: fonts.rounded, fontSize: 20, fontWeight: 600, color: "#fff", lineHeight: "24px" }}>{ctx.t("Spots", "雪场")}</span>
              <span style={{ flex: 1 }} />
              <span style={signatureEyebrow()}>{ctx.t("6 saved", "已收藏 6 个")}</span>
            </div>
            <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
              {[0, 1].map((row) => (
                <div key={row} style={{ display: "flex", gap: 8 }}>
                  {[0, 1, 2].map((col) => {
                    const index = row * 3 + col;
                    return (
                      <div
                        key={col}
                        ref={(el) => {
                          tileRefs.current[index] = el;
                        }}
                        onClick={() => {
                          clearAll();
                          select(index);
                        }}
                        style={{ position: "relative", width: 84, height: 84, cursor: "pointer" }}
                      >
                        {!(flying && shown === index) && <SpotPhoto spot={SPOTS[index]} large={false} />}
                      </div>
                    );
                  })}
                </div>
              ))}
            </div>
            <SignatureRim />
          </div>
        </div>
        {/* detail */}
        <div style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center", pointerEvents: "none" }}>
          <div
            onClick={() => {
              clearAll();
              select(null);
            }}
            style={{ position: "relative", padding: 10, width: 290, display: "flex", flexDirection: "column", gap: 12, pointerEvents: isOpen ? "auto" : "none", cursor: "pointer" }}
          >
            <div style={{ position: "absolute", inset: 0, opacity: clamp(open), transform: `scale(${mix(0.94, 1, open)})` }}>
              <div style={{ ...signatureCard(28), position: "absolute", inset: 0 }}>
                <SignatureRim radius={28} />
              </div>
            </div>
            <div ref={heroRef} style={{ position: "relative", height: 170 }} />
            <Info spot={SPOTS[shown]} open={isOpen} zh={ctx.lang === "zh"} />
          </div>
        </div>
        {/* the photo in flight (matched geometry): the grid's copy fades out blurred, the hero's fades in */}
        {flyRect && (
          <div style={{ position: "absolute", left: flyRect.x, top: flyRect.y, width: flyRect.w, height: flyRect.h, pointerEvents: "none" }}>
            <div style={{ position: "absolute", inset: 0, opacity: clamp(1 - open) * gridOpacity, filter: blur > 0.01 ? `blur(${blur}px)` : undefined }}>
              <SpotPhoto spot={SPOTS[shown]} large={false} />
            </div>
            <div style={{ position: "absolute", inset: 0, opacity: clamp(open) }}>
              <SpotPhoto spot={SPOTS[shown]} large />
            </div>
          </div>
        )}
        <DemoHint
          ctx={ctx}
          en="Tap a photo; tap the card to close"
          zh="点击照片展开，点击卡片收起"
          style={{ position: "absolute", left: 0, right: 0, bottom: 14, pointerEvents: "none" }}
        />
      </div>
    </SignatureStage>
  );
}

function SpotPhoto({ spot, large, style }: { spot: (typeof SPOTS)[number]; large: boolean; style?: CSSProperties }) {
  return (
    <div style={{ position: "absolute", inset: 0, borderRadius: 16, overflow: "hidden", ...style }}>
      <LandscapeArt seed={spot.seed} />
      <div style={{ position: "absolute", inset: 0, background: `linear-gradient(transparent 50%, ${black(large ? 0.55 : 0.35)})` }} />
      <span
        style={{
          position: "absolute",
          left: large ? 14 : 7,
          bottom: large ? 14 : 7,
          fontFamily: fonts.rounded,
          fontSize: large ? 22 : 9,
          fontWeight: 700,
          lineHeight: large ? "26px" : "11px",
          color: "#fff",
          textShadow: `0 0 3px ${black(0.6)}`,
          whiteSpace: "nowrap",
        }}
      >
        {spot.name}
      </span>
      <div style={{ position: "absolute", inset: 0, borderRadius: 16, boxShadow: `inset 0 0 0 1px ${white(0.12)}` }} />
    </div>
  );
}

function Info({ spot, open, zh }: { spot: (typeof SPOTS)[number]; open: boolean; zh: boolean }) {
  return (
    <div
      style={{
        position: "relative",
        display: "flex",
        flexDirection: "column",
        gap: 10,
        padding: "0 8px 6px",
        opacity: open ? 1 : 0,
        transform: `translateY(${open ? 0 : 14}px)`,
        transition: `opacity 0.3s cubic-bezier(0, 0, 0.58, 1) ${open ? 0.12 : 0}s, transform 0.3s cubic-bezier(0, 0, 0.58, 1) ${open ? 0.12 : 0}s`,
      }}
    >
      <div style={{ display: "flex", alignItems: "baseline" }}>
        <span style={signatureEyebrow()}>{zh ? "奥地利 · 蒂罗尔" : "Tirol · Austria"}</span>
        <span style={{ flex: 1 }} />
        <span style={{ display: "inline-flex", alignItems: "center", gap: 4, fontFamily: fonts.rounded, fontSize: 12, fontWeight: 700, color: Signature.accent }}>
          <Star size={12} fill="currentColor" strokeWidth={0} />
          {spot.rating}
        </span>
      </div>
      <div
        style={{
          display: "flex",
          alignItems: "center",
          gap: 10,
          fontFamily: fonts.rounded,
          fontSize: 12,
          fontWeight: 500,
          fontVariantNumeric: "tabular-nums",
          color: Signature.textSecondary,
        }}
      >
        <span>{spot.altitude}</span>
        <span>·</span>
        <span>
          {spot.runs} {zh ? "条雪道" : "runs"}
        </span>
        <span style={{ flex: 1 }} />
        <span style={{ fontSize: 12, fontWeight: 700, color: "#000", padding: "7px 12px", borderRadius: 999, background: Signature.accentGradient, lineHeight: "14px" }}>
          {zh ? "导航" : "Navigate"}
        </span>
      </div>
    </div>
  );
}
