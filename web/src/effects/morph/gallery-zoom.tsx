/** morph.gallery-zoom · 相册缩放转场 (Morph+GalleryZoom.swift) */
import { animate, useMotionValue } from "motion/react";
import { CloudSun, Flame, Leaf, MoonStar, Sparkles, TreePine, Waves } from "lucide-react";
import { useRef, useState } from "react";
import { DemoHint, Palette, anim, black, clamp, rubberBand, spring, useAutoplay, useHaptics, usePan, useTimeouts, white, type DemoProps } from "../../kit";
import { diag, mixN, mixRect, predicted, useMV, useSize, type Rect } from "./_shared";
import { Mountain2, SunHorizon, type SymbolComponent } from "./_symbols";

const symbols: [SymbolComponent, boolean][] = [
  [Mountain2, true],
  [SunHorizon, true],
  [Leaf, true],
  [Waves, false],
  [CloudSun, true],
  [Sparkles, true],
  [MoonStar, true],
  [TreePine, true],
  [Flame, true],
];
const photos = symbols.map(([Icon, fill], index) => ({
  id: index,
  Icon,
  fill,
  colors: [Palette.spectrum[index % 7], Palette.spectrum[(index + 2) % 7]],
}));
type Photo = (typeof photos)[number];

const PAGE_GAP = 16;
const CELL = 88;
const SPACING = 8;

export default function GalleryZoom({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const { after, clearAll } = useTimeouts();
  const root = useRef<HTMLDivElement>(null);
  const stage = useSize(root, { width: 340, height: ctx.isPreview ? 340 : 400 });
  const [selected, setSelected] = useState<number | null>(null);
  const [shown, setShown] = useState(4);
  const [autoIndex, setAutoIndex] = useState(4);
  const autoStage = useRef(0);
  const pending = useRef<number | null>(null);
  const axis = useRef<"paging" | "dismiss" | null>(null);
  const moved = useRef(false);
  const selectedRef = useRef<number | null>(null);
  selectedRef.current = selected;

  const openMV = useMotionValue(0);
  const dxMV = useMotionValue(0);
  const dyMV = useMotionValue(0);
  const pageMV = useMotionValue(0);
  const p = useMV(openMV);
  const dx = useMV(dxMV);
  const dy = useMV(dyMV);
  const pageDrag = useMV(pageMV);

  const response = ctx.n("response");
  const openSpring = spring(response, 0.86);
  const pageSpring = spring(response * 0.8, 1);
  const returnSpring = spring(response, ctx.n("damping"));
  const stride = stage.width + PAGE_GAP;

  const dragProgress = Math.min(Math.hypot(dx, dy) / 260, 1);
  const limit = ctx.n("tilt");
  const tilt = clamp((dx / 160) * limit, -limit, limit);

  const gridLeft = (stage.width - (CELL * 3 + SPACING * 2)) / 2;
  const gridTop = (stage.height - (CELL * 3 + SPACING * 2)) / 2;
  const tileRect = (id: number): Rect => ({ x: gridLeft + (id % 3) * (CELL + SPACING), y: gridTop + Math.floor(id / 3) * (CELL + SPACING), w: CELL, h: CELL });
  const stageRect: Rect = { x: 0, y: 0, w: stage.width, h: stage.height };

  const commitPendingPage = () => {
    const next = pending.current;
    if (next === null) return;
    pending.current = null;
    pageMV.stop();
    pageMV.set(0);
    setSelected(next);
    selectedRef.current = next;
    setShown(next);
  };

  const open = (id: number) => {
    haptics.tap();
    dxMV.set(0);
    dyMV.set(0);
    pageMV.set(0);
    setSelected(id);
    setShown(id);
    animate(openMV, 1, openSpring);
  };

  const close = () => {
    commitPendingPage();
    clearAll();
    setSelected(null);
    animate(openMV, 0, returnSpring);
    animate(dxMV, 0, returnSpring);
    animate(dyMV, 0, returnSpring);
    animate(pageMV, 0, returnSpring);
  };

  const settlePage = (step: number, silent: boolean) => {
    const index = selectedRef.current;
    if (step === 0 || index === null) {
      animate(pageMV, 0, pageSpring);
      return;
    }
    if (!silent) haptics.selection();
    pending.current = index + step;
    const token = index + step;
    animate(pageMV, -step * stride, pageSpring).then(() => {
      if (pending.current === token) commitPendingPage();
    });
  };

  const fling = () => {
    commitPendingPage();
    animate(dxMV, 46, anim.easeOut(0.28));
    animate(dyMV, 120, anim.easeOut(0.28));
    after(0.3, () => {
      if (selectedRef.current !== null) close();
    });
  };

  useAutoplay(
    ctx.isPreview,
    () => {
      const index = selectedRef.current;
      if (index === null) {
        open(photos[autoIndex % photos.length].id);
        setAutoIndex((i) => i + 2);
        autoStage.current = 0;
      } else if (autoStage.current === 0) {
        autoStage.current = 1;
        settlePage(index + 1 < photos.length ? 1 : -1, true);
      } else fling();
    },
    { every: 1.7 },
  );

  const pan = usePan(
    {
      onStart: () => {
        moved.current = true;
      },
      onChange: ({ translation: t }) => {
        if (selectedRef.current === null) return;
        if (axis.current === null) {
          if (Math.max(Math.abs(t.x), Math.abs(t.y)) < 2) return;
          // PageSafePan(directions: [.down, .left, .right]): an upward swipe never engages.
          if (-t.y > Math.abs(t.x)) return;
          clearAll();
          commitPendingPage();
          axis.current = Math.abs(t.x) > Math.abs(t.y) ? "paging" : "dismiss";
        }
        if (axis.current === "paging") {
          const index = selectedRef.current;
          const atStart = index === 0 && t.x > 0;
          const atEnd = index === photos.length - 1 && t.x < 0;
          pageMV.set(atStart || atEnd ? rubberBand(t.x, 60) : t.x);
        } else {
          dxMV.set(t.x);
          dyMV.set(t.y > 0 ? t.y : rubberBand(t.y, 16));
        }
      },
      onEnd: ({ translation, velocity }) => {
        const locked = axis.current;
        axis.current = null;
        if (!locked) return;
        if (locked === "paging") {
          const index = selectedRef.current;
          if (index === null) return;
          const m = pageMV.get();
          const pr = predicted(translation.x, velocity.x);
          let step = 0;
          if ((m < -stride * 0.3 || pr < -stride * 0.6) && index + 1 < photos.length) step = 1;
          if ((m > stride * 0.3 || pr > stride * 0.6) && index > 0) step = -1;
          settlePage(step, false);
        } else {
          const threshold = ctx.n("threshold");
          if (translation.y > threshold || predicted(translation.y, velocity.y) > threshold * 3) close();
          else {
            animate(dxMV, 0, spring(0.35, 0.8));
            animate(dyMV, 0, spring(0.35, 0.8));
          }
        }
      },
    },
    0,
  );

  const flying = selected !== null || p > 0.001;
  const fade = clamp(p);
  const rect = mixRect(tileRect(shown), stageRect, p);
  const radius = mixN(14, 4, fade);
  const neighbours = selected === null ? [] : [selected - 1, selected + 1].filter((i) => i >= 0 && i < photos.length);

  return (
    <div ref={root} style={{ position: "absolute", inset: 0 }}>
      {photos.map((photo) => {
        const r = tileRect(photo.id);
        return (
          <div
            key={photo.id}
            onClick={() => open(photo.id)}
            style={{
              position: "absolute",
              left: r.x,
              top: r.y,
              width: CELL,
              height: CELL,
              borderRadius: 14,
              overflow: "hidden",
              cursor: "pointer",
              opacity: flying && shown === photo.id ? 0 : 1,
            }}
          >
            <Art photo={photo} symbol={30} />
          </div>
        );
      })}
      {flying && (
        <>
          <div style={{ position: "absolute", inset: 0, background: "#000", opacity: 0.9 * (1 - dragProgress) * fade, pointerEvents: "none" }} />
          <div
            {...pan}
            onClick={() => {
              if (moved.current) {
                moved.current = false;
                return;
              }
              if (selectedRef.current !== null) close();
            }}
            onPointerDown={(e) => {
              moved.current = false;
              pan.onPointerDown(e);
            }}
            onPointerUp={(e) => {
              pan.onPointerUp(e);
              window.setTimeout(() => (moved.current = false), 0);
            }}
            style={{ ...pan.style, position: "absolute", inset: 0, pointerEvents: selected !== null ? "auto" : "none" }}
          >
            {neighbours.map((other) => (
              <div
                key={other}
                style={{
                  position: "absolute",
                  inset: 0,
                  borderRadius: 4,
                  overflow: "hidden",
                  transform: `translateX(${(other - (selected ?? 0)) * stride + pageDrag}px)`,
                  opacity: (1 - dragProgress) * fade,
                }}
              >
                <Art photo={photos[other]} symbol={84} />
              </div>
            ))}
            <div
              style={{
                position: "absolute",
                left: rect.x,
                top: rect.y,
                width: rect.w,
                height: rect.h,
                borderRadius: radius,
                overflow: "hidden",
                transform: `translate(${dx + pageDrag}px, ${dy}px) rotate(${tilt}deg)`,
              }}
            >
              <div style={{ position: "absolute", inset: 0, opacity: 1 - fade }}>
                <Art photo={photos[shown]} symbol={30} />
              </div>
              <div style={{ position: "absolute", inset: 0, opacity: fade }}>
                <Art photo={photos[shown]} symbol={84} />
              </div>
            </div>
          </div>
        </>
      )}
      <div
        className={selected !== null ? "ml-dark" : undefined}
        style={{ position: "absolute", left: 0, right: 0, bottom: 12, pointerEvents: "none", opacity: dragProgress > 0 ? 0 : 1 }}
      >
        <DemoHint
          ctx={ctx}
          en={selected === null ? "Tap a photo" : "Swipe to browse, pull down to close"}
          zh={selected === null ? "点击一张照片" : "左右滑动翻看，下拉关闭"}
        />
      </div>
    </div>
  );
}

function Art({ photo, symbol }: { photo: Photo; symbol: number }) {
  const { Icon } = photo;
  return (
    <div style={{ position: "absolute", inset: 0, background: diag(...photo.colors), display: "grid", placeItems: "center", color: white(0.9) }}>
      <Icon
        size={symbol}
        strokeWidth={photo.fill ? 1.2 : 2.2}
        fill={photo.fill ? "currentColor" : "none"}
        style={{ filter: `drop-shadow(0 4px 4px ${black(0.15)})` }}
      />
    </div>
  );
}
