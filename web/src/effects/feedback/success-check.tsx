/** feedback.success-check · 成功对勾 (Feedback+Status.swift) */
import { useState } from "react";
import { DemoHint, Palette, alpha, ease, useAutoplay, useElapsed, useHaptics, useTimeouts, type DemoProps } from "../../kit";
import { SPRINGS, track } from "./shared";

export default function SuccessCheck({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const { after } = useTimeouts();
  const [plays, setPlays] = useState(0);
  const d = ctx.n("speed");
  const sparks = ctx.b("sparks");
  const t = useElapsed(plays, 1.6 * d + 0.5, true);
  const idle = t < 0;
  const ring = idle ? 1 : track(t, 1, [{ move: 0 }, { linear: 1, d: 0.45 * d, curve: ease.inOut }]);
  const fill = idle ? 1 : track(t, 1, [{ move: 0 }, { linear: 0, d: 0.38 * d }, { spring: 1, d: 0.5 * d, ...SPRINGS.bouncy }]);
  const check = idle ? 1 : track(t, 1, [{ move: 0 }, { linear: 0, d: 0.6 * d }, { linear: 1, d: 0.3 * d, curve: ease.out }]);
  const burst = idle ? 1 : track(t, 1, [{ move: 0 }, { linear: 0, d: 0.42 * d }, { linear: 1, d: 0.5 * d, curve: ease.out }]);

  const play = (silent = false) => {
    setPlays((p) => p + 1);
    // Autoplay / intro plays are silent; the delayed buzz would fire after the mute ends, so skip it.
    if (silent) return;
    after(0.6 * d, () => haptics.success());
  };
  useAutoplay(ctx.isPreview, () => play(true), { every: 2.4, delay: 0.3 });

  const C = 2 * Math.PI * 53;
  return (
    <div onClick={() => play()} style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 22, cursor: "pointer" }}>
      <div style={{ position: "relative", width: 110, height: 110, marginBottom: 30 }}>
        {sparks &&
          Array.from({ length: 8 }, (_, i) => (
            <div
              key={i}
              style={{
                position: "absolute",
                left: 53,
                top: 49,
                width: 4,
                height: 12,
                borderRadius: 2,
                background: Palette.green,
                transform: `rotate(${i * 45}deg) translateY(${-(62 + 30 * burst)}px)`,
                opacity: burst > 0 && burst < 1 ? 1 - burst : 0,
              }}
            />
          ))}
        <svg width={110} height={110} style={{ position: "absolute", inset: 0, overflow: "visible" }}>
          <circle cx={55} cy={55} r={53} fill="none" stroke={Palette.green} strokeWidth={4} strokeLinecap="round" strokeDasharray={`${Math.max(ring, 0) * C} ${C}`} transform="rotate(-90 55 55)" style={{ opacity: ring > 0.001 ? 1 : 0 }} />
        </svg>
        <div
          style={{
            position: "absolute",
            inset: 0,
            borderRadius: "50%",
            background: `linear-gradient(#4BE08F, ${Palette.green})`,
            transform: `scale(${fill})`,
            boxShadow: `0 6px 14px ${alpha(Palette.green, 0.4)}`,
          }}
        />
        <svg width={46} height={36} viewBox="0 0 46 36" style={{ position: "absolute", left: 32, top: 37, overflow: "visible" }}>
          <path
            d={`M ${46 * 0.04} ${36 * 0.55} L ${46 * 0.37} ${36 - 36 * 0.04} L ${46 - 46 * 0.03} ${36 * 0.06}`}
            fill="none"
            stroke="#fff"
            strokeWidth={8}
            strokeLinecap="round"
            strokeLinejoin="round"
            pathLength={1}
            strokeDasharray={`${Math.max(check, 0)} 2`}
            style={{ opacity: check > 0.001 ? 1 : 0 }}
          />
        </svg>
        <div style={{ position: "absolute", left: "50%", bottom: 0, transform: `translate(-50%, ${44 + 8 * (1 - check)}px)`, opacity: check, fontSize: 17, lineHeight: "22px", fontWeight: 600, whiteSpace: "nowrap" }}>
          {ctx.t("Payment complete", "支付成功")}
        </div>
      </div>
      <DemoHint ctx={ctx} en="Tap to replay" zh="点击重播" />
    </div>
  );
}
