/** buttons.approve-stamp · 印章确认 (Buttons+ApproveStamp.swift) */
import { motion } from "motion/react";
import { Check, Plane } from "lucide-react";
import { useRef, useState } from "react";
import { DemoHint, Palette, alpha, anim, demoCard, fonts, useAutoplay, useHaptics, useTimeouts, type DemoProps } from "../../kit";
import { BlurReplace, PressButton, SNAPPY, cubicKF, linearKF, springKF, track, trackDuration, useSince } from "./_a-kit";

function SignatureGlyph() {
  return (
    <svg viewBox="0 0 24 24" width={20} height={20} fill="none" stroke="currentColor" strokeWidth={2} strokeLinecap="round" strokeLinejoin="round">
      <path d="M3 16c2.5-6 5-9.5 6.5-9 1.6.6-1.5 8.8-.3 9.3 1 .4 2.4-3.8 3.6-3.6 1 .2.4 3 1.5 3.2.9.2 1.7-1.6 2.7-1.5.8.1.9 1.3 2 1.4" />
      <path d="M3 20.5h18" />
    </svg>
  );
}

export default function ApproveStamp({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const { after } = useTimeouts();
  const [approved, setApproved] = useState(false);
  const approvedRef = useRef(false);
  const [impacts, setImpacts] = useState(0);
  const fall = ctx.n("fall");
  const jolt = ctx.n("jolt");
  const zh = ctx.lang === "zh";

  const toggle = (muted = false) => {
    if (approvedRef.current) {
      approvedRef.current = false;
      setApproved(false);
      haptics.tap();
      return;
    }
    approvedRef.current = true;
    setApproved(true);
    setImpacts((n) => n + 1);
    after(fall, () => !muted && haptics.tap("rigid"));
  };
  useAutoplay(ctx.isPreview, () => toggle(true), { every: 1.8, delay: 0.4 });

  const joltTrack = [linearKF(0, fall), cubicKF(jolt, 0.05), cubicKF(-jolt / 3, 0.08), springKF(0, 0.12, SNAPPY)];
  const splashTrack = [linearKF(0, fall), cubicKF(1, 0.45)];
  const t = useSince(impacts, Math.max(trackDuration(joltTrack), trackDuration(splashTrack)));
  const dy = track(t, 0, joltTrack);
  const splash = track(t, 0, splashTrack);
  const stampT = approved ? anim.easeIn(fall) : anim.easeOut(0.25);

  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center" }}>
      <div style={{ flex: 1 }} />
      <div
        style={{
          ...demoCard(22),
          position: "relative",
          width: 290,
          padding: 18,
          display: "flex",
          flexDirection: "column",
          gap: 16,
          flexShrink: 0,
          transform: `translateY(${dy}px)`,
        }}
      >
        <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
          <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
            <div style={{ width: 34, height: 34, borderRadius: 10, background: alpha(Palette.sky, 0.14), color: Palette.sky, display: "grid", placeItems: "center" }}>
              <Plane size={16} fill="currentColor" strokeWidth={1.4} style={{ transform: "rotate(45deg)" }} />
            </div>
            <div style={{ display: "flex", flexDirection: "column", gap: 2 }}>
              <div style={{ fontSize: 15, lineHeight: "20px", fontWeight: 600, color: Palette.label }}>{ctx.t("Flight to Lisbon", "飞往里斯本的机票")}</div>
              <div style={{ fontSize: 12, lineHeight: "16px", color: Palette.secondaryLabel }}>{ctx.t("Mar 14 · Design offsite", "3 月 14 日 · 设计团建")}</div>
            </div>
          </div>
          <div style={{ height: 0.5, background: Palette.labelAlpha(0.2) }} />
          <div style={{ display: "flex", alignItems: "baseline" }}>
            <span style={{ fontSize: 15, color: Palette.secondaryLabel }}>{ctx.t("Total", "合计")}</span>
            <span style={{ flex: 1 }} />
            <span style={{ fontFamily: fonts.rounded, fontSize: 22, lineHeight: "28px", fontWeight: 700, color: Palette.label, fontVariantNumeric: "tabular-nums" }}>€ 428.60</span>
          </div>
        </div>
        <PressButton
          scale={0.97}
          dim={0.05}
          onClick={() => toggle()}
          style={{
            height: 50,
            borderRadius: 14,
            background: approved ? Palette.labelAlpha(0.07) : Palette.successStrong,
            transition: "background 0.25s",
            fontSize: 17,
            fontWeight: 600,
          }}
        >
          <BlurReplace id={approved ? "done" : "todo"}>
            {approved ? (
              <span style={{ display: "flex", alignItems: "center", gap: 6, color: Palette.secondaryLabel }}>
                <Check size={18} strokeWidth={2.8} />
                {zh ? "已批准 · 撤销" : "Approved · Undo"}
              </span>
            ) : (
              <span style={{ display: "flex", alignItems: "center", gap: 6, color: "#fff" }}>
                <SignatureGlyph />
                {zh ? "批准" : "Approve"}
              </span>
            )}
          </BlurReplace>
        </PressButton>
        <div style={{ position: "absolute", left: "50%", top: "50%", width: 0, height: 0, pointerEvents: "none" }}>
          <div style={{ position: "absolute", transform: "translate(40px, -24px)" }}>
            <motion.div
              initial={false}
              animate={{ scale: approved ? 1 : ctx.n("start"), filter: approved ? "blur(0px)" : "blur(6px)", opacity: approved ? 1 : 0 }}
              transition={stampT}
              style={{ position: "absolute", left: 0, top: 0, rotate: -12 }}
            >
              {Array.from({ length: 6 }, (_, i) => {
                const rad = ((i * 60 + 18) * Math.PI) / 180;
                const distance = 60 + 30 * splash;
                const size = 3 + (i % 3);
                const visible = splash > 0.001 && splash < 0.999;
                return (
                  <div
                    key={i}
                    style={{
                      position: "absolute",
                      left: Math.cos(rad) * distance - size / 2,
                      top: Math.sin(rad) * distance * 0.6 - size / 2,
                      width: size,
                      height: size,
                      borderRadius: "50%",
                      background: Palette.green,
                      opacity: visible ? 1 - splash : 0,
                    }}
                  />
                );
              })}
              <div
                style={{
                  position: "absolute",
                  left: 0,
                  top: 0,
                  transform: "translate(-50%, -50%)",
                  padding: "6px 14px",
                  borderRadius: 8,
                  boxShadow: `inset 0 0 0 3px ${Palette.green}`,
                  color: Palette.green,
                  fontFamily: fonts.rounded,
                  fontSize: 26,
                  lineHeight: "31px",
                  fontWeight: 900,
                  letterSpacing: zh ? 6 : 2,
                  whiteSpace: "nowrap",
                  opacity: 0.88,
                }}
              >
                {ctx.t("APPROVED", "已批准")}
              </div>
            </motion.div>
          </div>
        </div>
      </div>
      <div style={{ flex: 1 }} />
      <DemoHint ctx={ctx} en="Tap Approve" zh="点击批准" style={{ paddingBottom: 18 }} />
    </div>
  );
}
