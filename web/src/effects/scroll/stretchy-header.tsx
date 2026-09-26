/** scroll.stretchy-header · 弹性视差头图 (Scroll+StretchyHeader.swift) */
import { useEffect, useRef } from "react";
import { Palette, anim, black, spring, useAutoplay, type DemoProps } from "../../kit";
import { ScrollKitRow, Sym, useAnimated, useScroller, swiftBlur } from "./_kit";

const HEADER = 190;

export default function StretchyHeader({ ctx }: DemoProps) {
  const sc = useScroller({ axis: "y" });
  // Simulated overscroll used only by the auto-playing preview.
  const [pull, pullTo] = useAnimated(0);
  const step = useRef(0);

  useAutoplay(
    ctx.isPreview,
    () => {
      switch (step.current % 4) {
        case 0:
          pullTo(80, spring(0.55, 0.85));
          break;
        case 1:
          pullTo(0, spring(0.55, 0.62));
          break;
        case 2:
          sc.scrollTo(170, anim.smoothD(1.2));
          break;
        default:
          sc.scrollTo(0, anim.smoothD(1.2));
      }
      step.current += 1;
    },
    { every: 1.5 },
  );

  const parallax = ctx.n("parallax");
  const minY = pull - sc.offset;
  const stretch = Math.max(minY, 0);
  const scrolled = Math.max(-minY, 0);
  const blur = ctx.b("blur") ? Math.min(scrolled / 14, 8) : 0;

  return (
    <div {...sc.props} style={{ ...sc.props.style, position: "absolute", inset: 0 }}>
      <div ref={sc.contentRef} style={{ paddingTop: pull, display: "flex", flexDirection: "column" }}>
        <div
          style={{
            position: "relative",
            height: HEADER,
            flexShrink: 0,
            zIndex: 0,
            transformOrigin: "50% 100%",
            transform: `translateY(${scrolled * parallax}px) scale(${1 + stretch / HEADER})`,
            filter: swiftBlur(blur),
          }}
        >
          <Artwork zh={ctx.lang === "zh"} fps={30} />
        </div>
        <div
          style={{
            position: "relative",
            zIndex: 1,
            marginTop: -24,
            padding: "10px 16px 24px",
            background: Palette.surface,
            borderRadius: "24px 24px 0 0",
            display: "flex",
            flexDirection: "column",
            gap: 10,
          }}
        >
          <div style={{ alignSelf: "center", width: 36, height: 5, borderRadius: 3, background: Palette.labelAlpha(0.15), marginBottom: 4 }} />
          {Array.from({ length: 10 }, (_, i) => (
            <ScrollKitRow key={i} index={i + 3} lang={ctx.lang} />
          ))}
        </div>
      </div>
    </div>
  );
}

/** MeshGradient 3×3 whose centre point drifts, rendered into a small canvas and scaled up smoothly. */
function Artwork({ zh, fps }: { zh: boolean; fps: number }) {
  return (
    <div style={{ position: "absolute", inset: 0, overflow: "hidden" }}>
      <MeshCanvas fps={fps} />
      <div style={{ position: "absolute", top: 24, right: 24, color: "rgb(255 255 255 / 0.18)", transform: "rotate(-18deg)" }}>
        <Sym name="leaf.fill" size={64} weight={600} />
      </div>
      <div
        style={{
          position: "absolute",
          left: 20,
          bottom: 40,
          display: "flex",
          flexDirection: "column",
          gap: 4,
          color: "#fff",
          textShadow: `0 3px 8px ${black(0.2)}`,
        }}
      >
        <div style={{ fontSize: 22, lineHeight: "28px", fontWeight: 700 }}>{zh ? "秋日京都" : "Kyoto in Autumn"}</div>
        <div style={{ fontSize: 13, lineHeight: "18px", fontWeight: 600, opacity: 0.85 }}>{zh ? "12 个地点 · 4 天" : "12 places · 4 days"}</div>
      </div>
    </div>
  );
}

const MESH_COLORS = [
  Palette.indigo, Palette.violet, Palette.pink,
  Palette.sky, Palette.violet, Palette.coral,
  Palette.mint, Palette.blue, Palette.amber,
].map((c) => [parseInt(c.slice(1, 3), 16), parseInt(c.slice(3, 5), 16), parseInt(c.slice(5, 7), 16)]);

const W = 68;
const H = 38;

function MeshCanvas({ fps }: { fps: number }) {
  const canvas = useRef<HTMLCanvasElement>(null);
  useEffect(() => {
    const c = canvas.current;
    const g = c?.getContext("2d");
    if (!c || !g) return;
    const image = g.createImageData(W, H);
    let raf = 0;
    let last = 0;
    const draw = (now: number) => {
      raf = requestAnimationFrame(draw);
      if (now - last < 1000 / fps - 1) return;
      last = now;
      const t = Date.now() / 1000;
      const cx = 0.5 + 0.12 * Math.sin(t * 0.7);
      const cy = 0.45 + 0.1 * Math.cos(t * 0.9);
      renderMesh(image.data, cx, cy);
      g.putImageData(image, 0, 0);
    };
    raf = requestAnimationFrame(draw);
    return () => cancelAnimationFrame(raf);
  }, [fps]);
  return <canvas ref={canvas} width={W} height={H} style={{ position: "absolute", inset: 0, width: "100%", height: "100%" }} />;
}

const smooth = (x: number) => x * x * (3 - 2 * x);

/** Inverse bilinear mapping (Quilez): (u, v) of point p inside quad a-b-c-d (a=00, b=10, c=11, d=01). */
function invBilinear(px: number, py: number, a: number[], b: number[], c: number[], d: number[]): [number, number] {
  const ex = b[0] - a[0], ey = b[1] - a[1];
  const fx = d[0] - a[0], fy = d[1] - a[1];
  const gx = a[0] - b[0] + c[0] - d[0], gy = a[1] - b[1] + c[1] - d[1];
  const hx = px - a[0], hy = py - a[1];
  const cross = (x1: number, y1: number, x2: number, y2: number) => x1 * y2 - y1 * x2;
  const k2 = cross(gx, gy, fx, fy);
  const k1 = cross(ex, ey, fx, fy) + cross(hx, hy, gx, gy);
  const k0 = cross(hx, hy, ex, ey);
  let v: number;
  if (Math.abs(k2) < 1e-6) v = -k0 / k1;
  else {
    const w = Math.sqrt(Math.max(k1 * k1 - 4 * k0 * k2, 0));
    v = (-k1 - w) / (2 * k2);
    if (v < -0.01 || v > 1.01) v = (-k1 + w) / (2 * k2);
  }
  const denx = ex + gx * v;
  const deny = ey + gy * v;
  const u = Math.abs(denx) > Math.abs(deny) ? (hx - fx * v) / denx : (hy - fy * v) / deny;
  return [Math.min(Math.max(u, 0), 1), Math.min(Math.max(v, 0), 1)];
}

function renderMesh(out: Uint8ClampedArray, cx: number, cy: number) {
  const P = [
    [0, 0], [0.5, 0], [1, 0],
    [0, 0.5], [cx, cy], [1, 0.5],
    [0, 1], [0.5, 1], [1, 1],
  ];
  for (let y = 0; y < H; y++) {
    const ny = (y + 0.5) / H;
    for (let x = 0; x < W; x++) {
      const nx = (x + 0.5) / W;
      // Pick the patch: which side of the centre lines the pixel is on.
      const col = nx < (ny < cy ? mixX(0.5, cx, ny / cy) : mixX(cx, 0.5, (ny - cy) / (1 - cy))) ? 0 : 1;
      const row = ny < (nx < cx ? mixX(0.5, cy, nx / cx) : mixX(cy, 0.5, (nx - cx) / (1 - cx))) ? 0 : 1;
      const i00 = row * 3 + col;
      const [u, v] = invBilinear(nx, ny, P[i00], P[i00 + 1], P[i00 + 4], P[i00 + 3]);
      const su = smooth(u);
      const sv = smooth(v);
      const c00 = MESH_COLORS[i00], c10 = MESH_COLORS[i00 + 1], c01 = MESH_COLORS[i00 + 3], c11 = MESH_COLORS[i00 + 4];
      const o = (y * W + x) * 4;
      for (let k = 0; k < 3; k++) {
        const top = c00[k] + (c10[k] - c00[k]) * su;
        const bottom = c01[k] + (c11[k] - c01[k]) * su;
        out[o + k] = top + (bottom - top) * sv;
      }
      out[o + 3] = 255;
    }
  }
}

const mixX = (a: number, b: number, t: number) => a + (b - a) * t;
