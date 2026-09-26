/** buttons.follow-morph · 关注形变 (Buttons+FollowMorph.swift) */
import { motion } from "motion/react";
import { Check, Plus } from "lucide-react";
import { useLayoutEffect, useRef, useState } from "react";
import { DemoHint, NumericText, Palette, demoCard, fonts, spring, useAutoplay, useHaptics, type DemoProps } from "../../kit";
import { BlurReplace, SymbolReplace, cubicKF, moveKF, track, useSince } from "./_a-kit";

export default function FollowMorph({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [following, setFollowing] = useState(false);
  const [followers, setFollowers] = useState(12480);
  const [pulses, setPulses] = useState(0);
  const [pressed, setPressed] = useState(false);
  const zh = ctx.lang === "zh";
  const t = spring(ctx.n("response"), ctx.n("damping"));

  const toggle = () => {
    const becoming = !following;
    haptics.tap(becoming ? "medium" : "light");
    setFollowing(becoming);
    setFollowers((f) => f + (becoming ? 1 : -1));
    if (becoming) setPulses((p) => p + 1);
  };
  useAutoplay(ctx.isPreview, toggle, { every: 1.6, delay: 0.5 });

  // Measure both labels so the pill's width can spring between them like the SwiftUI layout does.
  const measure = useRef<HTMLDivElement>(null);
  const [widths, setWidths] = useState<[number, number]>([40, 56]);
  useLayoutEffect(() => {
    const el = measure.current;
    if (!el) return;
    const spans = el.querySelectorAll("span");
    setWidths([spans[0].offsetWidth, spans[1].offsetWidth]);
  }, [zh]);
  const width = (following ? widths[1] + 32 : widths[0] + 36) + 13 + 6;

  const ringT = useSince(pulses, 0.6);
  const ringScale = track(ringT, 1, [moveKF(1), cubicKF(1.35, 0.6)]);
  const ringOpacity = ringT < 0 ? 0 : track(ringT, 0, [moveKF(0.9), cubicKF(0, 0.6)]);
  const verified = following && ctx.b("badge");
  const label = { fontSize: 15, fontWeight: 600, whiteSpace: "nowrap" as const };

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center" }}>
      <div ref={measure} style={{ position: "absolute", visibility: "hidden", pointerEvents: "none" }}>
        <span style={label}>{zh ? "关注" : "Follow"}</span>
        <span style={label}>{zh ? "已关注" : "Following"}</span>
      </div>
      <div style={{ flex: 1 }} />
      <div style={{ ...demoCard(24), width: 300, padding: 18, display: "flex", flexDirection: "column", gap: 18, flexShrink: 0 }}>
        <div style={{ display: "flex", alignItems: "center", gap: 14 }}>
          <div style={{ position: "relative", width: 56, height: 56, flexShrink: 0 }}>
            <div
              style={{
                position: "absolute",
                inset: 0,
                borderRadius: "50%",
                padding: 2,
                background: Palette.primary,
                WebkitMask: "linear-gradient(#000 0 0) content-box, linear-gradient(#000 0 0)",
                WebkitMaskComposite: "xor",
                mask: "linear-gradient(#000 0 0) content-box exclude, linear-gradient(#000 0 0)",
                transform: `scale(${ringScale})`,
                opacity: ringOpacity,
              }}
            />
            <div
              style={{
                position: "absolute",
                inset: 0,
                borderRadius: "50%",
                background: `linear-gradient(135deg, ${Palette.sky}, ${Palette.violet}, ${Palette.pink})`,
                boxShadow: "inset 0 0 0 1px rgb(255 255 255 / 0.35)",
                display: "grid",
                placeItems: "center",
                fontFamily: fonts.rounded,
                fontSize: 19,
                fontWeight: 700,
                color: "#fff",
              }}
            >
              ML
            </div>
            <motion.div
              initial={false}
              animate={{ scale: verified ? 1 : 0.2, opacity: verified ? 1 : 0 }}
              transition={{ ...spring(0.35, 0.5), delay: verified ? 0.12 : 0 }}
              style={{ position: "absolute", right: -3 - 1, bottom: -3 - 1, width: 22, height: 22, display: "grid", placeItems: "center" }}
            >
              <div style={{ position: "absolute", inset: 2, borderRadius: "50%", background: Palette.elevated }} />
              <svg viewBox="0 0 24 24" width={22} height={22} style={{ position: "relative" }}>
                <path
                  d="M12 1.5l2.4 1.8 3-.2 1 2.8 2.6 1.6-.7 2.9 1.2 2.7-2.1 2.1-.3 3-2.9.6-1.9 2.3-2.8-1-2.8 1-1.9-2.3-2.9-.6-.3-3-2.1-2.1 1.2-2.7-.7-2.9L5.6 5.9l1-2.8 3 .2Z"
                  fill={Palette.blue}
                />
                <path d="M7.8 12.2l2.8 2.8 5.6-5.8" fill="none" stroke="#fff" strokeWidth={2.2} strokeLinecap="round" strokeLinejoin="round" />
              </svg>
            </motion.div>
          </div>
          <div style={{ display: "flex", flexDirection: "column", gap: 3, minWidth: 0 }}>
            <div style={{ fontSize: 17, lineHeight: "22px", fontWeight: 600, color: Palette.label }}>{zh ? "林墨" : "Mira Lin"}</div>
            <div style={{ fontSize: 12, lineHeight: "16px", color: Palette.secondaryLabel, whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>
              {zh ? "@linmo · 动效设计师" : "@miralin · Motion designer"}
            </div>
          </div>
        </div>
        <div style={{ display: "flex", alignItems: "center", gap: 18 }}>
          <Stat value={<NumericText value={followers} text={followers.toLocaleString("en-US")} />} label={ctx.t("Followers", "粉丝")} />
          <Stat value="86" label={ctx.t("Posts", "作品")} />
          <div style={{ flex: 1 }} />
          <motion.button
            type="button"
            onClick={toggle}
            onPointerDown={() => setPressed(true)}
            onPointerUp={() => setPressed(false)}
            onPointerLeave={() => setPressed(false)}
            initial={false}
            animate={{
              width,
              scale: pressed ? 0.94 : 1,
              boxShadow: following ? "0px 5px 10px rgba(110, 123, 255, 0)" : "0px 5px 10px rgba(110, 123, 255, 0.35)",
            }}
            transition={{ default: t, scale: spring(0.25, 0.7) }}
            style={{
              position: "relative",
              height: 38,
              borderRadius: 19,
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              gap: 6,
              color: following ? Palette.label : "#fff",
              flexShrink: 0,
            }}
          >
            <motion.div initial={false} animate={{ opacity: following ? 0 : 1 }} transition={t} style={{ position: "absolute", inset: 0, borderRadius: 19, background: Palette.primary }} />
            <motion.div initial={false} animate={{ opacity: following ? 1 : 0 }} transition={t} style={{ position: "absolute", inset: 0, borderRadius: 19, background: Palette.labelAlpha(0.08) }} />
            <div
              style={{
                position: "absolute",
                inset: 0,
                borderRadius: 19,
                boxShadow: `inset 0 0 0 1px ${following ? Palette.labelAlpha(0.14) : "rgb(255 255 255 / 0.22)"}`,
              }}
            />
            <SymbolReplace id={following ? "check" : "plus"} style={{ position: "relative" }}>
              {following ? <Check size={14} strokeWidth={3.2} /> : <Plus size={14} strokeWidth={3.2} />}
            </SymbolReplace>
            <BlurReplace id={following ? "on" : "off"} style={{ ...label, position: "relative" }}>
              <span>{following ? (zh ? "已关注" : "Following") : zh ? "关注" : "Follow"}</span>
            </BlurReplace>
          </motion.button>
        </div>
      </div>
      <div style={{ flex: 1 }} />
      <DemoHint ctx={ctx} en="Tap Follow" zh="点击关注" style={{ paddingBottom: 18 }} />
    </div>
  );
}

function Stat({ value, label }: { value: React.ReactNode; label: string }) {
  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 2 }}>
      <div style={{ fontFamily: fonts.rounded, fontSize: 15, lineHeight: "20px", fontWeight: 700, color: Palette.label, fontVariantNumeric: "tabular-nums" }}>{value}</div>
      <div style={{ fontSize: 11, lineHeight: "13px", color: Palette.secondaryLabel }}>{label}</div>
    </div>
  );
}
