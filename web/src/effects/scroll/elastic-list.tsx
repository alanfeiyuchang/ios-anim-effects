/** scroll.elastic-list · 弹性消息列表 (Scroll+ElasticList.swift) */
import { motion } from "motion/react";
import { useRef, useState } from "react";
import { Palette, anim, clamp, spring, useAutoplay, type DemoProps } from "../../kit";
import { ScrollVelocityTracker, useScroller } from "./_kit";

const MESSAGES: [string, string][] = [
  ["Are we still on for tonight?", "今晚还照常吗？"],
  ["Yes! 7:30 at the ramen place", "对！7:30 拉面店见"],
  ["Perfect, I'll book a table", "好，我去订位"],
  ["Bring the camera 📷", "记得带相机 📷"],
  ["Already packed it", "早就装好了"],
  ["Leaving the office now", "我刚下班出发"],
  ["Traffic is wild", "路上好堵"],
  ["No rush, I'm early", "不急，我到早了"],
  ["Order me the spicy one", "帮我点辣的那款"],
  ["Done 🍜", "点好了 🍜"],
  ["Parking now", "在停车"],
  ["See you in 2", "两分钟后见"],
  ["Window seat!", "靠窗的位子！"],
  ["Best spot 🙌", "最佳位置 🙌"],
  ["Walking in", "我进来了"],
  ["I see you 👋", "看到你啦 👋"],
  ["Let's eat", "开吃"],
  ["Photo time first", "先拍照"],
];

const ROW = 44;
const GAP = 10;
const TOP = 16;

export default function ElasticList({ ctx }: DemoProps) {
  const [velocity, setVelocity] = useState(0);
  const tracker = useRef(new ScrollVelocityTracker());
  const settleTimer = useRef(0);
  const down = useRef(false);
  const settle = () => {
    tracker.current.reset();
    setVelocity(0);
  };
  const sc = useScroller({
    axis: "y",
    onScroll: (o) => {
      setVelocity(tracker.current.sample(o, 2400));
      // A finger held still sends nothing: 70 ms without a change counts as stopped.
      window.clearTimeout(settleTimer.current);
      settleTimer.current = window.setTimeout(settle, 70);
    },
    onPhase: (p) => {
      if (p === "idle") {
        window.clearTimeout(settleTimer.current);
        settle();
      }
    },
  });

  useAutoplay(
    ctx.isPreview,
    () => {
      down.current = !down.current;
      sc.scrollTo(down.current ? "end" : 0, anim.easeInOut(0.9));
    },
    { every: 1.6 },
  );

  const viewport = Math.max(sc.size.height, 1);
  const elasticity = ctx.n("elasticity");
  const damping = ctx.n("damping");

  return (
    <div {...sc.props} style={{ ...sc.props.style, position: "absolute", inset: 0 }}>
      <div ref={sc.contentRef} style={{ padding: `${TOP}px 16px`, display: "flex", flexDirection: "column", gap: GAP }}>
        {MESSAGES.map((m, i) => {
          const rowY = TOP + i * (ROW + GAP) - sc.offset;
          const screen = clamp(rowY / viewport);
          // Rows far from the leading edge of the motion lag the most.
          const far = velocity >= 0 ? screen : 1 - screen;
          const lag = clamp(velocity * 0.02 * far * elasticity, -40, 40);
          const outgoing = i % 2 === 1;
          return (
            <motion.div
              key={i}
              animate={{ y: lag }}
              transition={spring(0.2 + 0.25 * far, damping)}
              style={{ height: ROW, flexShrink: 0, display: "flex", alignItems: "center", justifyContent: outgoing ? "flex-end" : "flex-start" }}
            >
              <div
                style={{
                  height: 36,
                  maxWidth: 308 - 60,
                  padding: "0 14px",
                  borderRadius: 18,
                  display: "flex",
                  alignItems: "center",
                  fontSize: 15,
                  whiteSpace: "nowrap",
                  overflow: "hidden",
                  textOverflow: "ellipsis",
                  color: outgoing ? "#fff" : Palette.label,
                  background: outgoing ? Palette.ocean : Palette.elevated,
                }}
              >
                {ctx.lang === "zh" ? m[1] : m[0]}
              </div>
            </motion.div>
          );
        })}
      </div>
    </div>
  );
}
