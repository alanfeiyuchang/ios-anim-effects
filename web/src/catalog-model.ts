/**
 * Types and helpers for the app's exported catalog (`-ML_exportCatalog YES`, see
 * MotionLab/App/CatalogTools.swift). No data here: `catalog.ts` loads the JSON for the gallery,
 * and the docs site hands `live.js` the entry of the effect it opens.
 */
import type { Lang, ParamValues } from "./kit/types";

export type Text = { en: string; zh: string };

export interface ParamSpec {
  id: string;
  name: Text;
  kind: "slider" | "toggle" | "choice";
  unit: string;
  default: number | boolean;
  min?: number;
  max?: number;
  step?: number;
  decimals?: number;
  options?: Text[];
}

export interface EffectInfo {
  id: string;
  category: string;
  family: string;
  interaction: string;
  name: Text;
  summary: Text;
  prompt: Text;
  implementation: Text;
  apis: string[];
  tags: string[];
  params: ParamSpec[];
  requirement?: string;
}

export interface CategoryInfo {
  id: string;
  title: Text;
  subtitle: Text;
  symbol: string;
}

export interface FamilyInfo {
  id: string;
  category: string;
  name: Text;
  summary: Text;
  symbol: string;
}

export function defaultParams(effect: EffectInfo): ParamValues {
  const values: ParamValues = {};
  for (const p of effect.params) values[p.id] = typeof p.default === "boolean" ? (p.default ? 1 : 0) : p.default;
  return values;
}

export function formatParam(spec: ParamSpec, value: number, lang: Lang): string {
  if (spec.kind === "toggle") return value > 0.5 ? (lang === "zh" ? "开" : "on") : lang === "zh" ? "关" : "off";
  if (spec.kind === "choice") {
    const options = spec.options ?? [];
    const index = Math.min(Math.max(Math.round(value), 0), Math.max(options.length - 1, 0));
    return options[index]?.[lang] ?? "";
  }
  const decimals = spec.decimals ?? guessDecimals(spec);
  return value.toFixed(decimals) + spec.unit;
}

/** Older catalogs have no `decimals`: infer them from the numbers themselves. */
export function guessDecimals(spec: ParamSpec): number {
  const places = [spec.min, spec.max, spec.default as number].map((v) => {
    const s = String(v ?? 0);
    return s.includes(".") ? s.split(".")[1].length : 0;
  });
  return Math.min(Math.max(...places), 2);
}

/** Slider step: the spec's own, or continuous (1/200 of the range) when it has none. */
export function sliderStep(spec: ParamSpec): number {
  if (spec.step) return spec.step;
  const range = (spec.max ?? 1) - (spec.min ?? 0);
  return range / 200;
}

/** The prompt plus the current parameter values (Swift `Effect.fullPrompt`). */
export function fullPrompt(effect: EffectInfo, values: ParamValues, lang: Lang): string {
  const base = effect.prompt[lang];
  if (effect.params.length === 0) return base;
  const joined = effect.params
    .map((p) => `${p.name[lang]} ${formatParam(p, values[p.id] ?? 0, lang)}`)
    .join(lang === "zh" ? "，" : ", ");
  return `${base}\n\n${lang === "zh" ? "当前参数：" : "Current parameters: "}${joined}${lang === "zh" ? "。" : "."}`;
}
