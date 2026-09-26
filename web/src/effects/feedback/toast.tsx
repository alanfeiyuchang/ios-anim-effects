/** feedback.toast · 模糊滑入吐司 (Feedback+Toast.swift) */
import { motion, useTransform } from "motion/react";
import { Download, Check } from "lucide-react";
import { useRef } from "react";
import { DemoHint, Palette, anim, glass, rubberBand, spring, useAutoplay, useHaptics, usePan, useTimeouts, type DemoProps } from "../../kit";
import { PrimaryCapsule, predicted, useAnimated } from "./shared";

export default function Toast({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const { after, clearAll } = useTimeouts();
  const fromTop = ctx.i("edge") === 0;
  const [shown, showTo] = useAnimated(0);
  const [dragY, dragTo, dragSet] = useAnimated(0);
  const isShown = useRef(false);
  const blur = ctx.n("blur");

  const show = () => {
    dragSet(0);
    clearAll();
    haptics.success();
    isShown.current = true;
    showTo(1, spring(ctx.n("response"), 0.72));
    after(ctx.n("hold"), () => {
      isShown.current = false;
      showTo(0, anim.smoothD(0.35));
    });
  };

  const pan = usePan(
    {
      onChange: ({ translation }) => {
        if (!isShown.current) return;
        const toward = fromTop ? -translation.y : translation.y;
        const travel = toward > 0 ? toward : rubberBand(toward, 14);
        dragSet(fromTop ? -travel : travel);
      },
      onEnd: ({ translation, velocity }) => {
        if (!isShown.current) return;
        const toward = fromTop ? -translation.y : translation.y;
        const flick = predicted(toward, fromTop ? -velocity.y : velocity.y);
        if (toward > 30 || flick > 90) {
          clearAll();
          haptics.tap("soft");
          isShown.current = false;
          showTo(0, anim.smoothD(0.3));
          dragTo(0, anim.smoothD(0.3));
        } else {
          dragTo(0, spring(0.35, 0.75));
        }
      },
    },
    4,
  );

  useAutoplay(ctx.isPreview, show, { every: ctx.n("hold") + 1.4, delay: 0.4 });

  const scale = useTransform(shown, (p) => 0.86 + 0.14 * p);
  const filter = useTransform(shown, (p) => `blur(${Math.max(0, blur * (1 - p))}px)`);
  const opacity = useTransform(shown, (p) => Math.min(Math.max(p, 0), 1));
  const y = useTransform(() => (1 - shown.get()) * (fromTop ? -110 : 110) + dragY.get());
  const pointerEvents = useTransform(shown, (p) => (p > 0.5 ? "auto" : "none"));

  return (
    <div style={{ position: "absolute", inset: 0 }}>
      <div style={{ position: "absolute", left: 0, right: 0, [fromTop ? "top" : "bottom"]: 28, display: "flex", justifyContent: "center" }}>
        <motion.div {...pan} style={{ ...pan.style, scale, filter, opacity, y, pointerEvents, cursor: "grab" }}>
          <ToastPill zh={ctx.lang === "zh"} />
        </motion.div>
      </div>
      <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 14, pointerEvents: "none" }}>
        <PrimaryCapsule onClick={show} style={{ pointerEvents: "auto" }}>
          <Download size={18} strokeWidth={2.4} />
          {ctx.t("Save Photo", "保存图片")}
        </PrimaryCapsule>
        <DemoHint ctx={ctx} en="Tap Save Photo, then swipe the toast away" zh="点击“保存图片”，再把吐司划走" />
      </div>
    </div>
  );
}

function ToastPill({ zh }: { zh: boolean }) {
  return (
    <div
      style={{
        display: "flex",
        alignItems: "center",
        gap: 12,
        padding: "9px 20px 9px 10px",
        borderRadius: 999,
        ...glass("regular"),
        boxShadow: `inset 0 0 0 1px ${Palette.stroke}, 0 8px 18px rgb(0 0 0 / 0.15)`,
      }}
    >
      <div style={{ width: 28, height: 28, borderRadius: "50%", background: Palette.green, display: "grid", placeItems: "center", color: "#fff" }}>
        <Check size={15} strokeWidth={3.6} />
      </div>
      <div style={{ display: "flex", flexDirection: "column", gap: 1 }}>
        <span style={{ fontSize: 15, lineHeight: "20px", fontWeight: 600, whiteSpace: "nowrap" }}>{zh ? "已保存到相册" : "Saved to Photos"}</span>
        <span style={{ fontSize: 12, lineHeight: "16px", color: Palette.secondaryLabel, whiteSpace: "nowrap" }}>{zh ? "1 张图片" : "1 item"}</span>
      </div>
    </div>
  );
}
