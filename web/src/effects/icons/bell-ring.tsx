/** icons.bell-ring · 铃铛摇响 (Icons+BellRing.swift) */
import { AnimatePresence, motion } from "motion/react";
import { Calendar, MessageCircle, MessagesSquare, Package } from "lucide-react";
import { useState, type ReactNode } from "react";
import { DemoHint, NumericText, Palette, fonts, glass, spring, textStyle, useAutoplay, useHaptics, type DemoProps } from "../../kit";
import { C, Glyph, L, S, SPRINGS, SYM, arc, sym, track, trackDuration, useSince } from "./_icons-kit";

const MESSAGES: { icon: ReactNode; en: string; zh: string }[] = [
  { icon: <MessageCircle size={13} fill="currentColor" strokeWidth={1.5} />, en: "Mia sent you a photo", zh: "Mia 给你发了一张照片" },
  { icon: <Calendar size={13} strokeWidth={2.8} />, en: "Design review in 10 min", zh: "设计评审 10 分钟后开始" },
  { icon: <Package size={13} strokeWidth={2.6} />, en: "Your order has shipped", zh: "你的订单已发货" },
  { icon: <MessagesSquare size={13} fill="currentColor" strokeWidth={1.5} />, en: "3 new comments on “Aurora”", zh: "「极光」有 3 条新评论" },
];

const WAVE_RIGHT = [{ d: arc(4, 12, 4.2, -42, 42) + arc(4, 12, 8.6, -44, 44) + arc(4, 12, 13, -46, 46), mode: "stroke" as const, sw: 2.2 }];
const WAVE_LEFT = [{ d: arc(20, 12, 4.2, 138, 222) + arc(20, 12, 8.6, 136, 224) + arc(20, 12, 13, 134, 226), mode: "stroke" as const, sw: 2.2 }];

export default function BellRing({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [rings, setRings] = useState(0);
  const [badge, setBadge] = useState(2);
  const tempo = Math.max(ctx.n("tempo"), 0.1);
  const amp = ctx.n("amplitude");
  const step = 0.12 / tempo;

  const angleTrack = [C(amp, step * 0.8), C(-amp * 0.85, step), C(amp * 0.6, step), C(-amp * 0.4, step), C(amp * 0.18, step), C(0, step * 1.4)];
  const scaleTrack = [S(1.12, 0.14 / tempo, SPRINGS.snappy), S(1.0, 0.5 / tempo, SPRINGS.bouncy)];
  const badgeTrack = [L(1, 0.1 / tempo), S(1.25, 0.12 / tempo, SPRINGS.snappy), S(1.0, 0.45 / tempo, SPRINGS.bouncy)];
  const wavesTrack = [L(1, 0.08 / tempo), L(1, 0.18 / tempo), C(0, 0.3 / tempo)];
  const total = Math.max(trackDuration(angleTrack), trackDuration(scaleTrack), trackDuration(badgeTrack), trackDuration(wavesTrack));
  const t = useSince(rings, total);
  const at = (frames: typeof angleTrack, initial: number) => (t < 0 ? initial : track(t, initial, frames));
  const angle = at(angleTrack, 0);
  const scale = at(scaleTrack, 1);
  const badgeScale = at(badgeTrack, 1);
  const waves = at(wavesTrack, 0);

  const ring = () => {
    setRings((r) => r + 1);
    setBadge((b) => (b >= 99 ? 1 : b + 1));
    haptics.tap("medium");
  };
  useAutoplay(ctx.isPreview, ring, { every: 1.8, delay: 0.3 });

  const message = MESSAGES[badge % MESSAGES.length];
  const bell = sym(76);

  return (
    <div
      onClick={ring}
      style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 24, cursor: "pointer" }}
    >
      <div style={{ position: "relative", width: 180, height: 150, display: "grid", placeItems: "center" }}>
        <div
          style={{
            position: "absolute",
            inset: 0,
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            gap: 65,
            color: Palette.amber,
            opacity: waves,
            transform: `scale(${0.85 + waves * 0.15})`,
          }}
        >
          <Glyph def={WAVE_LEFT} size={sym(26)} />
          <Glyph def={WAVE_RIGHT} size={sym(26)} />
        </div>
        <div style={{ transform: `scale(${scale})`, filter: `drop-shadow(0 10px 16px rgb(255 122 92 / 0.35))` }}>
          <div style={{ position: "relative", width: bell, height: bell, transform: `rotate(${angle}deg)`, transformOrigin: "50% 8%" }}>
            <Glyph
              def={SYM.bellFill}
              size={bell}
              paint="url(#bell-ring-sunset)"
              defs={
                <linearGradient id="bell-ring-sunset" x1="0" y1="0" x2="1" y2="1">
                  <stop offset="0" stopColor={Palette.amber} />
                  <stop offset="0.5" stopColor={Palette.coral} />
                  <stop offset="1" stopColor={Palette.pink} />
                </linearGradient>
              }
            />
            <div style={{ position: "absolute", right: bell - bell * (20.74 / 24) - 20, top: bell * (2 / 24) - 15 }}>
              <div style={{ transform: `scale(${badgeScale})` }}>
                <BadgeCount count={badge} />
              </div>
            </div>
          </div>
        </div>
      </div>
      <div style={{ position: "relative", height: 50, width: 340, display: "grid", placeItems: "center" }}>
        <AnimatePresence initial={false}>
          <motion.div
            key={badge}
            initial={{ y: -18, scale: 0.92, opacity: 0 }}
            animate={{ y: 0, scale: 1, opacity: 1 }}
            exit={{ y: 10, scale: 1, opacity: 0 }}
            transition={spring(0.35, 0.55)}
            style={{ gridArea: "1 / 1" }}
          >
            <Banner icon={message.icon} text={ctx.t(message.en, message.zh)} />
          </motion.div>
        </AnimatePresence>
      </div>
      <DemoHint ctx={ctx} en="Tap to ring" zh="点击摇铃" />
    </div>
  );
}

function BadgeCount({ count }: { count: number }) {
  return (
    <div
      style={{
        minWidth: 26,
        height: 26,
        padding: "0 7px",
        borderRadius: 13,
        background: Palette.red,
        boxShadow: "inset 0 0 0 2px #fff",
        display: "grid",
        placeItems: "center",
        color: "#fff",
        fontFamily: fonts.rounded,
        fontSize: 15,
        fontWeight: 700,
      }}
    >
      <NumericText value={count} />
    </div>
  );
}

function Banner({ icon, text }: { icon: ReactNode; text: string }) {
  return (
    <div
      style={{
        display: "flex",
        alignItems: "center",
        gap: 10,
        height: 42,
        paddingLeft: 8,
        paddingRight: 14,
        borderRadius: 21,
        ...glass("regular"),
        boxShadow: `inset 0 0 0 1px ${Palette.stroke}, 0 6px 12px rgb(0 0 0 / 0.1)`,
        whiteSpace: "nowrap",
      }}
    >
      <div style={{ width: 26, height: 26, borderRadius: 8, background: Palette.sunset, display: "grid", placeItems: "center", color: "#fff" }}>{icon}</div>
      <span style={{ ...textStyle.footnote, fontWeight: 600 }}>{text}</span>
    </div>
  );
}
