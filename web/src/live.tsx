/**
 * `live.js`: loaded by the docs site (scripts/build_site.py) to put a live, interactive demo with
 * parameter controls into its effect dialog.
 *
 *     const live = await import("./live/live.js");
 *     live.has(id);                                   // ported?
 *     const handle = live.mount(el, { effect, lang, scheme, onPrompt });   // effect: the page's catalog entry
 *     handle.unmount();
 */
import { StrictMode, useEffect, useState } from "react";
import { createRoot } from "react-dom/client";
import { defaultParams, fullPrompt, type EffectInfo } from "./catalog-model";
import { portedIDs } from "./effects/registry";
import { DemoStage } from "./kit/stage";
import type { Lang, ParamValues, Scheme } from "./kit/types";
import { ParamControls } from "./shell/ParamControls";
import kitCSS from "./kit/kit.css?inline";
import shellCSS from "./shell/shell.css?inline";

/** A bare JS entry gets no <link> for its CSS, so the styles are injected once on first mount. */
function injectStyles() {
  if (document.getElementById("motionary-live-css")) return;
  const style = document.createElement("style");
  style.id = "motionary-live-css";
  style.textContent = kitCSS + "\n" + shellCSS;
  document.head.appendChild(style);
}

export const ported: string[] = [...portedIDs];

export function has(id: string): boolean {
  return portedIDs.has(id);
}

const LABELS = {
  zh: { reset: "重置", defaults: "默认参数", params: "参数", haptic: "触感反馈在网页上以轻微震动表现" },
  en: { reset: "Reset", defaults: "Defaults", params: "Parameters", haptic: "Haptics show as a small shake on the web" },
};

function LivePanel({ effect, lang, scheme, onPrompt }: { effect: EffectInfo; lang: Lang; scheme: Scheme; onPrompt?: (prompt: string) => void }) {
  const id = effect.id;
  const [params, setParams] = useState<ParamValues>(() => defaultParams(effect));
  const [reset, setReset] = useState(0);
  const t = LABELS[lang];
  const change = (next: ParamValues) => {
    setParams(next);
    onPrompt?.(fullPrompt(effect, next, lang));
  };
  // The copied prompt carries the current parameter line from the start, like the app's.
  useEffect(() => {
    onPrompt?.(fullPrompt(effect, defaultParams(effect), lang));
  }, [effect, lang, onPrompt]);
  return (
    <div className="mw-live">
      <div className="mw-live-stage">
        <DemoStage id={id} params={params} lang={lang} scheme={scheme} resetKey={reset} />
        <button type="button" className="mw-live-reset" onClick={() => setReset((r) => r + 1)} aria-label={t.reset}>
          ↺
        </button>
      </div>
      {effect.params.length > 0 && (
        <div className="mw-live-params">
          <div className="mw-live-head">
            <span>{t.params}</span>
            <button type="button" onClick={() => change(defaultParams(effect))}>
              {t.defaults}
            </button>
          </div>
          <ParamControls effect={effect} values={params} lang={lang} onChange={change} />
        </div>
      )}
      <p className="mw-live-note">{t.haptic}</p>
    </div>
  );
}

export function mount(
  element: HTMLElement,
  options: { effect: EffectInfo; lang?: Lang; scheme?: Scheme; onPrompt?: (prompt: string) => void },
) {
  injectStyles();
  const root = createRoot(element);
  root.render(
    <StrictMode>
      <LivePanel effect={options.effect} lang={options.lang ?? "zh"} scheme={options.scheme ?? "dark"} onPrompt={options.onPrompt} />
    </StrictMode>,
  );
  return { unmount: () => root.unmount() };
}
