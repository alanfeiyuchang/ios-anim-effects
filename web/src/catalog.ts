/**
 * The app's exported catalog (`-ML_exportCatalog YES`, see MotionLab/App/CatalogTools.swift):
 * names, prompts and parameter specs of every effect. The web demos only add the motion.
 */
import raw from "./catalog.json";
import type { CategoryInfo, EffectInfo, FamilyInfo } from "./catalog-model";

export * from "./catalog-model";

interface Catalog {
  categories: CategoryInfo[];
  families: FamilyInfo[];
  effects: EffectInfo[];
}

export const catalog = raw as unknown as Catalog;
export const effectByID: Record<string, EffectInfo> = Object.fromEntries(catalog.effects.map((e) => [e.id, e]));
