/** scroll.index-scrubber · A–Z 索引条 (Scroll+IndexScrubber.swift) */
import { AnimatePresence, motion } from "motion/react";
import { useEffect, useRef, useState } from "react";
import { DemoHint, Palette, alpha, anim, clamp, fonts, glass, spring, useAutoplay, useHaptics, type DemoProps } from "../../kit";
import { ScrollKit, useScroller } from "./_kit";

const LETTERS = "ABCDEFGHIJKLMNOPQRSTUVWXYZ".split("");
const SECTIONS: [string, [string, string][]][] = [
  ["A", [["Ava Collins", "安然"], ["Aiden Park", "艾米"]]],
  ["B", [["Bella Hart", "白露"], ["Ben Ortiz", "包晨"]]],
  ["C", [["Chloe Reed", "陈思远"], ["Caleb Stone", "程悦"]]],
  ["D", [["Daniel Wu", "邓宁"]]],
  ["E", [["Emma Lane", "鄂晴"]]],
  ["F", [["Finn Brooks", "方可"], ["Freya Moss", "冯雪"]]],
  ["G", [["Grace Kim", "高远"]]],
  ["H", [["Hana Sato", "何夕"], ["Henry Cole", "胡桃"]]],
  ["J", [["Jade Rivera", "江澄"], ["Jonah Fox", "金沐"]]],
  ["K", [["Kai Lopez", "孔乐"]]],
  ["L", [["Lena Park", "林晓"], ["Leo Grant", "陆鸣"], ["Lily Chen", "刘星"]]],
  ["M", [["Maya Singh", "马骁"], ["Miles Dunn", "孟夏"]]],
  ["N", [["Nora Blake", "宁静"]]],
  ["O", [["Oscar Hale", "欧阳朗"]]],
  ["P", [["Priya Nair", "潘越"]]],
  ["R", [["Ruby Walsh", "任舟"], ["Ryan Moore", "阮青"]]],
  ["S", [["Sofia Ruiz", "宋雨"], ["Sam Taylor", "孙一"], ["Sara Ali", "苏禾"]]],
  ["T", [["Theo Grey", "唐果"]]],
  ["V", [["Violet Ames", "魏然"]]],
  ["W", [["Will Harper", "王珂"], ["Wren Ellis", "吴桐"]]],
  ["X", [["Xavier Bell", "许诺"]]],
  ["Y", [["Yara Haddad", "杨帆"], ["Yuki Mori", "叶知秋"]]],
  ["Z", [["Zoe Fraser", "张弛"], ["Zane Cooper", "周屿"]]],
];
const LETTER_H = 11;
const INSET = 6;
const BAR_H = LETTER_H * LETTERS.length + INSET * 2;
const PREVIEW_PATH: (number | null)[] = [1, 3, 6, 9, 11, 13, 16, 18, null, null, 17, 14, 10, 7, 4, 1, null, null];
const INTRO_PATH = [1, 4, 7, 10, 12, 9, 5];

export default function IndexScrubber({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [active, setActive] = useState<number | null>(null);
  const activeRef = useRef<number | null>(null);
  const autoStep = useRef(0);
  const demoing = useRef(false);
  const held = useRef(false);
  const introTimers = useRef<number[]>([]);
  const sections = useRef<(HTMLDivElement | null)[]>([]);
  const sc = useScroller({ axis: "y" });
  const zh = ctx.lang === "zh";

  useEffect(() => () => introTimers.current.forEach((id) => window.clearTimeout(id)), []);

  const setActiveIndex = (i: number | null) => {
    activeRef.current = i;
    setActive(i);
  };
  const select = (index: number) => {
    if (index === activeRef.current) return;
    setActiveIndex(index);
    if (!ctx.isPreview && !demoing.current) haptics.selection();
    // Jump straight to the section (or the next existing one), like the native index.
    const letter = LETTERS[index];
    let k = SECTIONS.findIndex(([l]) => l >= letter);
    if (k < 0) k = SECTIONS.length - 1;
    const el = sections.current[k];
    if (el) sc.scrollTo(el.offsetTop, null);
  };
  const cancelIntro = () => {
    introTimers.current.forEach((id) => window.clearTimeout(id));
    introTimers.current = [];
    demoing.current = false;
  };

  /** Detail stage, once on arrival: a quick sweep down and back, then release and return to the top. */
  const introScrub = () => {
    if (demoing.current || held.current || activeRef.current !== null) return;
    demoing.current = true;
    const at = (sec: number, fn: () => void) => introTimers.current.push(window.setTimeout(fn, sec * 1000));
    INTRO_PATH.forEach((index, n) => at(n * 0.17, () => demoing.current && select(index)));
    at(INTRO_PATH.length * 0.17 + 0.25, () => {
      if (!demoing.current) return;
      setActiveIndex(null);
      sc.scrollTo(0, anim.smoothD(0.5));
      demoing.current = false;
    });
  };
  // Preview: sweep the thumb down the index, rest, then back up, releasing in between.
  useAutoplay(
    ctx.isPreview,
    () => {
      if (!ctx.isPreview) return introScrub();
      const index = PREVIEW_PATH[autoStep.current % PREVIEW_PATH.length];
      if (index !== null) select(index);
      else if (activeRef.current !== null) setActiveIndex(null);
      autoStep.current += 1;
    },
    { every: 0.32, delay: 0.5 },
  );

  const scrubAt = (e: React.PointerEvent<HTMLDivElement>) => {
    const rect = e.currentTarget.getBoundingClientRect();
    const scale = rect.height / e.currentTarget.offsetHeight || 1;
    const y = (e.clientY - rect.top) / scale;
    select(clamp(Math.floor((y - INSET) / LETTER_H), 0, LETTERS.length - 1));
  };
  const endHold = () => {
    if (!held.current) return;
    held.current = false;
    setActiveIndex(null);
  };

  const magnify = ctx.n("magnify");
  const reach = Math.max(ctx.n("reach"), 1);
  const falloff = (i: number) => {
    if (active === null) return 0;
    const d = Math.abs(i - active);
    return d < reach ? 0.5 + 0.5 * Math.cos((Math.PI * d) / reach) : 0;
  };
  const t = spring(0.25, 0.8);

  return (
    <div style={{ position: "absolute", inset: 0 }}>
      <div {...sc.props} style={{ ...sc.props.style, position: "absolute", inset: 0 }}>
        <div ref={sc.contentRef} style={{ padding: "16px 40px 16px 16px" }}>
          {SECTIONS.map(([letter, names], k) => (
            <div key={letter} ref={(el) => void (sections.current[k] = el)} style={{ display: "flex", flexDirection: "column", gap: 6 }}>
              <div style={{ paddingTop: 10, fontSize: 13, lineHeight: "18px", fontWeight: 700, color: Palette.secondaryLabel }}>{letter}</div>
              {names.map((name, i) => {
                const label = zh ? name[1] : name[0];
                return (
                  <div key={i} style={{ display: "flex", alignItems: "center", gap: 12, padding: "6px 10px", borderRadius: 14, background: Palette.elevated }}>
                    <div
                      style={{
                        width: 34,
                        height: 34,
                        borderRadius: "50%",
                        flexShrink: 0,
                        background: ScrollKit.gradient(letter.charCodeAt(0) + i),
                        color: "#fff",
                        display: "grid",
                        placeItems: "center",
                        fontSize: 15,
                        fontWeight: 700,
                      }}
                    >
                      {label.slice(0, 1)}
                    </div>
                    <span style={{ fontSize: 15, lineHeight: "20px", fontWeight: 500 }}>{label}</span>
                  </div>
                );
              })}
            </div>
          ))}
        </div>
      </div>
      {/* The A–Z strip; the touch area is widened 10 pt beyond the letter column. */}
      <div
        onPointerDown={(e) => {
          e.currentTarget.setPointerCapture(e.pointerId);
          held.current = true;
          cancelIntro();
          scrubAt(e);
        }}
        onPointerMove={(e) => held.current && scrubAt(e)}
        onPointerUp={endHold}
        onPointerCancel={endHold}
        style={{ position: "absolute", right: 4, top: "50%", marginTop: -BAR_H / 2, width: 32, height: BAR_H, paddingLeft: 10, touchAction: "none", cursor: "pointer" }}
      >
        <div style={{ position: "relative", width: 22, height: BAR_H }}>
          <div style={{ position: "absolute", inset: 0, borderRadius: 11, background: Palette.labelAlpha(active === null ? 0 : 0.06), transition: "background 0.25s" }} />
          <div style={{ position: "absolute", left: 0, top: INSET, width: 22 }}>
            {LETTERS.map((l, i) => {
              const lift = falloff(i);
              return (
                <motion.div
                  key={l}
                  animate={{ scale: 1 + magnify * lift, x: -lift * 14 }}
                  transition={t}
                  style={{
                    position: "relative",
                    zIndex: Math.round(lift * 10),
                    width: 22,
                    height: LETTER_H,
                    display: "grid",
                    placeItems: "center",
                    transformOrigin: "100% 50%",
                    fontFamily: fonts.rounded,
                    fontSize: 10,
                    lineHeight: `${LETTER_H}px`,
                    fontWeight: 600,
                    color: i === active ? "#8C74FF" : Palette.indigo,
                  }}
                >
                  {l}
                </motion.div>
              );
            })}
          </div>
          <AnimatePresence>
            {ctx.b("bubble") && active !== null && (
              <motion.div
                key="bubble"
                initial={{ scale: 0.4, opacity: 0 }}
                animate={{ scale: 1, opacity: 1, y: INSET + (active + 0.5) * LETTER_H - 28 }}
                exit={{ scale: 0.4, opacity: 0 }}
                transition={spring(0.3, 0.8)}
                style={{
                  position: "absolute",
                  right: 56,
                  top: 0,
                  width: 56,
                  height: 56,
                  borderRadius: "50%",
                  background: Palette.primary,
                  boxShadow: `0 6px 12px ${alpha(Palette.indigo, 0.35)}`,
                  transformOrigin: "100% 50%",
                  display: "grid",
                  placeItems: "center",
                  overflow: "hidden",
                  color: "#fff",
                  fontFamily: fonts.rounded,
                  fontSize: 28,
                  fontWeight: 800,
                  pointerEvents: "none",
                }}
              >
                <AnimatePresence initial={false} mode="popLayout">
                  <motion.span
                    key={active}
                    initial={{ y: 20, opacity: 0, filter: "blur(2px)" }}
                    animate={{ y: 0, opacity: 1, filter: "blur(0px)" }}
                    exit={{ y: -20, opacity: 0, filter: "blur(2px)" }}
                    transition={spring(0.25, 0.8)}
                  >
                    {LETTERS[active]}
                  </motion.span>
                </AnimatePresence>
              </motion.div>
            )}
          </AnimatePresence>
        </div>
      </div>
      {!ctx.isPreview && (
        <div
          style={{
            position: "absolute",
            left: 0,
            right: 0,
            bottom: 12,
            display: "flex",
            justifyContent: "center",
            pointerEvents: "none",
            opacity: active === null ? 1 : 0,
            transition: "opacity 0.2s ease-out",
          }}
        >
          <div style={{ padding: "6px 12px", borderRadius: 999, ...glass("regular") }}>
            <DemoHint ctx={ctx} en="Slide along the A–Z index" zh="沿 A–Z 索引滑动" />
          </div>
        </div>
      )}
    </div>
  );
}
