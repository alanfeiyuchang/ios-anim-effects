/** buttons.pill-toolbar · 胶囊工具栏展开 (Buttons+PillToolbar.swift) */
import { motion } from "motion/react";
import { CaseSensitive, Crop, Plus, SlidersHorizontal } from "lucide-react";
import { useEffect, useRef, useState } from "react";
import { DemoHint, Palette, SymbolBounce, delayed, spring, useAutoplay, useHaptics, useTimeouts, type DemoProps } from "../../kit";
import { LandscapeArt } from "../showcase/signature";
import { BlurReplace, PressButton } from "./_a-kit";

function Filters({ size }: { size: number; zh?: boolean }) {
  return (
    <svg viewBox="0 0 24 24" width={size} height={size} fill="none" stroke="currentColor" strokeWidth={2}>
      <circle cx="12" cy="8.2" r="5.2" />
      <circle cx="8.4" cy="14.6" r="5.2" />
      <circle cx="15.6" cy="14.6" r="5.2" />
    </svg>
  );
}

const TOOLS = [
  { Icon: ({ size }: { size: number; zh?: boolean }) => <Crop size={size} strokeWidth={2.4} />, name: ["Crop", "裁剪"] },
  { Icon: ({ size }: { size: number; zh?: boolean }) => <SlidersHorizontal size={size} strokeWidth={2.4} />, name: ["Adjust", "调节"] },
  { Icon: Filters, name: ["Filters", "滤镜"] },
  // SF Symbols draws `textformat` as the localized word in Chinese ("格式"), and as "Aa" elsewhere.
  { Icon: ({ size, zh }: { size: number; zh?: boolean }) => (zh ? <span style={{ fontSize: 15, fontWeight: 700 }}>格式</span> : <CaseSensitive size={size + 2} strokeWidth={2.4} />), name: ["Text", "文字"] },
] as const;

export default function PillToolbar({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const { after } = useTimeouts();
  const [open, setOpen] = useState(false);
  const openRef = useRef(false);
  const [selected, setSelected] = useState<number | null>(null);
  const [bounces, setBounces] = useState([0, 0, 0, 0]);
  const step = useRef(0);
  const intro = useRef<(() => void)[]>([]);
  const expanded = ctx.n("width");
  const stagger = ctx.n("stagger");

  const cancelIntro = () => {
    intro.current.forEach((c) => c());
    intro.current = [];
  };
  useEffect(() => () => cancelIntro(), []);

  const toggle = (silent: boolean) => {
    openRef.current = !openRef.current;
    setOpen(openRef.current);
    if (!openRef.current) setSelected(null);
    if (!silent) haptics.tap();
  };
  const pick = (index: number, silent: boolean) => {
    if (!openRef.current) return;
    setSelected(index);
    setBounces((b) => b.map((v, i) => (i === index ? v + 1 : v)));
    if (!silent) haptics.tap();
  };

  useAutoplay(ctx.isPreview, () => {
    if (ctx.isPreview) {
      const s = step.current % 4;
      if (s === 0) toggle(true);
      else if (s === 1) pick(1, true);
      else if (s === 2) pick(3, true);
      else toggle(true);
      step.current += 1;
      return;
    }
    cancelIntro();
    if (!openRef.current) toggle(true);
    intro.current.push(
      after(0.8, () => {
        pick(1, true);
        intro.current.push(after(1.1, () => openRef.current && toggle(true)));
      }),
    );
  }, { every: 1.1, delay: 0.4 });

  const barT = spring(0.45, ctx.n("damping"));
  const toolW = (expanded - 56) / TOOLS.length;
  const showCaption = selected !== null && open;

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center" }}>
      <div style={{ flex: 1 }} />
      <div
        style={{
          position: "relative",
          width: 310,
          height: 250,
          flexShrink: 0,
          borderRadius: 26,
          overflow: "hidden",
          boxShadow: "0 10px 18px rgb(0 0 0 / 0.16)",
        }}
      >
        <LandscapeArt seed={2} />
        <div style={{ position: "absolute", left: 0, right: 0, top: 16, display: "flex", justifyContent: "center" }}>
          <div
            style={{
              padding: showCaption ? "6px 12px" : "6px 12px",
              borderRadius: 999,
              background: `rgb(0 0 0 / ${showCaption ? 0.35 : 0})`,
              transition: "background 0.25s",
              fontSize: 15,
              lineHeight: "20px",
              fontWeight: 600,
              color: "#fff",
              minHeight: 32,
            }}
          >
            <BlurReplace id={showCaption ? String(selected) : "none"}>
              <span>{showCaption ? ctx.t(TOOLS[selected!].name[0], TOOLS[selected!].name[1]) : ""}</span>
            </BlurReplace>
          </div>
        </div>
        <div style={{ position: "absolute", right: 14, bottom: 14, width: expanded, height: 56 }}>
          <motion.div
            initial={false}
            animate={{ width: open ? expanded : 56 }}
            transition={barT}
            style={{
              position: "absolute",
              right: 0,
              top: 0,
              height: 56,
              borderRadius: 28,
              background: ctx.scheme === "dark" ? "rgb(44 44 50 / 0.92)" : "rgb(22 22 26 / 0.92)",
              boxShadow: "inset 0 0 0 1px rgb(255 255 255 / 0.2), 0 6px 12px rgb(0 0 0 / 0.3)",
            }}
          />
          <div style={{ position: "absolute", left: 0, top: 0, width: expanded - 56, height: 56, display: "flex", pointerEvents: open ? "auto" : "none" }}>
            {TOOLS.map((tool, index) => {
              const order = open ? TOOLS.length - 1 - index : index;
              const delay = order * stagger + (open ? 0.06 : 0);
              return (
                <motion.button
                  key={index}
                  type="button"
                  onClick={() => {
                    cancelIntro();
                    pick(index, false);
                  }}
                  initial={false}
                  animate={{ filter: open ? "blur(0px)" : "blur(6px)", scale: open ? 1 : 0.5, opacity: open ? 1 : 0 }}
                  transition={delayed(spring(0.35, 0.8), delay)}
                  style={{
                    width: toolW,
                    height: 56,
                    display: "grid",
                    placeItems: "center",
                    color: selected === index ? Palette.amber : "rgb(255 255 255 / 0.85)",
                  }}
                >
                  <SymbolBounce trigger={bounces[index]}>
                    <tool.Icon size={20} zh={ctx.lang === "zh"} />
                  </SymbolBounce>
                </motion.button>
              );
            })}
          </div>
          <PressButton
            scale={0.9}
            dim={0.05}
            onClick={() => {
              cancelIntro();
              toggle(false);
            }}
            style={{
              position: "absolute",
              right: 0,
              top: 0,
              width: 56,
              height: 56,
              borderRadius: "50%",
              background: Palette.primary,
              boxShadow: "inset 0 0 0 1px rgb(255 255 255 / 0.2)",
              display: "grid",
              placeItems: "center",
              color: "#fff",
            }}
          >
            <motion.span initial={false} animate={{ rotate: open ? 45 : 0 }} transition={barT} style={{ display: "grid" }}>
              <Plus size={24} strokeWidth={2.4} />
            </motion.span>
          </PressButton>
        </div>
      </div>
      <div style={{ flex: 1 }} />
      <DemoHint ctx={ctx} en="Tap +, then pick a tool" zh="点击加号，再选一个工具" style={{ paddingBottom: 14 }} />
    </div>
  );
}
