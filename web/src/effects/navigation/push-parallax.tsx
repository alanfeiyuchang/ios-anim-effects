/** navigation.push-parallax · 视差推入 (Navigation+PushParallax.swift) */
import { animate, useMotionValue } from "motion/react";
import { BellDot, ChevronLeft, ChevronRight, Moon, Palette as PaletteIcon, Wifi, type LucideIcon } from "lucide-react";
import { useRef, useState } from "react";
import { DemoHint, Palette, anim, clamp, hex, spring, useAutoplay, useHaptics, useTimeouts, type DemoContext, type DemoProps } from "../../kit";
import { colorGradient, predicted, useMotionNumber, useNavPan } from "./nav-util";

interface PushItem {
  icon: LucideIcon;
  filled: boolean;
  color: string;
  title: [string, string];
  detail: [string, string];
}

const pushItems: PushItem[] = [
  { icon: Wifi, filled: false, color: Palette.blue, title: ["Wi-Fi", "无线局域网"], detail: ["Studio 5G", "Studio 5G"] },
  { icon: BellDot, filled: false, color: Palette.red, title: ["Notifications", "通知"], detail: ["Banners, sounds", "横幅、声音"] },
  { icon: Moon, filled: true, color: Palette.indigo, title: ["Focus", "专注模式"], detail: ["Off", "关闭"] },
  { icon: PaletteIcon, filled: false, color: Palette.pink, title: ["Appearance", "外观"], detail: ["Automatic", "自动"] },
];

const W = 300;
const H = 320;
const hairline = Palette.labelAlpha(0.14);

export default function PushParallax({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const { after, clearAll } = useTimeouts();
  const progressMV = useMotionValue(0);
  const progress = useMotionNumber(progressMV);
  const [selected, setSelected] = useState(0);
  const previewStep = useRef(0);
  const sp = spring(ctx.n("response"), 1);

  const push = (index: number) => {
    haptics.tap();
    setSelected(index);
    animate(progressMV, 1, sp);
  };
  const pop = () => {
    haptics.tap("soft");
    animate(progressMV, 0, sp);
  };

  const pan = useNavPan(
    {
      onStart: () => {
        clearAll();
        progressMV.stop();
      },
      onChange: (s) => progressMV.set(1 - Math.min(Math.max(s.translation.x, 0) / W, 1)),
      onEnd: (s) => {
        const back = s ? predicted(s).x > W * 0.5 : progressMV.get() < 0.5;
        if (back) pop();
        else animate(progressMV, 1, sp);
      },
    },
    { axis: "horizontal", minimumDistance: 8, enabled: progress > 0.01 },
  );

  /** Previews alternate a push with a simulated half swipe that then completes. */
  useAutoplay(
    ctx.isPreview,
    () => {
      const step = previewStep.current;
      if (step % 2 === 0) push(Math.floor(step / 2) % pushItems.length);
      else {
        animate(progressMV, 0.55, anim.easeOut(0.35));
        clearAll();
        after(0.4, pop);
      }
      previewStep.current += 1;
    },
    { every: 1.6 },
  );

  const item = pushItems[selected];
  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 14 }}>
      <div
        style={{
          position: "relative",
          width: W,
          height: H,
          flexShrink: 0,
          borderRadius: 30,
          overflow: "hidden",
          background: Palette.surface,
          boxShadow: "0 10px 18px rgb(0 0 0 / 0.12)",
          isolation: "isolate",
        }}
      >
        <div style={{ position: "absolute", inset: 0, transform: `translateX(${-W * ctx.n("parallax") * progress}px)` }}>
          <ListScreen ctx={ctx} progress={progress} onSelect={push} />
        </div>
        <div style={{ position: "absolute", inset: 0, background: "#000", opacity: ctx.n("dim") * progress, pointerEvents: "none" }} />
        <div
          {...pan}
          style={{
            position: "absolute",
            inset: 0,
            transform: `translateX(${W * (1 - progress)}px)`,
            boxShadow: progress > 0 ? `-3px 0 14px rgb(0 0 0 / ${0.2 * progress})` : undefined,
            pointerEvents: progress > 0.01 ? "auto" : "none",
          }}
        >
          <DetailScreen ctx={ctx} item={item} progress={progress} onBack={pop} />
        </div>
        <div style={{ position: "absolute", inset: 0, borderRadius: 30, boxShadow: `inset 0 0 0 1px ${Palette.stroke}`, pointerEvents: "none" }} />
      </div>
      <DemoHint ctx={ctx} en="Tap a row, then swipe right to go back" zh="点击一行，再向右滑返回" />
    </div>
  );
}

function IconTile({ item, size, radius, iconSize }: { item: PushItem; size: number; radius: number; iconSize: number }) {
  const Icon = item.icon;
  return (
    <div style={{ width: size, height: size, borderRadius: radius, background: colorGradient(item.color), display: "grid", placeItems: "center", color: "#fff", flexShrink: 0 }}>
      <Icon size={iconSize} strokeWidth={2.4} fill={item.filled ? "currentColor" : "none"} />
    </div>
  );
}

function ListScreen({ ctx, progress, onSelect }: { ctx: DemoContext; progress: number; onSelect: (i: number) => void }) {
  const [pressed, setPressed] = useState<number | null>(null);
  return (
    <div style={{ position: "absolute", inset: 0, background: Palette.surface, display: "flex", flexDirection: "column", gap: 14 }}>
      <div style={{ padding: "18px 20px 0", fontSize: 34, lineHeight: "41px", fontWeight: 700, opacity: 1 - clamp(progress) }}>{ctx.t("Settings", "设置")}</div>
      <div style={{ margin: "0 14px", borderRadius: 16, background: Palette.elevated, overflow: "hidden" }}>
        {pushItems.map((it, index) => (
          <div key={it.title[0]}>
            <button
              type="button"
              onClick={() => onSelect(index)}
              onPointerDown={() => setPressed(index)}
              onPointerUp={() => setPressed(null)}
              onPointerLeave={() => setPressed(null)}
              style={{
                width: "100%",
                height: 50,
                padding: "0 14px",
                display: "flex",
                alignItems: "center",
                gap: 12,
                background: Palette.labelAlpha(pressed === index ? 0.08 : 0),
                transition: "background 0.12s ease-out",
                textAlign: "left",
              }}
            >
              <IconTile item={it} size={30} radius={8} iconSize={15} />
              <span style={{ fontSize: 17, lineHeight: "22px", whiteSpace: "nowrap", flexShrink: 0 }}>{ctx.t(...it.title)}</span>
              <span style={{ marginLeft: "auto", fontSize: 15, lineHeight: "20px", color: Palette.secondaryLabel, whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>
                {ctx.t(...it.detail)}
              </span>
              <ChevronRight size={14} strokeWidth={3} color={Palette.tertiaryLabel} style={{ flexShrink: 0 }} />
            </button>
            {index < pushItems.length - 1 && <div style={{ height: 0.5, marginLeft: 58, background: hairline }} />}
          </div>
        ))}
      </div>
    </div>
  );
}

function DetailScreen({ ctx, item, progress, onBack }: { ctx: DemoContext; item: PushItem; progress: number; onBack: () => void }) {
  return (
    <div style={{ position: "absolute", inset: 0, background: Palette.surface, padding: "10px 14px 0", display: "flex", flexDirection: "column", gap: 18 }}>
      <button
        type="button"
        onClick={onBack}
        style={{
          alignSelf: "flex-start",
          height: 36,
          display: "flex",
          alignItems: "center",
          gap: 3,
          color: Palette.indigo,
          fontSize: 17,
          transform: `translateX(${-W * 0.6 * (1 - progress)}px)`,
          opacity: clamp(progress),
        }}
      >
        <ChevronLeft size={20} strokeWidth={2.8} style={{ marginLeft: -4 }} />
        {ctx.t("Settings", "设置")}
      </button>
      <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 10 }}>
        <div style={{ borderRadius: 18, boxShadow: `0 6px 12px ${hex(item.color, 0.35)}` }}>
          <IconTile item={item} size={68} radius={18} iconSize={30} />
        </div>
        <div style={{ fontSize: 20, lineHeight: "25px", fontWeight: 700 }}>{ctx.t(...item.title)}</div>
      </div>
      <div style={{ borderRadius: 16, background: Palette.elevated }}>
        <SettingRow title={ctx.t("Enabled", "开启")} on />
        <div style={{ height: 0.5, marginLeft: 14, background: hairline }} />
        <SettingRow title={ctx.t("Show on Lock Screen", "在锁定屏幕显示")} on={false} />
      </div>
    </div>
  );
}

function SettingRow({ title, on }: { title: string; on: boolean }) {
  return (
    <div style={{ height: 46, padding: "0 14px", display: "flex", alignItems: "center", justifyContent: "space-between" }}>
      <span style={{ fontSize: 15, lineHeight: "20px" }}>{title}</span>
      <div style={{ width: 44, height: 26, borderRadius: 13, background: on ? Palette.green : Palette.labelAlpha(0.12), padding: 2, display: "flex", justifyContent: on ? "flex-end" : "flex-start" }}>
        <div style={{ width: 22, height: 22, borderRadius: "50%", background: "#fff", boxShadow: "0 1px 2px rgb(0 0 0 / 0.15)" }} />
      </div>
    </div>
  );
}
