/** buttons.liquid-glass · 液态玻璃收藏按钮 (Buttons+LiquidGlass.swift) */
import { AnimatePresence, motion } from "motion/react";
import { Bookmark, Check, Undo2 } from "lucide-react";
import { useLayoutEffect, useRef, useState, type CSSProperties } from "react";
import { DemoHint, Palette, fonts, glass, spring, useAutoplay, useHaptics, type DemoProps } from "../../kit";
import { LandscapeArt, Signature } from "../showcase/signature";
import { HEART_PATH, PressButton, SymbolReplace } from "./_a-kit";

/** Liquid Glass stand-in: frosted material, optional tint, bright top rim fading to the bottom. */
function Glass({ tint, radius, style }: { tint?: string; radius: number | string; style?: CSSProperties }) {
  return (
    <div style={{ position: "absolute", inset: 0, borderRadius: radius, overflow: "hidden", ...style }}>
      <div style={{ position: "absolute", inset: 0, ...glass("ultraThin", "dark"), backdropFilter: "blur(14px) saturate(1.9)", WebkitBackdropFilter: "blur(14px) saturate(1.9)" }} />
      {tint && <div style={{ position: "absolute", inset: 0, background: tint, opacity: 0.55 }} />}
      <div style={{ position: "absolute", inset: 0, background: "linear-gradient(rgb(255 255 255 / 0.22), transparent 50%)" }} />
      <div
        style={{
          position: "absolute",
          inset: 0,
          borderRadius: radius,
          padding: 1,
          background: "linear-gradient(rgb(255 255 255 / 0.65), rgb(255 255 255 / 0.1))",
          WebkitMask: "linear-gradient(#000 0 0) content-box, linear-gradient(#000 0 0)",
          WebkitMaskComposite: "xor",
          mask: "linear-gradient(#000 0 0) content-box exclude, linear-gradient(#000 0 0)",
        }}
      />
    </div>
  );
}

export default function LiquidGlass({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [saved, setSaved] = useState(false);
  const savedRef = useRef(false);
  const [liked, setLiked] = useState(false);
  const zh = ctx.lang === "zh";
  const t = spring(ctx.n("response"), ctx.n("damping"));
  const gap = 4 + ctx.n("spacing") * 0.5;
  const saveLabel = zh ? "收藏到行程" : "Save to trip";
  const undoLabel = zh ? "撤销" : "Undo";
  // Label widths, so the pills can spring between sizes like the SwiftUI layout.
  const measure = useRef<HTMLDivElement>(null);
  const [saveW, setSaveW] = useState(160);
  const [undoW, setUndoW] = useState(96);
  useLayoutEffect(() => {
    const spans = measure.current?.querySelectorAll("span");
    if (!spans) return;
    setSaveW(Math.ceil(spans[0].offsetWidth) + 17 + 8 + 44);
    setUndoW(Math.ceil(spans[1].offsetWidth) + 16 + 6 + 36);
  }, [zh]);

  const toggle = () => {
    if (savedRef.current) haptics.tap("soft");
    else haptics.success();
    savedRef.current = !savedRef.current;
    setSaved(savedRef.current);
  };
  useAutoplay(ctx.isPreview, toggle, { every: 1.8, delay: 0.5 });

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center" }}>
      <div ref={measure} style={{ position: "absolute", visibility: "hidden", pointerEvents: "none", whiteSpace: "nowrap" }}>
        <span style={{ fontSize: 17, fontWeight: 600 }}>{saveLabel}</span>
        <span style={{ fontSize: 15, fontWeight: 600 }}>{undoLabel}</span>
      </div>
      <div style={{ flex: 1 }} />
      <div
        style={{
          position: "relative",
          width: 300,
          height: 300,
          flexShrink: 0,
          borderRadius: 28,
          overflow: "hidden",
          boxShadow: "0 10px 18px rgb(0 0 0 / 0.2)",
          color: "#fff",
        }}
      >
        <LandscapeArt seed={1} />
        <div style={{ position: "absolute", inset: 0, background: "linear-gradient(transparent 50%, rgb(0 0 0 / 0.35))" }} />
        <div style={{ position: "absolute", left: 18, top: 18, display: "flex", flexDirection: "column", gap: 2 }}>
          <div style={{ fontSize: 12, lineHeight: "16px", fontWeight: 600, color: "rgb(255 255 255 / 0.8)" }}>{zh ? "法国 · 尼斯" : "France · Nice"}</div>
          <div style={{ fontFamily: fonts.rounded, fontSize: 22, lineHeight: "27px", fontWeight: 700 }}>{zh ? "天使湾日落" : "Sunset on the Baie"}</div>
        </div>
        <div style={{ position: "absolute", top: 14, right: 14 }}>
          <PressButton
            scale={0.9}
            dim={0.05}
            onClick={() => {
              haptics.tap();
              setLiked((l) => !l);
            }}
            style={{ position: "relative", width: 44, height: 44, borderRadius: "50%", display: "grid", placeItems: "center" }}
          >
            <Glass radius="50%" />
            <SymbolReplace id={liked ? "on" : "off"} style={{ position: "relative" }}>
              <svg viewBox="0 0 24 24" width={22} height={22} style={{ overflow: "visible" }}>
                {liked ? (
                  <path d={HEART_PATH} fill={Palette.pink} />
                ) : (
                  <path d={HEART_PATH} fill="none" stroke="#fff" strokeWidth={2.1} strokeLinejoin="round" />
                )}
              </svg>
            </SymbolReplace>
          </PressButton>
        </div>
        <div style={{ position: "absolute", left: 0, right: 0, bottom: 20, display: "flex", justifyContent: "center" }}>
          <div style={{ display: "flex" }}>
            <motion.div
              initial={false}
              animate={{ width: saved ? 52 : saveW }}
              transition={t}
              style={{ position: "relative", height: 52 }}
            >
              <PressButton
                scale={0.94}
                dim={0.04}
                onClick={toggle}
                style={{ position: "absolute", inset: 0, display: "grid", placeItems: "center", color: "#fff" }}
              >
                <Glass radius={26} tint={saved ? Palette.green : Signature.accent} />
                <AnimatePresence initial={false}>
                  <motion.span
                    key={saved ? "check" : "save"}
                    initial={{ opacity: 0, scale: 0.6, filter: "blur(4px)" }}
                    animate={{ opacity: 1, scale: 1, filter: "blur(0px)" }}
                    exit={{ opacity: 0, scale: 0.6, filter: "blur(4px)" }}
                    transition={spring(0.3, 0.85)}
                    style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center", gap: 8, whiteSpace: "nowrap", fontSize: 17, fontWeight: 600 }}
                  >
                    {saved ? (
                      <Check size={21} strokeWidth={3} />
                    ) : (
                      <>
                        <Bookmark size={17} fill="currentColor" strokeWidth={0} />
                        {saveLabel}
                      </>
                    )}
                  </motion.span>
                </AnimatePresence>
              </PressButton>
            </motion.div>
            <motion.div initial={false} animate={{ width: saved ? undoW + gap : 0 }} transition={t} style={{ position: "relative", height: 52 }}>
              <motion.div
                initial={false}
                animate={{ opacity: saved ? 1 : 0, scale: saved ? 1 : 0.3 }}
                transition={t}
                style={{ position: "absolute", left: gap, top: 0, width: undoW, height: 52, originX: 0, pointerEvents: saved ? "auto" : "none" }}
              >
                <PressButton
                  scale={0.94}
                  dim={0.04}
                  onClick={toggle}
                  style={{ position: "relative", width: undoW, height: 52, display: "flex", alignItems: "center", justifyContent: "center", gap: 6, fontSize: 15, fontWeight: 600, color: "#fff" }}
                >
                  <Glass radius={26} />
                  <Undo2 size={16} strokeWidth={2.6} style={{ position: "relative" }} />
                  <span style={{ position: "relative", whiteSpace: "nowrap" }}>{undoLabel}</span>
                </PressButton>
              </motion.div>
            </motion.div>
          </div>
        </div>
      </div>
      <div style={{ flex: 1 }} />
      <DemoHint ctx={ctx} en="Tap Save, then Undo" zh="点击收藏，再点撤销" style={{ paddingBottom: 16 }} />
    </div>
  );
}
