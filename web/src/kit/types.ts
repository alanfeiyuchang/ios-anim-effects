import type { ComponentType } from "react";

export type Lang = "zh" | "en";
export type Scheme = "dark" | "light";

/** Current parameter values of a demo, keyed by the catalog's param id. */
export type ParamValues = Record<string, number>;

/**
 * Everything a demo needs to render; the web twin of Swift's `DemoContext`.
 * Read params with `ctx.n("response")`, `ctx.b("toast")`, `ctx.i("style")`, like `ctx["x"]`,
 * `ctx.bool("x")` and `ctx.int("x")` in Swift.
 */
export interface DemoContext {
  params: ParamValues;
  /** A small, non-interactive grid thumbnail: tap-driven demos autoplay (see `useAutoplay`). */
  isPreview: boolean;
  lang: Lang;
  scheme: Scheme;
  n(id: string): number;
  b(id: string): boolean;
  i(id: string): number;
  /** Localized text: `ctx.t("Saved", "已收藏")`. */
  t(en: string, zh: string): string;
}

export interface DemoProps {
  ctx: DemoContext;
}

export type DemoComponent = ComponentType<DemoProps>;

/** A category's `index.ts` maps effect ids to lazy loaders so each demo is its own chunk. */
export type DemoLoader = () => Promise<{ default: DemoComponent }>;
export type DemoMap = Record<string, DemoLoader>;

export function makeContext(params: ParamValues, isPreview: boolean, lang: Lang, scheme: Scheme): DemoContext {
  return {
    params,
    isPreview,
    lang,
    scheme,
    n: (id) => params[id] ?? 0,
    b: (id) => (params[id] ?? 0) > 0.5,
    i: (id) => Math.round(params[id] ?? 0),
    t: (en, zh) => (lang === "zh" ? zh : en),
  };
}
