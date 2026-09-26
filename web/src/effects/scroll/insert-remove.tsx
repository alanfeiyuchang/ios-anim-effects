/** scroll.insert-remove · 列表增删动画 (Scroll+InsertRemove.swift) */
import { AnimatePresence, motion, type TargetAndTransition } from "motion/react";
import { useRef, useState } from "react";
import { DemoHint, NumericText, Palette, alpha, spring, useAutoplay, useHaptics, type DemoProps } from "../../kit";
import { ROW_HEIGHT, ScrollKitRow, Sym, useScroller } from "./_kit";

type Motion = { initial: TargetAndTransition; exit: TargetAndTransition };

function transitionFor(style: number): Motion {
  switch (style) {
    case 1:
      return { initial: { scale: 0.7, opacity: 0 }, exit: { scale: 0.7, opacity: 0 } };
    case 2:
      return {
        initial: { filter: "blur(7.5px)", opacity: 0, scale: 0.92 },
        exit: { filter: "blur(7.5px)", opacity: 0, scale: 0.92 },
      };
    default:
      // .move(edge: .top) + opacity in, .move(edge: .trailing) + opacity out.
      return { initial: { y: -(ROW_HEIGHT + 16), opacity: 0 }, exit: { x: 320, opacity: 0 } };
  }
}

export default function InsertRemove({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [items, setItems] = useState([3, 2, 1, 0]);
  const nextID = useRef(4);
  const tick = useRef(0);
  const sc = useScroller({ axis: "y" });
  const t = spring(ctx.n("response"), ctx.n("damping"));
  const tr = transitionFor(ctx.i("style"));

  const insert = () => {
    haptics.tap("soft");
    const id = nextID.current++;
    setItems((list) => [id, ...list]);
  };
  const remove = (id: number) => {
    haptics.tap("light");
    setItems((list) => list.filter((x) => x !== id));
  };
  useAutoplay(
    ctx.isPreview,
    () => {
      tick.current += 1;
      if (items.length >= 5 || (tick.current % 3 === 0 && items.length > 2)) remove(items[Math.min(1, items.length - 1)]);
      else insert();
    },
    { every: 1.2 },
  );

  return (
    <div style={{ position: "absolute", inset: 0, paddingTop: 16, display: "flex", flexDirection: "column", gap: 12 }}>
      <div style={{ display: "flex", alignItems: "center", gap: 8, padding: "0 20px", flexShrink: 0 }}>
        <span style={{ fontSize: 20, lineHeight: "25px", fontWeight: 700 }}>{ctx.t("Inbox", "收件箱")}</span>
        <NumericText value={items.length} style={{ fontSize: 15, lineHeight: "20px", fontWeight: 600, color: Palette.secondaryLabel }} />
        <span style={{ flex: 1 }} />
        <button
          type="button"
          onClick={insert}
          style={{
            width: 36,
            height: 36,
            borderRadius: "50%",
            background: Palette.primary,
            color: "#fff",
            display: "grid",
            placeItems: "center",
            boxShadow: `0 4px 8px ${alpha(Palette.indigo, 0.35)}`,
          }}
        >
          <Sym name="plus" size={16} weight={700} />
        </button>
      </div>
      <div {...sc.props} style={{ ...sc.props.style, flex: 1, minHeight: 0 }}>
        <div ref={sc.contentRef} style={{ padding: "6px 20px", display: "flex", flexDirection: "column", gap: 10 }}>
          <AnimatePresence initial={false} mode="popLayout">
            {items.map((id) => (
              <motion.div
                key={id}
                layout
                initial={tr.initial}
                animate={{ x: 0, y: 0, scale: 1, opacity: 1, filter: "blur(0px)" }}
                exit={tr.exit}
                transition={t}
                style={{ flexShrink: 0 }}
              >
                <ScrollKitRow index={id} lang={ctx.lang} showsMeta={false}>
                  <button
                    type="button"
                    onClick={() => remove(id)}
                    style={{
                      width: 28,
                      height: 28,
                      borderRadius: "50%",
                      background: Palette.labelAlpha(0.06),
                      color: Palette.secondaryLabel,
                      display: "grid",
                      placeItems: "center",
                      flexShrink: 0,
                    }}
                  >
                    <Sym name="xmark" size={11} weight={700} />
                  </button>
                </ScrollKitRow>
              </motion.div>
            ))}
          </AnimatePresence>
        </div>
      </div>
      <DemoHint ctx={ctx} en="Tap + to add, × to remove" zh="点 + 添加，点 × 删除" style={{ paddingBottom: 10, flexShrink: 0 }} />
    </div>
  );
}
