/** text.odometer · 里程表 (Text+Odometer.swift) */
import { animate, useMotionValue, useMotionValueEvent } from "motion/react";
import { useEffect, useRef, useState } from "react";
import { DemoHint, Palette, black, delayed, fonts, spring, useAutoplay, useHaptics, white, type DemoProps } from "../../kit";
import { randInt } from "./_text-kit";

const COLUMNS = 6;
const CELL_H = 58;

/** How many steps drum `column` has turned for `reading` (unbounded; its digit is `roll % 10`). */
const rollAt = (column: number, reading: number) => Math.floor(reading / 10 ** (COLUMNS - 1 - column));

/** Smallest damping whose overshoot stays under 0.4 digit over `travel` digits. */
function requiredDamping(travel: number) {
  if (travel <= 1) return 0;
  const logOS = -Math.log(0.4 / travel);
  return Math.min(logOS / Math.sqrt(Math.PI * Math.PI + logOS * logOS), 1);
}

export default function Odometer({ ctx }: DemoProps) {
  const haptics = useHaptics();
  const [reading, setReading] = useState({ value: 42_318, previous: 42_318 });

  const drive = () => {
    setReading((r) => ({ previous: r.value, value: r.value + randInt(4, 96) }));
    haptics.tap("light");
  };
  useAutoplay(ctx.isPreview, drive, { every: 1.7 });

  return (
    <div onClick={drive} style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 16, cursor: "pointer" }}>
      <div style={{ width: 290, display: "flex", fontSize: 15, lineHeight: "20px", fontWeight: 600 }}>
        <span style={{ color: Palette.secondaryLabel }}>{ctx.t("Total distance", "总里程")}</span>
        <span style={{ flex: 1 }} />
        <span style={{ color: Palette.tertiaryLabel }}>{ctx.t("km", "公里")}</span>
      </div>
      <div
        style={{
          display: "flex",
          gap: 6,
          padding: 10,
          borderRadius: 18,
          background: "rgb(10 10 10)",
          boxShadow: `inset 0 0 0 1px ${white(0.08)}, 0 10px 18px ${black(0.25)}`,
        }}
      >
        {Array.from({ length: COLUMNS }, (_, column) => {
          const last = column === COLUMNS - 1;
          const roll = rollAt(column, reading.value);
          const travel = roll - rollAt(column, reading.previous);
          const damping = Math.max(ctx.n("damping"), requiredDamping(travel));
          const transition = delayed(spring(ctx.n("response"), damping), (COLUMNS - 1 - column) * ctx.n("stagger"));
          return (
            <div key={column} style={{ display: "flex", gap: 6 }}>
              {last && (
                <div style={{ height: CELL_H, display: "flex", alignItems: "flex-end", paddingBottom: 12 }}>
                  <span style={{ width: 6, height: 6, borderRadius: "50%", background: Palette.amber }} />
                </div>
              )}
              <Drum roll={roll} transition={transition} accent={last} />
            </div>
          );
        })}
      </div>
      <DemoHint ctx={ctx} en="Tap to drive" zh="点击行驶" />
    </div>
  );
}

function Drum({ roll, transition, accent }: { roll: number; transition: ReturnType<typeof spring>; accent: boolean }) {
  const mv = useMotionValue(roll);
  const [value, setValue] = useState(roll);
  useMotionValueEvent(mv, "change", setValue);
  const first = useRef(true);
  useEffect(() => {
    if (first.current) {
      first.current = false;
      return;
    }
    const controls = animate(mv, roll, transition);
    return () => controls.stop();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [roll]);

  const base = Math.floor(value);
  const fraction = value - base;
  const digit = ((base % 10) + 10) % 10;
  const face = (n: number) => (
    <div
      style={{
        width: 40,
        height: CELL_H,
        display: "grid",
        placeItems: "center",
        fontFamily: fonts.rounded,
        fontSize: 36,
        fontWeight: 600,
        fontVariantNumeric: "tabular-nums",
        color: accent ? Palette.amber : "rgb(242 242 242)",
      }}
    >
      {n}
    </div>
  );
  return (
    <div style={{ position: "relative", width: 40, height: CELL_H, borderRadius: 8, overflow: "hidden", background: "linear-gradient(rgb(51 51 51), rgb(31 31 31))" }}>
      <div style={{ transform: `translateY(${-fraction * CELL_H}px)` }}>
        {face(digit)}
        {face((digit + 1) % 10)}
      </div>
      <div
        style={{
          position: "absolute",
          inset: 0,
          pointerEvents: "none",
          background: `linear-gradient(${black(0.7)} 0%, transparent 30%, transparent 70%, ${black(0.7)} 100%)`,
        }}
      />
    </div>
  );
}
