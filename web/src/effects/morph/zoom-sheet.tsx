/** morph.zoom-sheet · 从按钮长出的面板 (Morph+ZoomSheet.swift) */
import { animate, motion, useMotionValue } from "motion/react";
import { Bookmark, Copy, Ellipsis, Printer, Share, X } from "lucide-react";
import { useState } from "react";
import { DemoHint, Palette, anim, black, clamp, delayed, hex, rubberBand, spring, useAutoplay, useHaptics, usePan, white, type DemoProps } from "../../kit";
import { LayoutRoot, predicted, sheen, useMV } from "./_shared";
import { SunHorizon } from "./_symbols";

export default function ZoomSheet({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [open, setOpen] = useState(false);
  const [showContent, setShowContent] = useState(false);
  const openMV = useMotionValue(0);
  const dragMV = useMotionValue(0);
  const openP = useMV(openMV);
  const dragY = useMV(dragMV);
  const spr = spring(ctx.n("response"), ctx.n("damping"));
  const zh = ctx.lang === "zh";
  const dark = ctx.scheme === "dark";
  const elevated = dark ? "#2c2c2e" : "#ffffff";

  const presence = openP * (1 - clamp(Math.max(dragY, 0) / 220));

  const present = () => {
    haptics.tap("medium");
    animate(dragMV, 0, spr);
    animate(openMV, 1, spr);
    setOpen(true);
    requestAnimationFrame(() => setShowContent(true));
  };
  const close = () => {
    setShowContent(false);
    animate(openMV, 0, spr);
    animate(dragMV, 0, spr);
    setOpen(false);
  };
  useAutoplay(ctx.isPreview, () => (open ? close() : present()), { every: 2.2 });

  const pan = usePan(
    {
      onChange: ({ translation: t }) => dragMV.set(t.y > 0 ? t.y : rubberBand(t.y, 24)),
      onEnd: ({ translation, velocity }) => {
        if (translation.y > 100 || predicted(translation.y, velocity.y) > 260) close();
        else animate(dragMV, 0, spr);
      },
    },
    6,
  );

  const hintOpacity = dragY > 4 ? 0 : 1;
  return (
    <LayoutRoot>
      <div style={{ position: "absolute", inset: 0, transformOrigin: "50% 0%", transform: `scale(${1 - (1 - ctx.n("recede")) * presence})` }}>
        <Backdrop zh={zh} />
      </div>
      <div onClick={() => open && close()} style={{ position: "absolute", inset: 0, background: "#000", opacity: 0.25 * presence, pointerEvents: open ? "auto" : "none" }} />
      {open ? (
        <div {...pan} style={{ ...pan.style, position: "absolute", left: 8, right: 8, bottom: 8, transform: `translateY(${dragY}px)` }}>
          <motion.div
            layoutId="sheet"
            transition={spr}
            initial={{ backgroundColor: Palette.indigo }}
            animate={{ backgroundColor: elevated }}
            style={{ position: "absolute", inset: 0, borderRadius: 32, boxShadow: `0 10px 24px ${black(0.18)}` }}
          />
          <div style={{ position: "relative", padding: 18, display: "flex", flexDirection: "column", gap: 16 }}>
            <div style={{ width: 36, height: 5, borderRadius: 3, background: Palette.labelAlpha(0.15), alignSelf: "center" }} />
            <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
              <motion.span layoutId="icon" transition={spr} initial={{ color: "#ffffff" }} animate={{ color: Palette.indigo }} style={{ display: "grid" }}>
                <Share size={19} strokeWidth={2.4} />
              </motion.span>
              <Row visible={showContent} delay={0.05}>
                <span style={{ fontSize: 17, lineHeight: "22px", fontWeight: 600 }}>{zh ? "分享照片" : "Share photo"}</span>
              </Row>
              <div style={{ flex: 1 }} />
              <Row visible={showContent} delay={0.05}>
                <button
                  type="button"
                  onPointerDown={(e) => e.stopPropagation()}
                  onClick={close}
                  style={{ width: 28, height: 28, borderRadius: 14, background: Palette.labelAlpha(0.08), display: "grid", placeItems: "center", color: Palette.secondaryLabel }}
                >
                  <X size={13} strokeWidth={3.2} />
                </button>
              </Row>
            </div>
            <Row visible={showContent} delay={0.1}>
              <div style={{ display: "flex" }}>
                {(
                  [
                    ["AL", Palette.pink],
                    ["MJ", Palette.amber],
                    ["SK", Palette.mint],
                    ["YU", Palette.sky],
                  ] as const
                ).map(([initials, color]) => (
                  <div key={initials} style={{ flex: 1, display: "flex", justifyContent: "center" }}>
                    <div style={{ width: 52, height: 52, borderRadius: 26, background: sheen(color), display: "grid", placeItems: "center", color: "#fff", fontSize: 15, fontWeight: 700 }}>
                      {initials}
                    </div>
                  </div>
                ))}
              </div>
            </Row>
            <Row visible={showContent} delay={0.15}>
              <div style={{ display: "flex" }}>
                {[Copy, Bookmark, Printer, Ellipsis].map((Icon, i) => (
                  <div key={i} style={{ flex: 1, display: "flex", justifyContent: "center" }}>
                    <div style={{ width: 52, height: 44, borderRadius: 14, background: Palette.labelAlpha(0.06), display: "grid", placeItems: "center" }}>
                      <Icon size={19} strokeWidth={2.3} />
                    </div>
                  </div>
                ))}
              </div>
            </Row>
          </div>
        </div>
      ) : (
        <button type="button" onClick={present} style={{ position: "absolute", right: 20, bottom: 20, width: 56, height: 56, display: "grid", placeItems: "center" }}>
          <motion.div
            layoutId="sheet"
            transition={spr}
            initial={{ backgroundColor: elevated }}
            animate={{ backgroundColor: Palette.indigo }}
            style={{ position: "absolute", inset: 0, borderRadius: 28, boxShadow: `0 6px 12px ${hex(Palette.indigo, 0.4)}` }}
          />
          <motion.span layoutId="icon" transition={spr} initial={{ color: Palette.indigo }} animate={{ color: "#ffffff" }} style={{ position: "relative", display: "grid" }}>
            <Share size={19} strokeWidth={2.4} />
          </motion.span>
        </button>
      )}
      <div
        className={open ? "ml-dark" : undefined}
        style={{
          position: "absolute",
          pointerEvents: "none",
          opacity: hintOpacity,
          ...(open ? { left: 0, right: 0, top: 30 } : { left: 24, bottom: 38 }),
        }}
      >
        <DemoHint
          ctx={ctx}
          en={open ? "Drag the sheet down to close" : "Tap the share button"}
          zh={open ? "向下拖动面板即可关闭" : "点击分享按钮"}
          style={open ? undefined : { textAlign: "left" }}
        />
      </div>
    </LayoutRoot>
  );
}

function Row({ visible, delay, children }: { visible: boolean; delay: number; children: React.ReactNode }) {
  return (
    <motion.div
      initial={false}
      animate={{ opacity: visible ? 1 : 0, y: visible ? 0 : 12 }}
      transition={visible ? delayed(spring(0.45, 0.86), delay) : anim.easeOut(0.1)}
    >
      {children}
    </motion.div>
  );
}

function Backdrop({ zh }: { zh: boolean }) {
  return (
    <div style={{ position: "absolute", inset: 0, padding: 20, display: "flex", flexDirection: "column", gap: 14 }}>
      <div
        style={{
          height: 150,
          borderRadius: 22,
          background: `linear-gradient(to bottom right, ${Palette.amber}, ${Palette.coral}, ${Palette.pink})`,
          display: "grid",
          placeItems: "center",
          color: white(0.85),
        }}
      >
        <SunHorizon size={54} />
      </div>
      <div style={{ padding: "0 4px", display: "flex", flexDirection: "column", gap: 4 }}>
        <span style={{ fontSize: 17, lineHeight: "22px", fontWeight: 600 }}>{zh ? "海边日落" : "Sunset over the bay"}</span>
        <span style={{ fontSize: 12, lineHeight: "16px", color: Palette.secondaryLabel }}>{zh ? "9 月 12 日 · 18:42 · 旧金山" : "Sep 12 · 6:42 PM · San Francisco"}</span>
        <span style={{ fontSize: 15, lineHeight: "20px", color: Palette.secondaryLabel, paddingTop: 4 }}>
          {zh ? "云层压得很低，最后一缕光把整片海湾染成了琥珀色。" : "Low clouds, and the last light turned the whole bay amber."}
        </span>
      </div>
    </div>
  );
}
