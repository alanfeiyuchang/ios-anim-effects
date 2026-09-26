/** loading.activity-petals · 花瓣指示器 (Loading+Spinners.swift) */
import { Cloud, Droplet, Flame, Heart, Leaf, MoonStar, Sparkles, Sun, TreeDeciduous, type LucideIcon } from "lucide-react";
import { Palette, black, glass, type DemoProps } from "../../kit";
import { frac, previewFps, usePhase } from "./shared";

const FILLS: [string, string][] = [
  [Palette.amber, Palette.coral],
  [Palette.sky, Palette.blue],
  [Palette.mint, Palette.sky],
  [Palette.pink, Palette.violet],
  [Palette.indigo, Palette.violet],
  [Palette.coral, Palette.pink],
  [Palette.mint, Palette.green],
  [Palette.amber, Palette.pink],
  [Palette.blue, Palette.indigo],
];
const SYMBOLS: LucideIcon[] = [Sun, Cloud, Leaf, Heart, MoonStar, Flame, TreeDeciduous, Sparkles, Droplet];

export default function ActivityPetals({ ctx }: DemoProps) {
  const petals = <Petals count={Math.max(ctx.i("count"), 1)} period={ctx.n("period")} stepped={ctx.b("stepped")} preview={ctx.isPreview} />;
  return (
    <div style={{ position: "absolute", inset: 0, display: "grid", placeItems: "center" }}>
      {ctx.b("hud") ? (
        <div style={{ position: "relative", display: "grid", placeItems: "center" }}>
          <PhotoGrid />
          <div
            style={{
              position: "absolute",
              width: 148,
              height: 148,
              borderRadius: 28,
              ...glass("thick"),
              boxShadow: `inset 0 0 0 1px ${Palette.stroke}, 0 12px 24px ${black(0.16)}`,
              display: "flex",
              flexDirection: "column",
              alignItems: "center",
              justifyContent: "center",
              gap: 16,
            }}
          >
            <div style={{ width: 76, height: 76, display: "grid", placeItems: "center" }}>
              <div style={{ transform: "scale(1.5)" }}>{petals}</div>
            </div>
            <span style={{ fontSize: 15, lineHeight: "20px", fontWeight: 600, color: Palette.secondaryLabel }}>{ctx.t("Loading", "正在加载")}</span>
          </div>
        </div>
      ) : (
        <div style={{ transform: "scale(2.4)" }}>{petals}</div>
      )}
    </div>
  );
}

function PhotoGrid() {
  return (
    <div style={{ display: "grid", gridTemplateColumns: "repeat(3, 84px)", gap: 6, borderRadius: 24, overflow: "hidden", opacity: 0.9 }}>
      {FILLS.map(([a, b], i) => {
        const Icon = SYMBOLS[i];
        return (
          <div key={i} style={{ width: 84, height: 84, borderRadius: 6, background: `linear-gradient(135deg, ${a}, ${b})`, display: "grid", placeItems: "center", color: "rgb(255 255 255 / 0.85)" }}>
            <Icon size={28} fill="currentColor" strokeWidth={2} />
          </div>
        );
      })}
    </div>
  );
}

function Petals({ count, period, stepped, preview }: { count: number; period: number; stepped: boolean; preview: boolean }) {
  const t = usePhase(1 / Math.max(period, 0.1), previewFps(preview));
  const raw = frac(t) * count;
  const head = stepped ? Math.floor(raw) : raw;
  return (
    <div style={{ position: "relative", width: 50, height: 50 }}>
      {Array.from({ length: count }, (_, index) => {
        let distance = head - index;
        if (distance < 0) distance += count;
        const fade = Math.max(0, 1 - distance / (count * 0.8));
        return (
          <div
            key={index}
            style={{ position: "absolute", left: 25 - 18.5, top: 25 - 18.5, width: 37, height: 37, transform: `rotate(${(index / count) * 360}deg)`, opacity: 0.18 + 0.82 * fade }}
          >
            <div style={{ position: "absolute", left: 18.5 - 1.75, top: 0, width: 3.5, height: 11, borderRadius: 2, background: Palette.label }} />
          </div>
        );
      })}
    </div>
  );
}
