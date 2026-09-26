/** text.marquee · 跑马灯 (Text+Marquee.swift) */
import { Sparkle } from "lucide-react";
import { useEffect, useRef, type ReactNode } from "react";
import { DemoHint, Palette, alpha, fonts, useClock, useHaptics, usePan, type DemoProps } from "../../kit";
import { useSize } from "./_text-kit";

const QUOTES = [
  { symbol: "AAPL", price: "232.18", change: 1.24 },
  { symbol: "NVDA", price: "141.02", change: 3.87 },
  { symbol: "TSLA", price: "248.50", change: -2.11 },
  { symbol: "MSFT", price: "438.66", change: 0.58 },
  { symbol: "AMZN", price: "201.73", change: -0.42 },
  { symbol: "META", price: "589.34", change: 2.05 },
];
const WORDS = { zh: ["动效", "质感", "节奏", "细节", "愉悦"], en: ["Motion", "Craft", "Rhythm", "Detail", "Delight"] };

export default function Marquee({ ctx }: DemoProps) {
  const speed = ctx.n("speed");
  return (
    <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "stretch", justifyContent: "center", gap: 22 }}>
      <MarqueeRow speed={speed} reversed={false} preview={ctx.isPreview}>
        {QUOTES.map((q) => (
          <QuoteChip key={q.symbol} {...q} />
        ))}
      </MarqueeRow>
      <MarqueeRow speed={speed * 0.8} reversed={ctx.b("opposite")} preview={ctx.isPreview}>
        {WORDS[ctx.lang].map((w) => (
          <HeadlineWord key={w} word={w} />
        ))}
      </MarqueeRow>
      <DemoHint ctx={ctx} en="Drag a belt to scrub or fling it" zh="拖动传送带来回拨动或甩出" />
    </div>
  );
}

const COAST = 0.35;
const secs = () => performance.now() / 1000;

function MarqueeRow({ speed, reversed, preview, children }: { speed: number; reversed: boolean; preview: boolean; children: ReactNode }) {
  const haptics = useHaptics();
  useClock(true, preview ? 30 : undefined);
  const [stripRef, { w: stripWidth }] = useSize<HTMLDivElement>();
  const s = useRef({ manual: 0, liveX: 0, heldAt: null as number | null, pausedTime: 0, flingVelocity: 0, flingStart: -Infinity, ownShift: 0 });

  const beltClock = (at: number) => (s.current.heldAt ?? at) - s.current.pausedTime;
  const flingOffset = (at: number) => {
    const t = Math.max(at - s.current.flingStart, 0);
    return s.current.flingVelocity * COAST * (1 - Math.exp(-t / COAST));
  };

  const lastSpeed = useRef(speed);
  useEffect(() => {
    s.current.ownShift += beltClock(secs()) * (lastSpeed.current - speed);
    lastSpeed.current = speed;
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [speed]);

  const grabX = useRef(0);
  const pan = usePan(
    {
      onStart: ({ translation }) => {
        const now = secs();
        grabX.current = translation.x;
        s.current.liveX = 0;
        s.current.manual += flingOffset(now);
        s.current.flingVelocity = 0;
        s.current.heldAt = now;
        haptics.selection();
      },
      onChange: ({ translation }) => {
        s.current.liveX = translation.x - grabX.current;
      },
      onEnd: ({ velocity }) => {
        const start = s.current.heldAt;
        if (start === null) return;
        const now = secs();
        s.current.manual += s.current.liveX;
        s.current.liveX = 0;
        grabX.current = 0;
        s.current.pausedTime += now - start;
        s.current.heldAt = null;
        s.current.flingVelocity = Math.min(Math.max(velocity.x, -3000), 3000);
        s.current.flingStart = now;
      },
    },
    8,
  );

  const now = secs();
  const width = Math.max(stripWidth, 1);
  const own = (beltClock(now) * speed + s.current.ownShift) % width;
  const hand = (s.current.manual + s.current.liveX + flingOffset(now)) % width;
  const raw = (reversed ? own : -own) + hand;
  const wrapped = raw % width;
  const offset = wrapped > 0 ? wrapped - width : wrapped;

  const fade = "linear-gradient(to right, transparent 0%, #000 12%, #000 88%, transparent 100%)";
  return (
    <div {...pan} style={{ ...pan.style, position: "relative", overflow: "hidden", WebkitMaskImage: fade, maskImage: fade, cursor: "grab" }}>
      <div style={{ display: "flex", width: "max-content", transform: `translateX(${offset}px)` }}>
        <div ref={stripRef} style={{ display: "flex", flexShrink: 0 }}>
          {children}
        </div>
        <div style={{ display: "flex", flexShrink: 0 }}>{children}</div>
        <div style={{ display: "flex", flexShrink: 0 }}>{children}</div>
      </div>
    </div>
  );
}

function QuoteChip({ symbol, price, change }: { symbol: string; price: string; change: number }) {
  const up = change >= 0;
  const tone = up ? Palette.green : Palette.red;
  return (
    <div style={{ padding: "0 5px", flexShrink: 0 }}>
      <div
        style={{
          display: "flex",
          alignItems: "center",
          gap: 8,
          padding: "8px 10px",
          borderRadius: 12,
          background: Palette.elevated,
          boxShadow: `inset 0 0 0 1px ${Palette.stroke}`,
          whiteSpace: "nowrap",
        }}
      >
        <span style={{ fontSize: 15, lineHeight: "20px", fontWeight: 700 }}>{symbol}</span>
        <span style={{ fontSize: 15, lineHeight: "20px", fontVariantNumeric: "tabular-nums", color: Palette.secondaryLabel }}>{price}</span>
        <span
          style={{
            fontSize: 12,
            lineHeight: "16px",
            fontWeight: 600,
            fontVariantNumeric: "tabular-nums",
            color: tone,
            padding: "3px 7px",
            borderRadius: 999,
            background: alpha(tone, 0.14),
          }}
        >
          {(up ? "▲ " : "▼ ") + Math.abs(change).toFixed(2) + "%"}
        </span>
      </div>
    </div>
  );
}

function HeadlineWord({ word }: { word: string }) {
  return (
    <div style={{ display: "flex", alignItems: "center", gap: 16, paddingRight: 16, flexShrink: 0, whiteSpace: "nowrap" }}>
      <span style={{ fontFamily: fonts.rounded, fontSize: 44, fontWeight: 800, lineHeight: "53px", color: Palette.label }}>{word}</span>
      <svg width={26} height={26} viewBox="0 0 24 24" style={{ overflow: "visible" }}>
        <defs>
          <linearGradient id="marquee-sunset" x1="0" y1="0" x2="1" y2="1">
            <stop offset="0" stopColor={Palette.amber} />
            <stop offset="0.5" stopColor={Palette.coral} />
            <stop offset="1" stopColor={Palette.pink} />
          </linearGradient>
        </defs>
        <Sparkle size={24} fill="url(#marquee-sunset)" stroke="url(#marquee-sunset)" strokeWidth={2} strokeLinejoin="round" />
      </svg>
    </div>
  );
}
