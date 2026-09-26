/** loading.skeleton-shimmer · 骨架屏微光 (Loading+Ambient.swift) */
import { motion } from "motion/react";
import { useId, useState } from "react";
import { DemoHint, Palette, anim, demoCard, useAutoplay, type DemoProps } from "../../kit";
import { Mountains2, previewFps, primary, usePhase } from "./shared";

const W = 248;
const H = 206;

/** SkeletonLayout geometry (VStack spacing 14: 110 image, 40 avatar row, two placeholder lines). */
function shapes(fill: string) {
  return (
    <>
      <rect x={0} y={0} width={W} height={110} rx={14} fill={fill} />
      <circle cx={20} cy={144} r={20} fill={fill} />
      <rect x={52} y={130} width={130} height={10} rx={5} fill={fill} />
      <rect x={52} y={148} width={84} height={10} rx={5} fill={fill} />
      <rect x={0} y={178} width={W} height={10} rx={5} fill={fill} />
      <rect x={0} y={196} width={120} height={10} rx={5} fill={fill} />
    </>
  );
}

export default function SkeletonShimmer({ ctx }: DemoProps) {
  const [loaded, setLoaded] = useState(false);
  const toggle = () => setLoaded((l) => !l);
  useAutoplay(ctx.isPreview, toggle, { every: 2.6, delay: 1.6 });
  const t = anim.smoothD(0.5);
  return (
    <div
      onClick={toggle}
      style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 18, cursor: "pointer" }}
    >
      <div style={{ ...demoCard(), width: 280, padding: 16, display: "grid", alignItems: "center" }}>
        <motion.div initial={false} animate={{ opacity: loaded ? 0 : 1 }} transition={t} style={{ gridArea: "1 / 1" }}>
          <Skeleton speed={ctx.n("speed")} band={ctx.n("band")} degrees={ctx.n("angle")} preview={ctx.isPreview} dark={ctx.scheme === "dark"} />
        </motion.div>
        <motion.div
          initial={false}
          animate={{ opacity: loaded ? 1 : 0, filter: `blur(${loaded ? 0 : 8}px)`, scale: loaded ? 1 : 0.98 }}
          transition={t}
          style={{ gridArea: "1 / 1" }}
        >
          <LoadedCard zh={ctx.lang === "zh"} />
        </motion.div>
      </div>
      <DemoHint ctx={ctx} en="Tap to toggle loaded state" zh="点击切换加载状态" />
    </div>
  );
}

function Skeleton({ speed, band, degrees, preview, dark }: { speed: number; band: number; degrees: number; preview: boolean; dark: boolean }) {
  const id = useId().replace(/:/g, "");
  const t = usePhase(speed, previewFps(preview));
  const tilt = band * Math.tan((Math.min(Math.max(degrees, 0), 80) * Math.PI) / 180);
  const x = ((t / 1.4) % 1) * (1.4 + band * 2) - 0.2 - band;
  const peak = dark ? 0.14 : 0.7;
  return (
    <svg width={W} height={H} viewBox={`0 0 ${W} ${H}`} style={{ display: "block" }}>
      <defs>
        <linearGradient id={`g${id}`} gradientUnits="userSpaceOnUse" x1={(x - band) * W} y1={(0.5 - tilt) * H} x2={(x + band) * W} y2={(0.5 + tilt) * H}>
          <stop offset={0} stopColor="#fff" stopOpacity={0} />
          <stop offset={0.5} stopColor="#fff" stopOpacity={peak} />
          <stop offset={1} stopColor="#fff" stopOpacity={0} />
        </linearGradient>
      </defs>
      {shapes(primary(0.08))}
      {shapes(`url(#g${id})`)}
    </svg>
  );
}

function LoadedCard({ zh }: { zh: boolean }) {
  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 14 }}>
      <div style={{ height: 110, borderRadius: 14, background: Palette.sunset, display: "grid", placeItems: "center", color: "rgb(255 255 255 / 0.9)" }}>
        <Mountains2 size={52} />
      </div>
      <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
        <div style={{ width: 40, height: 40, borderRadius: "50%", background: Palette.ocean, display: "grid", placeItems: "center", color: "#fff", fontSize: 12, fontWeight: 700 }}>ML</div>
        <div style={{ display: "flex", flexDirection: "column", gap: 2 }}>
          <span style={{ fontSize: 15, lineHeight: "20px", fontWeight: 600 }}>{zh ? "极光工作室" : "Aurora Studio"}</span>
          <span style={{ fontSize: 12, lineHeight: "16px", color: Palette.secondaryLabel }}>{zh ? "2 分钟前" : "2 min ago"}</span>
        </div>
      </div>
      <div
        style={{
          fontSize: 12,
          lineHeight: "16px",
          color: Palette.secondaryLabel,
          display: "-webkit-box",
          WebkitLineClamp: 2,
          WebkitBoxOrient: "vertical",
          overflow: "hidden",
        }}
      >
        {zh ? "新的设计系统已发布，快来看看动效规范。" : "Our new design system is live — check out the motion specs."}
      </div>
    </div>
  );
}
