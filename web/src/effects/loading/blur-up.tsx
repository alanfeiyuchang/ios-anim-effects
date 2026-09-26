/** loading.blur-up · 渐进式图片加载 (Loading+Stories.swift) */
import { motion } from "motion/react";
import { Leaf, type LucideIcon } from "lucide-react";
import { useEffect, useRef, useState } from "react";
import { DemoHint, Palette, anim, useHaptics, type DemoProps } from "../../kit";
import { Mountains2, SunHorizon } from "./shared";

interface Photo {
  icon: LucideIcon | "mountains" | "sun";
  colors: string[];
}

const PHOTOS: Photo[] = [
  { icon: "sun", colors: [Palette.amber, Palette.coral, Palette.pink] },
  { icon: "mountains", colors: [Palette.sky, Palette.blue] },
  { icon: Leaf, colors: [Palette.mint, Palette.green] },
];

const shuffled = (list: number[]) => {
  const a = [...list];
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
};

export default function BlurUp({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [loadedCount, setLoadedCount] = useState(0);
  const [order, setOrder] = useState([1, 0, 2]);
  const [run, setRun] = useState(0);
  const [fade, setFade] = useState(anim.easeOut(0.3));
  const latest = useRef(ctx);
  latest.current = ctx;

  useEffect(() => {
    const c = latest.current;
    const live = !c.isPreview && run > 0;
    const timers: number[] = [];
    setFade(anim.easeOut(0.3));
    setLoadedCount(0);
    setOrder(shuffled([0, 1, 2]));
    let at = 0.7;
    for (let count = 1; count <= 3; count++) {
      at += latest.current.n("stagger") * (0.7 + Math.random() * 0.6);
      timers.push(
        window.setTimeout(() => {
          setFade(anim.smoothD(latest.current.n("fade")));
          setLoadedCount(count);
          if (count === 3 && live) haptics.tap("soft");
        }, at * 1000),
      );
    }
    if (c.isPreview) timers.push(window.setTimeout(() => setRun((r) => r + 1), (at + 2) * 1000));
    return () => timers.forEach(clearTimeout);
  }, [run, haptics]);

  const isLoaded = (i: number) => order.indexOf(i) < loadedCount;
  const tile = (i: number, w: number, h: number) => <Tile photo={PHOTOS[i]} loaded={isLoaded(i)} blur={ctx.n("blur")} width={w} height={h} transition={fade} />;

  return (
    <div
      onClick={() => setRun((r) => r + 1)}
      style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 16, cursor: "pointer" }}
    >
      <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 10 }}>
        {tile(0, 274, 128)}
        <div style={{ display: "flex", gap: 10 }}>
          {tile(1, 132, 132)}
          {tile(2, 132, 132)}
        </div>
      </div>
      <DemoHint ctx={ctx} en="Tap to reload" zh="点击重新加载" />
    </div>
  );
}

function Art({ photo }: { photo: Photo }) {
  const Icon = photo.icon;
  return (
    <div style={{ position: "absolute", inset: 0 }}>
      <div style={{ position: "absolute", inset: 0, background: `linear-gradient(135deg, ${photo.colors.join(", ")})` }} />
      <div style={{ position: "absolute", inset: 0, background: "radial-gradient(140px circle at 30% 25%, rgb(255 255 255 / 0.4), transparent)" }} />
      <div style={{ position: "absolute", inset: 0, display: "grid", placeItems: "center", color: "rgb(255 255 255 / 0.92)", filter: "drop-shadow(0 4px 8px rgb(0 0 0 / 0.15))" }}>
        {Icon === "mountains" ? <Mountains2 size={60} /> : Icon === "sun" ? <SunHorizon size={58} /> : <Icon size={56} fill="currentColor" strokeWidth={2} />}
      </div>
    </div>
  );
}

function Tile({ photo, loaded, blur, width, height, transition }: { photo: Photo; loaded: boolean; blur: number; width: number; height: number; transition: ReturnType<typeof anim.easeOut> }) {
  return (
    <div style={{ position: "relative", width, height, borderRadius: 18, overflow: "hidden", boxShadow: "0 5px 10px rgb(0 0 0 / 0.1)", isolation: "isolate" }}>
      <motion.div initial={false} animate={{ scale: loaded ? 1 : 1.12 }} transition={transition} style={{ position: "absolute", inset: 0 }}>
        <Art photo={photo} />
      </motion.div>
      <motion.div initial={false} animate={{ scale: loaded ? 1 : 1.12, opacity: loaded ? 0 : 1 }} transition={transition} style={{ position: "absolute", inset: 0 }}>
        <div style={{ position: "absolute", inset: 0, filter: "saturate(0.5)" }}>
          <div style={{ position: "absolute", inset: 0, background: `linear-gradient(135deg, ${photo.colors.join(", ")})` }} />
          <div style={{ position: "absolute", inset: 0, filter: `blur(${blur}px)` }}>
            <Art photo={photo} />
          </div>
          <motion.div
            animate={{ opacity: [0, 0.16] }}
            transition={{ duration: 0.9, ease: [0.42, 0, 0.58, 1], repeat: Infinity, repeatType: "reverse" }}
            style={{ position: "absolute", inset: 0, background: "#fff" }}
          />
        </div>
      </motion.div>
    </div>
  );
}
