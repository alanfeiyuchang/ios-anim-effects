/** Parameter controls (slider / toggle / segmented choice), like the app's detail page. */
import type { EffectInfo } from "../catalog-model";
import { formatParam, sliderStep } from "../catalog-model";
import type { Lang, ParamValues } from "../kit/types";

export function ParamControls({
  effect,
  values,
  lang,
  onChange,
}: {
  effect: EffectInfo;
  values: ParamValues;
  lang: Lang;
  onChange: (next: ParamValues) => void;
}) {
  if (effect.params.length === 0) return null;
  const set = (id: string, value: number) => onChange({ ...values, [id]: value });
  return (
    <div className="mw-params">
      {effect.params.map((p) => {
        const value = values[p.id] ?? 0;
        return (
          <div className="mw-param" key={p.id}>
            <div className="mw-param-head">
              <span>{p.name[lang]}</span>
              <b>{formatParam(p, value, lang)}</b>
            </div>
            {p.kind === "slider" && (
              <input
                type="range"
                min={p.min}
                max={p.max}
                step={sliderStep(p)}
                value={value}
                onChange={(e) => set(p.id, Number(e.target.value))}
              />
            )}
            {p.kind === "toggle" && (
              <button type="button" className={`mw-switch ${value > 0.5 ? "on" : ""}`} aria-pressed={value > 0.5} onClick={() => set(p.id, value > 0.5 ? 0 : 1)}>
                <i />
              </button>
            )}
            {p.kind === "choice" && (
              <div className="mw-seg">
                {(p.options ?? []).map((o, index) => (
                  <button type="button" key={index} className={Math.round(value) === index ? "on" : ""} onClick={() => set(p.id, index)}>
                    {o[lang]}
                  </button>
                ))}
              </div>
            )}
          </div>
        );
      })}
    </div>
  );
}
