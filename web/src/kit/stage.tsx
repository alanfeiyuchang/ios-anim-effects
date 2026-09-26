/**
 * `DemoStage`: mounts one ported demo on the app's stage. The demo is laid out on a canvas
 * 340 px wide (Swift's authoring canvas) and 340 (preview) or 400 (detail) tall, then scaled
 * uniformly to the container's width, so every demo can use the same point values as the app.
 */
import { Component, Suspense, lazy, useEffect, useLayoutEffect, useMemo, useRef, useState, type ReactNode } from "react";
import { demoLoaders } from "../effects/registry";
import { HapticStage } from "./haptics";
import { StageRuntimeContext } from "./runtime";
import { makeContext, type DemoComponent, type Lang, type ParamValues, type Scheme } from "./types";
import "./kit.css";

export const CANVAS_WIDTH = 340;
export const PREVIEW_HEIGHT = 340;
export const DETAIL_HEIGHT = 400;

const lazyCache = new Map<string, DemoComponent>();
function lazyDemo(id: string): DemoComponent | null {
  const loader = demoLoaders[id];
  if (!loader) return null;
  let component = lazyCache.get(id);
  if (!component) {
    component = lazy(loader) as unknown as DemoComponent;
    lazyCache.set(id, component);
  }
  return component;
}

class DemoErrorBoundary extends Component<{ children: ReactNode; id: string }, { error: Error | null }> {
  state = { error: null as Error | null };
  static getDerivedStateFromError(error: Error) {
    return { error };
  }
  componentDidCatch(error: Error) {
    console.error(`[demo ${this.props.id}]`, error);
  }
  render() {
    if (this.state.error) {
      return (
        <div style={{ position: "absolute", inset: 0, display: "grid", placeItems: "center", padding: 20, color: "#ff4d5e", fontSize: 12, textAlign: "center" }}>
          {String(this.state.error.message || this.state.error)}
        </div>
      );
    }
    return this.props.children;
  }
}

export interface DemoStageProps {
  id: string;
  params: ParamValues;
  lang?: Lang;
  scheme?: Scheme;
  preview?: boolean;
  /** Changing it rebuilds the demo (the app's Reset button). */
  resetKey?: number;
  /** Paused previews (scrolled away) stop their autoplay loops. */
  autoplay?: boolean;
  /** Show the app's stage backdrop (off when the host draws its own). */
  background?: boolean;
  /** Canvas height in authoring points; defaults to 340 (preview) or 400 (detail). */
  height?: number;
  className?: string;
  style?: React.CSSProperties;
}

export function hasDemo(id: string) {
  return id in demoLoaders;
}

export function DemoStage({
  id,
  params,
  lang = "zh",
  scheme = "dark",
  preview = false,
  resetKey = 0,
  autoplay = true,
  background = true,
  height,
  className,
  style,
}: DemoStageProps) {
  const host = useRef<HTMLDivElement>(null);
  const [scale, setScale] = useState(0);
  const canvasHeight = height ?? (preview ? PREVIEW_HEIGHT : DETAIL_HEIGHT);
  const reduceMotion = useReducedMotion();

  useLayoutEffect(() => {
    const el = host.current;
    if (!el) return;
    const update = () => setScale(el.clientWidth / CANVAS_WIDTH);
    update();
    const observer = new ResizeObserver(update);
    observer.observe(el);
    return () => observer.disconnect();
  }, []);

  const ctx = useMemo(() => makeContext(params, preview, lang, scheme), [params, preview, lang, scheme]);
  const runtime = useMemo(
    () => ({ autoplayEnabled: autoplay && !reduceMotion, introPlay: !preview, reduceMotion }),
    [autoplay, reduceMotion, preview],
  );
  const Demo = lazyDemo(id);

  return (
    <div
      ref={host}
      className={className}
      style={{ position: "relative", width: "100%", aspectRatio: `${CANVAS_WIDTH} / ${canvasHeight}`, overflow: "hidden", ...style }}
    >
      <div
        className="ml-canvas"
        data-scheme={scheme}
        style={{
          position: "absolute",
          left: 0,
          top: 0,
          width: CANVAS_WIDTH,
          height: canvasHeight,
          transform: `scale(${scale})`,
          transformOrigin: "0 0",
          visibility: scale > 0 ? "visible" : "hidden",
          pointerEvents: preview ? "none" : "auto",
        }}
      >
        {background && <div className="ml-stage-bg" />}
        <StageRuntimeContext.Provider value={runtime}>
          <HapticStage enabled={!preview}>
            <div style={{ position: "absolute", inset: 0 }}>
              {Demo ? (
                <DemoErrorBoundary id={id} key={`${id}:${resetKey}`}>
                  <Suspense fallback={null}>
                    <Demo ctx={ctx} />
                  </Suspense>
                </DemoErrorBoundary>
              ) : (
                <div style={{ position: "absolute", inset: 0, display: "grid", placeItems: "center", color: "var(--ml-label2)", fontSize: 13 }}>
                  {lang === "zh" ? "尚未移植" : "Not ported yet"}
                </div>
              )}
            </div>
          </HapticStage>
        </StageRuntimeContext.Provider>
      </div>
    </div>
  );
}

function useReducedMotion() {
  const [reduce, setReduce] = useState(() => typeof matchMedia !== "undefined" && matchMedia("(prefers-reduced-motion: reduce)").matches);
  useEffect(() => {
    if (typeof matchMedia === "undefined") return;
    const query = matchMedia("(prefers-reduced-motion: reduce)");
    const onChange = () => setReduce(query.matches);
    query.addEventListener("change", onChange);
    return () => query.removeEventListener("change", onChange);
  }, []);
  return reduce;
}
