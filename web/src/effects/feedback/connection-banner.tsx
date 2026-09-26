/** feedback.connection-banner · 网络状态横幅 (Feedback+Connection.swift) */
import { AnimatePresence, motion } from "motion/react";
import { Bell, Book, CircleCheck, Footprints, Image, Music, WifiOff, type LucideIcon } from "lucide-react";
import { useRef, useState } from "react";
import { DemoHint, Palette, anim, demoCard, spring, useAutoplay, useClock, useHaptics, useTimeouts, type DemoProps } from "../../kit";

type Phase = "online" | "offline" | "reconnecting" | "restored";

export default function ConnectionBanner({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const { after, clearAll } = useTimeouts();
  const [phase, setPhase] = useState<Phase>("online");
  const phaseRef = useRef(phase);
  phaseRef.current = phase;
  const sp = spring(ctx.n("response"), 0.82);
  const stale = ctx.b("dim") && (phase === "offline" || phase === "reconnecting");

  const reconnect = (buzz: boolean) => {
    clearAll();
    if (buzz) haptics.tap();
    setPhase("reconnecting");
    after(1.2, () => {
      setPhase("restored");
      if (buzz) haptics.success();
      after(ctx.n("hold"), () => setPhase("online"));
    });
  };

  const advance = (buzz = true) => {
    const p = phaseRef.current;
    if (p === "online") {
      clearAll();
      haptics.error();
      setPhase("offline");
    } else if (p === "offline") reconnect(buzz);
  };

  useAutoplay(ctx.isPreview, () => advance(false), { every: 1.6, delay: 0.6 });

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 14 }}>
      <div
        onClick={() => advance()}
        style={{ ...demoCard(26), position: "relative", width: 300, height: 280, flexShrink: 0, overflow: "hidden", display: "flex", flexDirection: "column", cursor: "pointer" }}
      >
        <div style={{ position: "relative", zIndex: 1, height: 52, flexShrink: 0, padding: "0 18px", display: "flex", alignItems: "center", background: Palette.elevated }}>
          <span style={{ fontSize: 20, lineHeight: "25px", fontWeight: 700 }}>{ctx.t("Feed", "动态")}</span>
          <span style={{ flex: 1 }} />
          <Bell size={17} strokeWidth={2.4} color={Palette.secondaryLabel} />
        </div>
        <AnimatePresence initial={false}>
          {phase !== "online" && (
            <motion.div key="banner" initial={{ height: 0 }} animate={{ height: 46 }} exit={{ height: 0 }} transition={sp} style={{ position: "relative", flexShrink: 0 }}>
              <motion.div initial={{ y: -46, opacity: 0 }} animate={{ y: 0, opacity: 1 }} exit={{ y: -46, opacity: 0 }} transition={sp} style={{ position: "absolute", left: 0, right: 0, top: 0 }}>
                <Banner phase={phase} zh={ctx.lang === "zh"} transition={sp} />
              </motion.div>
            </motion.div>
          )}
        </AnimatePresence>
        <motion.div initial={false} animate={{ filter: `saturate(${stale ? 0 : 1})`, opacity: stale ? 0.55 : 1 }} transition={sp}>
          <Feed zh={ctx.lang === "zh"} />
        </motion.div>
        <div style={{ position: "absolute", inset: 0, borderRadius: 26, boxShadow: `inset 0 0 0 1px ${Palette.stroke}`, pointerEvents: "none", zIndex: 2 }} />
      </div>
      <DemoHint ctx={ctx} en="Tap to drop or restore the connection" zh="点击断开或恢复网络" />
    </div>
  );
}

const BANNER: Record<Phase, { title: [string, string]; tint: string }> = {
  online: { title: ["Back online", "已恢复连接"], tint: Palette.green },
  restored: { title: ["Back online", "已恢复连接"], tint: Palette.green },
  offline: { title: ["No internet connection", "网络连接已断开"], tint: "#3A3A3F" },
  reconnecting: { title: ["Reconnecting…", "正在重新连接…"], tint: Palette.indigo },
};

function Banner({ phase, zh, transition }: { phase: Phase; zh: boolean; transition: ReturnType<typeof spring> }) {
  const b = BANNER[phase];
  const symbol = phase === "offline" ? "off" : phase === "reconnecting" ? "wifi" : "check";
  return (
    <motion.div
      initial={false}
      animate={{ backgroundColor: b.tint }}
      transition={transition}
      style={{ height: 46, padding: "0 16px", display: "flex", alignItems: "center", gap: 10, color: "#fff" }}
    >
      <span style={{ position: "relative", width: 22, height: 22, flexShrink: 0 }}>
        <AnimatePresence initial={false}>
          <motion.span
            key={symbol}
            initial={{ scale: 0.4, opacity: 0, filter: "blur(3px)" }}
            animate={{ scale: 1, opacity: 1, filter: "blur(0px)" }}
            exit={{ scale: 0.4, opacity: 0, filter: "blur(3px)" }}
            transition={anim.snappyD(0.3)}
            style={{ position: "absolute", inset: 0, display: "grid", placeItems: "center" }}
          >
            {symbol === "off" ? <WifiOff size={16} strokeWidth={2.8} /> : symbol === "wifi" ? <IterativeWifi /> : <CircleCheck size={17} fill="currentColor" stroke={Palette.green} strokeWidth={2.4} />}
          </motion.span>
        </AnimatePresence>
      </span>
      <span style={{ display: "grid", flex: 1, minWidth: 0 }}>
        <AnimatePresence initial={false}>
          <motion.span key={b.title[0]} initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} transition={transition} style={{ gridArea: "1/1", fontSize: 15, fontWeight: 600, whiteSpace: "nowrap" }}>
            {b.title[zh ? 1 : 0]}
          </motion.span>
        </AnimatePresence>
      </span>
      <AnimatePresence initial={false}>
        {phase === "offline" && (
          <motion.span
            initial={{ scale: 0.8, opacity: 0 }}
            animate={{ scale: 1, opacity: 1 }}
            exit={{ scale: 0.8, opacity: 0 }}
            transition={transition}
            style={{ fontSize: 12, lineHeight: "16px", fontWeight: 700, padding: "5px 10px", borderRadius: 999, background: "rgb(255 255 255 / 0.2)" }}
          >
            {zh ? "重试" : "Retry"}
          </motion.span>
        )}
      </AnimatePresence>
    </motion.div>
  );
}

/** `wifi` with `.symbolEffect(.variableColor.iterative)`: the arcs light up one after another. */
function IterativeWifi() {
  const t = useClock(true);
  const step = Math.floor(t / 0.25) % 4; // 0: dot … 3: outer arc
  const o = (layer: number) => (layer === step ? 1 : 0.35);
  return (
    <svg width={18} height={18} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2.8} strokeLinecap="round">
      <path d="M12 20h.01" opacity={o(0)} strokeWidth={3.6} />
      <path d="M8.5 16.43a5 5 0 0 1 7 0" opacity={o(1)} />
      <path d="M5 12.86a10 10 0 0 1 14 0" opacity={o(2)} />
      <path d="M2 8.82a15 15 0 0 1 20 0" opacity={o(3)} />
    </svg>
  );
}

const ROWS: { Icon: LucideIcon; colors: [string, string]; title: [string, string]; sub: [string, string] }[] = [
  { Icon: Image, colors: [Palette.amber, Palette.coral], title: ["Weekend in Kyoto", "京都的周末"], sub: ["24 new photos", "24 张新照片"] },
  { Icon: Music, colors: [Palette.pink, Palette.violet], title: ["Friday Mix", "周五歌单"], sub: ["Updated by Mia", "米娅更新了歌单"] },
  { Icon: Footprints, colors: [Palette.mint, Palette.sky], title: ["Morning run", "晨跑"], sub: ["5.2 km · 26 min", "5.2 公里 · 26 分钟"] },
  { Icon: Book, colors: [Palette.indigo, Palette.blue], title: ["Reading list", "阅读清单"], sub: ["3 articles saved", "收藏了 3 篇文章"] },
];

function Feed({ zh }: { zh: boolean }) {
  return (
    <div>
      {ROWS.map(({ Icon, colors, title, sub }, i) => (
        <div key={i} style={{ height: 56, padding: "0 18px", display: "flex", alignItems: "center", gap: 12 }}>
          <div style={{ width: 42, height: 42, borderRadius: 11, background: `linear-gradient(135deg, ${colors[0]}, ${colors[1]})`, display: "grid", placeItems: "center", color: "#fff" }}>
            <Icon size={17} strokeWidth={2.4} />
          </div>
          <div style={{ display: "flex", flexDirection: "column", gap: 2 }}>
            <span style={{ fontSize: 15, lineHeight: "20px", fontWeight: 600 }}>{title[zh ? 1 : 0]}</span>
            <span style={{ fontSize: 12, lineHeight: "16px", color: Palette.secondaryLabel }}>{sub[zh ? 1 : 0]}</span>
          </div>
        </div>
      ))}
    </div>
  );
}
