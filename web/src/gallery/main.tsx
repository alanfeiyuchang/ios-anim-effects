/**
 * Development & verification gallery.
 *
 *   /                          every category, ported count, search
 *   ?cat=showcase              live preview grid of one category
 *   ?id=showcase.save-burst    detail: live stage, parameters, reset, reference recording from the app
 *   ?id=…&shot=1               bare stage only (scripts/shot.mjs screenshots it)
 *        &preview=1 &lang=en &scheme=light &p.<param>=<value>
 */
import { StrictMode, useEffect, useMemo, useRef, useState } from "react";
import { createRoot } from "react-dom/client";
import { catalog, defaultParams, effectByID, type EffectInfo } from "../catalog";
import { portedIDs } from "../effects/registry";
import { DemoStage } from "../kit/stage";
import type { Lang, ParamValues, Scheme } from "../kit/types";
import { ParamControls } from "../shell/ParamControls";
import "../shell/shell.css";
import "./gallery.css";

const MEDIA = "https://alanfeiyuchang.github.io/motionary-ios-animations/media";
const query = new URLSearchParams(location.search);

function paramsFromQuery(effect: EffectInfo): ParamValues {
  const values = defaultParams(effect);
  for (const [key, value] of query) if (key.startsWith("p.")) values[key.slice(2)] = Number(value);
  return values;
}

function Shot() {
  const effect = effectByID[query.get("id") ?? ""];
  if (!effect) return <p>unknown id</p>;
  const width = Number(query.get("w") ?? 340);
  return (
    <div id="shot" style={{ width }}>
      <DemoStage
        id={effect.id}
        params={paramsFromQuery(effect)}
        preview={query.get("preview") === "1"}
        lang={(query.get("lang") as Lang) ?? "zh"}
        scheme={(query.get("scheme") as Scheme) ?? "dark"}
      />
    </div>
  );
}

function Toolbar({ lang, setLang, scheme, setScheme }: { lang: Lang; setLang: (l: Lang) => void; scheme: Scheme; setScheme: (s: Scheme) => void }) {
  return (
    <div className="g-tools">
      <a href="?">← 全部</a>
      <span style={{ flex: 1 }} />
      <button className={lang === "zh" ? "on" : ""} onClick={() => setLang("zh")}>中文</button>
      <button className={lang === "en" ? "on" : ""} onClick={() => setLang("en")}>EN</button>
      <button className={scheme === "dark" ? "on" : ""} onClick={() => setScheme("dark")}>深色</button>
      <button className={scheme === "light" ? "on" : ""} onClick={() => setScheme("light")}>浅色</button>
    </div>
  );
}

function Detail({ effect }: { effect: EffectInfo }) {
  const [lang, setLang] = useState<Lang>((query.get("lang") as Lang) ?? "zh");
  const [scheme, setScheme] = useState<Scheme>((query.get("scheme") as Scheme) ?? "dark");
  const [params, setParams] = useState<ParamValues>(() => paramsFromQuery(effect));
  const [reset, setReset] = useState(0);
  const siblings = catalog.effects.filter((e) => e.family === effect.family);
  const index = catalog.effects.findIndex((e) => e.id === effect.id);
  const prev = catalog.effects[index - 1];
  const next = catalog.effects[index + 1];
  return (
    <div className={`g-page g-${scheme}`}>
      <Toolbar lang={lang} setLang={setLang} scheme={scheme} setScheme={setScheme} />
      <h1>
        {effect.name[lang]} <small>{effect.id}</small> {portedIDs.has(effect.id) ? <em className="ok">已移植</em> : <em>未移植</em>}
      </h1>
      <p className="g-summary">{effect.summary[lang]}</p>
      <div className="g-detail">
        <section>
          <h3>Web（可交互）</h3>
          <div className="g-stage">
            <DemoStage id={effect.id} params={params} lang={lang} scheme={scheme} resetKey={reset} />
          </div>
          <div className="g-row">
            <button onClick={() => setReset((r) => r + 1)}>重置</button>
            <button onClick={() => setParams(defaultParams(effect))}>默认参数</button>
          </div>
          <ParamControls effect={effect} values={params} lang={lang} onChange={setParams} />
        </section>
        <section>
          <h3>App 实录（参考）</h3>
          <div className="g-stage">
            <video key={`${effect.id}.${lang}`} src={`${MEDIA}/${effect.id}.${lang}.mp4`} poster={`${MEDIA}/${effect.id}.${lang}.jpg`} autoPlay muted loop playsInline />
          </div>
          <h3>缩略图预览（Web）</h3>
          <div className="g-thumb">
            <DemoStage id={effect.id} params={params} lang={lang} scheme={scheme} preview />
          </div>
        </section>
      </div>
      {siblings.length > 1 && (
        <div className="g-sibs">
          {siblings.map((s) => (
            <a key={s.id} href={`?id=${s.id}`} className={s.id === effect.id ? "on" : ""}>
              {s.name[lang]}
              {portedIDs.has(s.id) ? " ✓" : ""}
            </a>
          ))}
        </div>
      )}
      <div className="g-row">
        {prev && <a href={`?id=${prev.id}`}>← {prev.name[lang]}</a>}
        <span style={{ flex: 1 }} />
        {next && <a href={`?id=${next.id}`}>{next.name[lang]} →</a>}
      </div>
      <details>
        <summary>提示词</summary>
        <p className="g-prompt">{effect.prompt[lang]}</p>
      </details>
    </div>
  );
}

function LazyPreview({ effect, lang, scheme }: { effect: EffectInfo; lang: Lang; scheme: Scheme }) {
  const ref = useRef<HTMLAnchorElement>(null);
  const [visible, setVisible] = useState(false);
  useEffect(() => {
    const el = ref.current;
    if (!el) return;
    const io = new IntersectionObserver(([entry]) => setVisible(entry.isIntersecting), { rootMargin: "100px" });
    io.observe(el);
    return () => io.disconnect();
  }, []);
  const params = useMemo(() => defaultParams(effect), [effect]);
  return (
    <a ref={ref} className="g-card" href={`?id=${effect.id}`}>
      <div className="g-thumb">
        {visible && portedIDs.has(effect.id) ? (
          <DemoStage id={effect.id} params={params} lang={lang} scheme={scheme} preview />
        ) : (
          <img loading="lazy" src={`${MEDIA}/${effect.id}.${lang}.jpg`} alt="" style={{ opacity: portedIDs.has(effect.id) ? 1 : 0.35 }} />
        )}
      </div>
      <b>{effect.name[lang]}</b>
      <small>{portedIDs.has(effect.id) ? "✓ " : "· "}{effect.id}</small>
    </a>
  );
}

function CategoryGrid({ cat }: { cat: string }) {
  const [lang, setLang] = useState<Lang>("zh");
  const [scheme, setScheme] = useState<Scheme>("dark");
  const effects = catalog.effects.filter((e) => e.category === cat);
  const info = catalog.categories.find((c) => c.id === cat);
  return (
    <div className={`g-page g-${scheme}`}>
      <Toolbar lang={lang} setLang={setLang} scheme={scheme} setScheme={setScheme} />
      <h1>
        {info?.title[lang]} <small>{effects.filter((e) => portedIDs.has(e.id)).length}/{effects.length}</small>
      </h1>
      <div className="g-grid">
        {effects.map((e) => (
          <LazyPreview key={e.id} effect={e} lang={lang} scheme={scheme} />
        ))}
      </div>
    </div>
  );
}

function Index() {
  const total = catalog.effects.length;
  const done = catalog.effects.filter((e) => portedIDs.has(e.id)).length;
  return (
    <div className="g-page g-dark">
      <h1>
        Motionary Web <small>已移植 {done}/{total}</small>
      </h1>
      <div className="g-cats">
        {catalog.categories.map((c) => {
          const list = catalog.effects.filter((e) => e.category === c.id);
          const n = list.filter((e) => portedIDs.has(e.id)).length;
          return (
            <a key={c.id} href={`?cat=${c.id}`}>
              <b>{c.title.zh}</b>
              <span>
                {n}/{list.length}
              </span>
              <i style={{ width: `${(n / list.length) * 100}%` }} />
            </a>
          );
        })}
      </div>
    </div>
  );
}

function App() {
  if (query.get("shot") === "1") return <Shot />;
  const id = query.get("id");
  if (id && effectByID[id]) return <Detail effect={effectByID[id]} />;
  const cat = query.get("cat");
  if (cat) return <CategoryGrid cat={cat} />;
  return <Index />;
}

// Reuse the root when a hot update re-runs this module (a registry edit propagates here), instead of
// calling createRoot() on the same container twice.
const container = document.getElementById("root") as HTMLElement & { _root?: ReturnType<typeof createRoot> };
container._root ??= createRoot(container);
container._root.render(
  <StrictMode>
    <App />
  </StrictMode>,
);
