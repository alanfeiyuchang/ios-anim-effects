/**
 * Every ported demo, collected from each category's `index.ts` (which maps effect ids to lazy
 * loaders). Adding a category folder with an `index.ts` is enough; nothing here needs editing.
 */
import type { DemoLoader, DemoMap } from "../kit/types";

const modules = import.meta.glob<{ demos: DemoMap }>("./*/index*.ts", { eager: true });

export const demoLoaders: Record<string, DemoLoader> = Object.assign({}, ...Object.values(modules).map((m) => m.demos));

export const portedIDs = new Set(Object.keys(demoLoaders));

// A category's index changing (a newly registered demo) would otherwise propagate to the gallery entry
// and remount the whole page. Merge the new ids into the existing maps instead; the grid picks them up
// on the next navigation.
if (import.meta.hot) {
  import.meta.hot.accept((next) => {
    if (!next) return;
    Object.assign(demoLoaders, next.demoLoaders);
    for (const id of next.portedIDs as Set<string>) portedIDs.add(id);
  });
}
