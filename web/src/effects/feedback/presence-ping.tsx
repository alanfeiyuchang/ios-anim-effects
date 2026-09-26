/** feedback.presence-ping · 在线状态涟漪 (Feedback+BadgeVariations.swift) */
import { motion } from "motion/react";
import { useEffect, useRef, useState } from "react";
import { DemoHint, NumericText, Palette, anim, demoCard, useClock, useElapsed, useHaptics, useStageRuntime, type DemoProps } from "../../kit";
import { SPRINGS, track } from "./shared";

const MEMBERS: { initials: string; colors: [string, string] }[] = [
  { initials: "AK", colors: [Palette.sky, Palette.blue] },
  { initials: "SL", colors: [Palette.mint, Palette.green] },
  { initials: "MJ", colors: [Palette.pink, Palette.violet] },
  { initials: "RT", colors: [Palette.amber, Palette.coral] },
  { initials: "DN", colors: [Palette.indigo, Palette.violet] },
];
const USER_HOLD = 6;
const SEQUENCE = [1, 4, 2, 1, 4, 2];

export default function PresencePing({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [online, setOnline] = useState([true, false, true, true, false]);
  const [pops, setPops] = useState([0, 0, 0, 0, 0]);
  const [cycleEpoch, setCycleEpoch] = useState(0);
  const touched = useRef<(number | null)[]>([null, null, null, null, null]);
  const onlineRef = useRef(online);
  onlineRef.current = online;
  const { autoplayEnabled } = useStageRuntime();
  const zh = ctx.lang === "zh";
  const t = useClock(true, ctx.isPreview ? 30 : undefined) + performance.timeOrigin / 1000;
  const onlineCount = online.filter(Boolean).length;

  const flip = (index: number, byUser: boolean) => {
    const now = !onlineRef.current[index];
    const next = onlineRef.current.slice();
    next[index] = now;
    onlineRef.current = next;
    setOnline(next);
    setPops((p) => p.map((v, i) => (i === index ? v + 1 : v)));
    if (byUser && now) haptics.tap("soft");
  };
  const userFlip = (index: number) => {
    touched.current[index] = performance.now() / 1000;
    setCycleEpoch((c) => c + 1);
    flip(index, true);
  };

  const toggleEvery = Math.max(ctx.n("toggle"), 0.5);
  useEffect(() => {
    if (!autoplayEnabled && ctx.isPreview) return;
    let order = 0;
    const id = window.setInterval(() => {
      const now = performance.now() / 1000;
      for (let k = 0; k < SEQUENCE.length; k++) {
        const member = SEQUENCE[order % SEQUENCE.length];
        order += 1;
        const last = touched.current[member];
        if (last !== null && now - last < USER_HOLD) continue;
        flip(member, false);
        break;
      }
    }, toggleEvery * 1000);
    return () => window.clearInterval(id);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [toggleEvery, cycleEpoch, autoplayEnabled, ctx.isPreview]);

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 16 }}>
      <div style={{ ...demoCard(22), padding: 20, width: 296, display: "flex", flexDirection: "column", gap: 16 }}>
        <div style={{ display: "flex", alignItems: "center" }}>
          <span style={{ fontSize: 17, lineHeight: "22px", fontWeight: 600 }}>{zh ? "设计团队" : "Design team"}</span>
          <span style={{ flex: 1 }} />
          <span style={{ display: "flex", alignItems: "center", gap: 4, color: Palette.secondaryLabel, fontSize: 15, fontWeight: 500 }}>
            <span style={{ width: 8, height: 8, borderRadius: "50%", background: Palette.green }} />
            {zh ? (
              <>
                <NumericText value={onlineCount} /> 人在线
              </>
            ) : (
              <>
                <NumericText value={onlineCount} /> online
              </>
            )}
          </span>
        </div>
        <div style={{ display: "flex" }}>
          {MEMBERS.map((m, i) => (
            <Avatar key={i} index={i} member={m} online={online[i]} pops={pops[i]} t={t} period={Math.max(ctx.n("ping"), 0.3)} reach={ctx.n("reach")} onTap={() => userFlip(i)} />
          ))}
        </div>
      </div>
      <DemoHint ctx={ctx} en="Tap an avatar to toggle" zh="点击头像切换状态" />
    </div>
  );
}

function Avatar({ index, member, online, pops, t, period, reach, onTap }: { index: number; member: (typeof MEMBERS)[number]; online: boolean; pops: number; t: number; period: number; reach: number; onTap: () => void }) {
  const raw = (t - index * 0.3) / period;
  const u = raw - Math.floor(raw);
  const e = useElapsed(pops, 0.8, true);
  const pop = e < 0 ? 1 : track(e, 1, [{ move: 0.6 }, { cubic: 1.3, d: 0.15 }, { spring: 1, d: 0.4, ...SPRINGS.bouncy }]);
  const smooth = anim.smoothD(0.35);
  return (
    <div onClick={onTap} style={{ position: "relative", width: 48, height: 48, marginLeft: index === 0 ? 0 : -12, zIndex: MEMBERS.length - index, cursor: "pointer" }}>
      <motion.div
        initial={false}
        animate={{ filter: `saturate(${online ? 1 : 0.45})`, opacity: online ? 1 : 0.8 }}
        transition={smooth}
        style={{ position: "absolute", inset: 0, borderRadius: "50%", background: `linear-gradient(${member.colors[0]}, ${member.colors[1]})`, boxShadow: `0 0 0 1.5px ${Palette.elevated}`, display: "grid", placeItems: "center", color: "#fff", fontSize: 12, fontWeight: 700 }}
      >
        {member.initials}
      </motion.div>
      <div style={{ position: "absolute", right: -1, bottom: -1, width: 14, height: 14 }}>
        <div style={{ position: "absolute", inset: 0, borderRadius: "50%", border: `2px solid ${Palette.green}`, transform: `scale(${1 + (reach - 1) * u})`, opacity: online ? 0.55 * (1 - u) : 0 }} />
        <div style={{ position: "absolute", inset: 0, transform: `scale(${pop})` }}>
          <div style={{ position: "absolute", inset: -3, borderRadius: "50%", background: Palette.elevated }} />
          <motion.div
            initial={false}
            animate={{ backgroundColor: online ? Palette.green : "var(--ml-elevated)", boxShadow: `inset 0 0 0 2px ${online ? Palette.green : "var(--ml-label2)"}` }}
            transition={anim.snappyD(0.3)}
            style={{ position: "absolute", inset: 0, borderRadius: "50%" }}
          />
        </div>
      </div>
    </div>
  );
}
