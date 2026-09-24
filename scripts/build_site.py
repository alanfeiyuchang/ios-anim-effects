#!/usr/bin/env python3
"""Builds the Motionary documentation site.

Input:  a catalog JSON exported by the app (`-ML_exportCatalog YES`) and a folder of per-effect
        video loops (<effect-id>.mp4) + posters (<effect-id>.jpg) recorded in the simulator.
Output: a static, bilingual (中文 / English) single-page site in the output folder.

Usage: scripts/build_site.py catalog.json media/ site/
"""
import html
import json
import os
import shutil
import sys

CATEGORY_GRADIENTS = {
    "showcase": ["#FFB02E", "#FF5A1F"], "buttons": ["#6E7BFF", "#A46BFF"], "inputs": ["#3AC4FF", "#4F7CFF"],
    "loading": ["#21D4A8", "#2A9DF4"], "feedback": ["#FF8A5B", "#FF4D7A"], "morph": ["#B86BFF", "#FF6BC1"],
    "navigation": ["#5B8CFF", "#39D0D8"], "cards": ["#FF6B8B", "#FFB36B"], "scroll": ["#4ED6A0", "#5AA8FF"],
    "text": ["#FFC247", "#FF7A45"], "icons": ["#7C5CFF", "#4FA3FF"], "gestures": ["#00C2A8", "#7BE36B"],
    "charts": ["#4F7CFF", "#8A5CFF"], "backgrounds": ["#FF5FA2", "#7B61FF"], "shaders": ["#2BD9FE", "#AA5CFF"],
}


def main():
    if len(sys.argv) != 4:
        print(__doc__)
        sys.exit(2)
    catalog_path, media_dir, out_dir = sys.argv[1:]
    with open(catalog_path, encoding="utf-8") as f:
        catalog = json.load(f)

    os.makedirs(os.path.join(out_dir, "media"), exist_ok=True)
    videos = posters = 0
    for effect in catalog["effects"]:
        eid = effect["id"]
        effect["video"], effect["poster"] = {}, {}
        for lang in ("zh", "en"):
            for ext, key in ((".mp4", "video"), (".jpg", "poster")):
                name = f"{eid}.{lang}{ext}"
                src = os.path.join(media_dir, name)
                if os.path.exists(src) and os.path.getsize(src) > 0:
                    shutil.copyfile(src, os.path.join(out_dir, "media", name))
                    effect[key][lang] = True
                    if key == "video":
                        videos += 1
                    else:
                        posters += 1
    for category in catalog["categories"]:
        category["gradient"] = CATEGORY_GRADIENTS.get(category["id"], ["#6E7BFF", "#A46BFF"])

    # Live, interactive app (Appetize.io); falls back to the key recorded by an earlier upload.
    key = os.environ.get("APPETIZE_PUBLIC_KEY", "").strip()
    if not key:
        try:
            with open(os.path.join(os.path.dirname(__file__), "..", "docs", "appetize.json"), encoding="utf-8") as f:
                key = json.load(f).get("publicKey", "")
        except (OSError, ValueError):
            key = ""
    catalog["appetize"] = key

    data = json.dumps(catalog, ensure_ascii=False, separators=(",", ":")).replace("</", "<\\/")
    page = TEMPLATE.replace("__DATA__", data)
    with open(os.path.join(out_dir, "index.html"), "w", encoding="utf-8") as f:
        f.write(page)
    with open(os.path.join(out_dir, ".nojekyll"), "w") as f:
        f.write("")
    print(f"Site: {len(catalog['effects'])} effects, {videos} videos, {posters} posters, "
          f"live preview {'on (' + key + ')' if key else 'off'} → {out_dir}")


TEMPLATE = r"""<!doctype html>
<html lang="zh-Hans">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<title>Motionary – 动效词典</title>
<meta name="description" content="A living dictionary of premium iOS motion — every effect with a live loop, parameters and a bilingual prompt.">
<style>
:root{
  --bg:#f5f5f8;--panel:#ffffff;--panel2:#eeeef3;--text:#141418;--muted:#6b6b76;--line:rgba(0,0,0,.08);
  --accent:#4B57E0;--accent2:#A46BFF;--shadow:0 10px 30px rgba(20,20,40,.08);--radius:22px;
}
@media (prefers-color-scheme: dark){:root:not([data-theme="light"]){
  --bg:#0b0b0e;--panel:#16161b;--panel2:#1f1f26;--text:#f2f2f6;--muted:#9a9aa6;--line:rgba(255,255,255,.08);
  --accent:#8A94FF;--shadow:0 10px 30px rgba(0,0,0,.4);}}
:root[data-theme="dark"]{--bg:#0b0b0e;--panel:#16161b;--panel2:#1f1f26;--text:#f2f2f6;--muted:#9a9aa6;--line:rgba(255,255,255,.08);--accent:#8A94FF;--shadow:0 10px 30px rgba(0,0,0,.4);}
*{box-sizing:border-box}
html,body{margin:0;background:var(--bg);color:var(--text);font:15px/1.5 -apple-system,BlinkMacSystemFont,"SF Pro Text","PingFang SC","Helvetica Neue",sans-serif;-webkit-font-smoothing:antialiased}
a{color:var(--accent)}
.wrap{max-width:1180px;margin:0 auto;padding:0 16px}
header.hero{position:relative;overflow:hidden;padding:56px 0 28px}
.hero .mesh{position:absolute;inset:-40%;filter:blur(60px);opacity:.55;pointer-events:none;
  background:radial-gradient(40% 40% at 20% 30%,#6E7BFF,transparent 70%),radial-gradient(35% 35% at 70% 25%,#FF5FA2,transparent 70%),
  radial-gradient(40% 40% at 55% 75%,#21D4A8,transparent 70%),radial-gradient(30% 30% at 90% 70%,#FFC247,transparent 70%);
  animation:drift 18s ease-in-out infinite alternate}
@keyframes drift{to{transform:translate3d(4%,-3%,0) rotate(8deg) scale(1.08)}}
@media (prefers-reduced-motion: reduce){.hero .mesh{animation:none}}
.hero h1{position:relative;font-size:clamp(34px,6vw,56px);line-height:1.05;margin:0 0 8px;letter-spacing:-.02em}
.hero p{position:relative;margin:0;color:var(--muted);max-width:640px}
.stats{position:relative;display:flex;gap:10px;flex-wrap:wrap;margin-top:18px}
.pill{background:var(--panel);border:1px solid var(--line);border-radius:999px;padding:6px 14px;font-weight:600;box-shadow:var(--shadow)}
.pill b{background:linear-gradient(90deg,var(--accent),var(--accent2));-webkit-background-clip:text;background-clip:text;color:transparent;font-variant-numeric:tabular-nums}
.bar{position:sticky;top:0;z-index:5;backdrop-filter:saturate(1.6) blur(18px);-webkit-backdrop-filter:saturate(1.6) blur(18px);
  background:color-mix(in srgb,var(--bg) 78%,transparent);border-bottom:1px solid var(--line)}
.bar .wrap{display:flex;gap:10px;align-items:center;padding-top:10px;padding-bottom:10px}
.search{flex:1;min-width:0;display:flex;align-items:center;gap:8px;background:var(--panel);border:1px solid var(--line);border-radius:14px;padding:9px 12px}
.search input{flex:1;min-width:0;border:0;outline:0;background:transparent;color:var(--text);font:inherit}
.seg{display:flex;background:var(--panel2);border-radius:12px;padding:3px}
.seg button{border:0;background:transparent;color:var(--muted);font:inherit;font-weight:600;padding:6px 10px;border-radius:9px;cursor:pointer}
.seg button.on{background:var(--panel);color:var(--text);box-shadow:0 1px 4px rgba(0,0,0,.12)}
.chips{display:flex;gap:8px;overflow-x:auto;padding:10px 0 12px;scrollbar-width:none}
.chips::-webkit-scrollbar{display:none}
.chip{flex:none;border:1px solid var(--line);background:var(--panel);color:var(--text);border-radius:999px;padding:6px 12px;font:inherit;font-weight:600;cursor:pointer;white-space:nowrap}
.chip.on{color:#fff;border-color:transparent;background:linear-gradient(135deg,#4B57E0,#8A4FE0)}
.chip small{opacity:.7;font-variant-numeric:tabular-nums;margin-left:4px}
section.cat{padding:26px 0 8px}
.cat-head{display:flex;gap:12px;align-items:center;margin-bottom:6px}
.cat-dot{width:38px;height:38px;border-radius:12px;flex:none}
.cat-head h2{margin:0;font-size:24px;letter-spacing:-.01em}
.cat-sub{color:var(--muted);margin:0 0 14px}
.family{margin:18px 0 6px}
.family h3{margin:0;font-size:17px}
.family .fs{color:var(--muted);font-size:13px;margin:2px 0 10px}
.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(172px,1fr));gap:14px}
.card{background:var(--panel);border:1px solid var(--line);border-radius:var(--radius);padding:8px 8px 12px;box-shadow:var(--shadow);cursor:pointer;
  transition:transform .35s cubic-bezier(.2,.9,.25,1.2),box-shadow .3s}
.card:hover{transform:translateY(-3px)}
.card:active{transform:scale(.97)}
.media{position:relative;aspect-ratio:1;border-radius:16px;overflow:hidden;background:var(--panel2)}
.media video,.media img{width:100%;height:100%;object-fit:cover;display:block}
.media .none{position:absolute;inset:0;display:grid;place-items:center;color:var(--muted);font-size:12px}
.card h4{margin:10px 4px 2px;font-size:14px;line-height:1.3}
.card p{margin:0 4px;color:var(--muted);font-size:12px;line-height:1.4;display:-webkit-box;-webkit-line-clamp:2;-webkit-box-orient:vertical;overflow:hidden}
.badge{position:absolute;top:8px;left:8px;font-size:10px;font-weight:700;padding:3px 7px;border-radius:999px;background:rgba(0,0,0,.55);color:#fff}
.empty{padding:60px 0;text-align:center;color:var(--muted)}
dialog{border:0;padding:0;border-radius:26px;background:var(--panel);color:var(--text);width:min(920px,calc(100vw - 24px));max-height:calc(100vh - 24px);box-shadow:0 30px 80px rgba(0,0,0,.35)}
dialog::backdrop{background:rgba(0,0,0,.45);backdrop-filter:blur(6px)}
.dlg{display:grid;grid-template-columns:minmax(0,380px) minmax(0,1fr);gap:22px;padding:22px}
@media (max-width:760px){.dlg{grid-template-columns:1fr;padding:16px}}
.dlg .media{border-radius:20px}
.dlg h2{margin:4px 0 4px;font-size:26px;letter-spacing:-.01em}
.meta{display:flex;flex-wrap:wrap;gap:6px;margin:6px 0 10px}
.tag{font-size:12px;padding:3px 9px;border-radius:999px;background:var(--panel2);color:var(--muted)}
.tag.api{font-family:ui-monospace,SFMono-Regular,Menlo,monospace}
.block{margin:14px 0}
.block h5{margin:0 0 6px;font-size:13px;color:var(--muted);text-transform:uppercase;letter-spacing:.06em}
.prompt{position:relative;background:color-mix(in srgb,var(--accent) 8%,transparent);border-radius:14px;padding:14px 14px 14px 18px;line-height:1.65}
.prompt:before{content:"";position:absolute;left:0;top:10px;bottom:10px;width:3px;border-radius:3px;background:linear-gradient(var(--accent),var(--accent2))}
.btn{border:0;border-radius:12px;padding:9px 14px;font:inherit;font-weight:700;color:#fff;cursor:pointer;background:linear-gradient(135deg,#4B57E0,#8A4FE0)}
.btn.ok{background:#17803F}
.btn.ghost{background:var(--panel2);color:var(--text)}
table.params{width:100%;border-collapse:collapse;font-size:13px}
table.params td,table.params th{padding:7px 6px;border-bottom:1px solid var(--line);text-align:left}
table.params th{color:var(--muted);font-weight:600}
.close{position:absolute;top:12px;right:12px}
.variants{display:flex;gap:8px;overflow-x:auto;padding-bottom:4px}
.variants .v{flex:none;width:86px;cursor:pointer}
.variants .v .media{border-radius:12px}
.variants .v span{display:block;font-size:11px;margin-top:4px;color:var(--muted);white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.variants .v.on span{color:var(--text);font-weight:700}
.live{position:relative;width:100%;aspect-ratio:9/19.5;max-height:78vh;border-radius:20px;overflow:hidden;background:#000}
.live iframe{position:absolute;inset:0;width:100%;height:100%;border:0}
.hero .btn{position:relative;margin-top:16px}
.dlg-app{padding:18px;display:grid;place-items:center}
.dlg-app .live{width:min(390px,100%)}
footer{padding:40px 0 60px;color:var(--muted);font-size:13px;text-align:center}
</style>
</head>
<body>
<header class="hero"><div class="mesh"></div><div class="wrap">
  <h1 data-i18n="title"></h1><p data-i18n="subtitle"></p>
  <div class="stats" id="stats"></div>
  <button class="btn" id="tryApp" hidden></button>
</div></header>
<div class="bar"><div class="wrap">
  <label class="search"><span aria-hidden="true">⌕</span><input id="q" type="search" autocomplete="off"></label>
  <div class="seg" role="group" aria-label="Language"><button id="lang-zh">中文</button><button id="lang-en">EN</button></div>
</div><div class="wrap"><div class="chips" id="chips"></div></div></div>
<main class="wrap" id="main"></main>
<footer class="wrap" id="foot"></footer>
<dialog id="dlg"></dialog>
<script>
const DATA = __DATA__;
const I18N = {
  zh:{title:"Motionary",subtitle:"动效词典 · 可上手玩的 iOS 高级动效：每个动效都附实时录制的动画循环、可调参数与中英专业提示词。",effects:"个动效",categories:"个分类",families:"个家族",
      search:"搜索动效、API、关键词…",all:"全部",prompt:"提示词",copy:"复制提示词",copied:"已复制",impl:"实现方式",apis:"关键 API",tags:"标签",params:"参数",
      param:"参数",def:"默认值",range:"范围",variants:"同家族变体",none:"暂无录像",noResults:"没有匹配的动效",requires:"需要",close:"关闭",
      foot:"由 Motionary App 自动生成 · 动画均为 iOS 模拟器实录",
      live:"▶ 在线交互试玩",liveApp:"▶ 在线试玩完整 App",video:"返回录像",liveNote:"真实 App 运行在云端 iOS 模拟器中（Appetize.io），可直接点击、拖动。启动约需数秒。"},
  en:{title:"Motionary",subtitle:"iOS Motion Dictionary — every effect with a real recorded loop, tunable parameters and a native bilingual prompt.",effects:"effects",categories:"categories",families:"families",
      search:"Search effects, APIs, keywords…",all:"All",prompt:"Prompt",copy:"Copy prompt",copied:"Copied",impl:"Implementation",apis:"Key APIs",tags:"Tags",params:"Parameters",
      param:"Parameter",def:"Default",range:"Range",variants:"Variations in this family",none:"No recording yet",noResults:"No matching effects",requires:"Requires",close:"Close",
      foot:"Generated from the Motionary app · every animation recorded in the iOS Simulator",
      live:"▶ Try it live",liveApp:"▶ Try the full app live",video:"Back to video",liveNote:"The real app running in a cloud iOS Simulator (Appetize.io) — tap and drag as on a phone. It takes a few seconds to boot."}
};
let lang = localStorage.getItem("ml.lang") || ((navigator.language||"").toLowerCase().startsWith("zh") ? "zh" : "en");
let cat = null, query = "";
const $ = s => document.querySelector(s);
const t = k => I18N[lang][k];
const L = o => (o && (o[lang] ?? o.en)) || "";
const esc = s => String(s).replace(/[&<>"']/g, c => ({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;"}[c]));
const famById = Object.fromEntries(DATA.families.map(f => [f.id, f]));
const effById = Object.fromEntries(DATA.effects.map(e => [e.id, e]));
const hay = e => [L(e.name), e.name.en, e.name.zh, e.summary.en, e.summary.zh, (e.apis||[]).join(" "), (e.tags||[]).join(" "),
  famById[e.family] ? famById[e.family].name.en + " " + famById[e.family].name.zh : "", e.id].join(" ").toLowerCase();

// Media is recorded per language (demo text follows the UI language); fall back to the other language.
const pick = (e, key) => { const m = e[key] || {}; const l = m[lang] ? lang : (m.zh ? "zh" : (m.en ? "en" : null)); return l ? `media/${e.id}.${l}.${key==="video"?"mp4":"jpg"}` : null; };
function mediaHTML(e, autoplay){
  const v = pick(e, "video"), p = pick(e, "poster");
  if (v) return autoplay ? `<video muted loop playsinline autoplay ${p?`poster="${p}"`:""} src="${v}"></video>`
                         : `<video muted loop playsinline preload="none" ${p?`poster="${p}"`:""} data-src="${v}"></video>`;
  if (p) return `<img loading="lazy" src="${p}" alt="">`;
  return `<div class="none">${t("none")}</div>`;
}
// Appetize embed of the real app; `link` deep-links to one screen (motionlexicon://effect/<id>).
function liveHTML(link){
  const q = new URLSearchParams({device:"iphone16pro", scale:"auto", autoplay:"true", centered:"both",
    language: lang === "zh" ? "zh-Hans" : "en", locale: lang === "zh" ? "zh_CN" : "en_US"});
  if (link) q.set("launchUrl", link);
  return `<div class="live"><iframe src="https://appetize.io/embed/${encodeURIComponent(DATA.appetize)}?${q}"
    allow="clipboard-write" title="Motionary"></iframe></div><p style="color:var(--muted);font-size:12px">${t("liveNote")}</p>`;
}
function openApp(){
  const d = $("#dlg");
  d.innerHTML = `<div style="position:relative"><button class="btn ghost close" id="x" aria-label="${t("close")}">✕</button>
    <div class="dlg-app">${liveHTML("")}</div></div>`;
  d.querySelector("#x").onclick = () => d.close();
  if (!d.open) d.showModal();
}
function cardHTML(e){
  return `<article class="card" data-id="${e.id}" tabindex="0" role="button" aria-label="${esc(L(e.name))}">
    <div class="media">${mediaHTML(e)}${e.requirement?`<span class="badge">${esc(e.requirement)}</span>`:""}</div>
    <h4>${esc(L(e.name))}</h4><p>${esc(L(e.summary))}</p></article>`;
}
function render(){
  document.documentElement.lang = lang === "zh" ? "zh-Hans" : "en";
  document.title = lang === "zh" ? "Motionary – 动效词典" : "Motionary – iOS Motion Dictionary";
  document.querySelectorAll("[data-i18n]").forEach(n => n.textContent = t(n.dataset.i18n));
  $("#q").placeholder = t("search");
  $("#tryApp").hidden = !DATA.appetize; $("#tryApp").textContent = t("liveApp");
  $("#lang-zh").classList.toggle("on", lang==="zh"); $("#lang-en").classList.toggle("on", lang==="en");
  $("#stats").innerHTML = `<span class="pill"><b>${DATA.effects.length}</b> ${t("effects")}</span>
    <span class="pill"><b>${DATA.families.length}</b> ${t("families")}</span><span class="pill"><b>${DATA.categories.length}</b> ${t("categories")}</span>`;
  const q = query.trim().toLowerCase().split(/\s+/).filter(Boolean);
  const match = e => (!cat || e.category===cat) && q.every(w => hay(e).includes(w));
  $("#chips").innerHTML = `<button class="chip ${!cat?"on":""}" data-cat="">${t("all")}<small>${DATA.effects.length}</small></button>` +
    DATA.categories.map(c => `<button class="chip ${cat===c.id?"on":""}" data-cat="${c.id}">${esc(L(c.title))}<small>${DATA.effects.filter(e=>e.category===c.id).length}</small></button>`).join("");
  let out = "";
  for (const c of DATA.categories){
    if (cat && c.id !== cat) continue;
    const fams = DATA.families.filter(f => f.category === c.id);
    let body = "";
    for (const f of fams){
      const list = DATA.effects.filter(e => e.family === f.id && match(e));
      if (!list.length) continue;
      body += `<div class="family"><h3>${esc(L(f.name))} <span class="tag">${list.length}</span></h3><div class="fs">${esc(L(f.summary))}</div>
        <div class="grid">${list.map(cardHTML).join("")}</div></div>`;
    }
    const loose = DATA.effects.filter(e => e.category===c.id && !famById[e.family] && match(e));
    if (loose.length) body += `<div class="family"><div class="grid">${loose.map(cardHTML).join("")}</div></div>`;
    if (!body) continue;
    const g = c.gradient;
    out += `<section class="cat" id="${c.id}"><div class="cat-head"><div class="cat-dot" style="background:linear-gradient(135deg,${g[0]},${g[1]})"></div>
      <h2>${esc(L(c.title))}</h2></div><p class="cat-sub">${esc(L(c.subtitle))}</p>${body}</section>`;
  }
  $("#main").innerHTML = out || `<div class="empty">${t("noResults")}</div>`;
  $("#foot").textContent = t("foot") + (DATA.generated ? " · " + DATA.generated.slice(0,10) : "");
  observe();
}
const io = new IntersectionObserver(entries => {
  for (const en of entries){
    const v = en.target;
    if (en.isIntersecting){ if (!v.src) v.src = v.dataset.src; v.play().catch(()=>{}); } else { v.pause(); }
  }
}, {rootMargin:"200px"});
function observe(){ document.querySelectorAll("video[data-src]").forEach(v => io.observe(v)); }

function paramRange(p){
  if (p.kind === "slider") return `${p.min} – ${p.max}${p.unit||""}`;
  if (p.kind === "toggle") return lang==="zh" ? "开 / 关" : "on / off";
  if (p.kind === "choice") return (p.options||[]).map(L).join(" · ");
  return "";
}
function paramDefault(p){
  if (p.kind === "toggle") return p.default ? (lang==="zh"?"开":"on") : (lang==="zh"?"关":"off");
  if (p.kind === "choice") return L((p.options||[])[p.default] || {});
  return `${p.default}${p.unit||""}`;
}
function openEffect(id){
  const e = effById[id]; if (!e) return;
  const f = famById[e.family];
  const sibs = f ? DATA.effects.filter(x => x.family === f.id) : [];
  const d = $("#dlg");
  d.innerHTML = `<div style="position:relative"><button class="btn ghost close" id="x" aria-label="${t("close")}">✕</button>
   <div class="dlg"><div><div id="stage"><div class="media">${mediaHTML(e, true)}</div></div>
   ${DATA.appetize?`<div style="margin-top:10px"><button class="btn" id="live">${t("live")}</button></div>`:""}
   ${sibs.length>1?`<div class="block"><h5>${t("variants")}</h5><div class="variants">${sibs.map(s=>`<div class="v ${s.id===e.id?"on":""}" data-id="${s.id}"><div class="media">${pick(s,"poster")?`<img loading="lazy" src="${pick(s,"poster")}" alt="">`:""}</div><span>${esc(L(s.name))}</span></div>`).join("")}</div></div>`:""}
   </div><div>
   <div class="meta"><span class="tag">${esc(L((DATA.categories.find(c=>c.id===e.category)||{}).title||{}))}</span>${f?`<span class="tag">${esc(L(f.name))}</span>`:""}${e.requirement?`<span class="tag">${t("requires")} ${esc(e.requirement)}</span>`:""}</div>
   <h2>${esc(L(e.name))}</h2><div style="color:var(--muted)">${esc(L(e.summary))}</div>
   <div class="block"><h5>${t("prompt")}</h5><div class="prompt" id="ptxt">${esc(L(e.prompt))}</div>
     <div style="margin-top:10px;display:flex;gap:8px"><button class="btn" id="copy">${t("copy")}</button>
     <button class="btn ghost" id="other">${lang==="zh"?"English prompt":"中文提示词"}</button></div></div>
   ${(e.params||[]).length?`<div class="block"><h5>${t("params")}</h5><table class="params"><tr><th>${t("param")}</th><th>${t("def")}</th><th>${t("range")}</th></tr>
     ${e.params.map(p=>`<tr><td>${esc(L(p.name))}</td><td>${esc(paramDefault(p))}</td><td>${esc(paramRange(p))}</td></tr>`).join("")}</table></div>`:""}
   <div class="block"><h5>${t("impl")}</h5><div>${esc(L(e.implementation))}</div></div>
   <div class="block"><h5>${t("apis")}</h5><div class="meta">${(e.apis||[]).map(a=>`<span class="tag api">${esc(a)}</span>`).join("")}</div></div>
   <div class="block"><h5>${t("tags")}</h5><div class="meta">${(e.tags||[]).map(a=>`<span class="tag">#${esc(a)}</span>`).join("")}</div></div>
   </div></div></div>`;
  let shownLang = lang;
  d.querySelector("#x").onclick = () => d.close();
  d.querySelector("#copy").onclick = async ev => {
    try { await navigator.clipboard.writeText(e.prompt[shownLang]); ev.target.textContent = t("copied"); ev.target.classList.add("ok");
      setTimeout(()=>{ev.target.textContent=t("copy");ev.target.classList.remove("ok")},1600);} catch(_){}
  };
  d.querySelector("#other").onclick = ev => {
    shownLang = shownLang === "zh" ? "en" : "zh";
    d.querySelector("#ptxt").textContent = e.prompt[shownLang];
    ev.target.textContent = shownLang === "zh" ? "English prompt" : "中文提示词";
  };
  d.querySelectorAll(".variants .v").forEach(v => v.onclick = () => openEffect(v.dataset.id));
  const live = d.querySelector("#live");
  if (live){
    const stage = d.querySelector("#stage"), recorded = stage.innerHTML;
    live.onclick = () => {
      const on = !stage.querySelector(".live");
      stage.innerHTML = on ? liveHTML("motionlexicon://effect/" + e.id) : recorded;
      live.textContent = on ? t("video") : t("live");
    };
  }
  if (!d.open) d.showModal();
  history.replaceState(null, "", "#" + e.id);
}
document.addEventListener("click", ev => {
  const chip = ev.target.closest(".chip"); if (chip){ cat = chip.dataset.cat || null; render(); window.scrollTo({top: document.querySelector(".bar").offsetTop, behavior:"smooth"}); return; }
  const card = ev.target.closest(".card"); if (card) openEffect(card.dataset.id);
});
document.addEventListener("keydown", ev => { if (ev.key==="Enter" && ev.target.classList && ev.target.classList.contains("card")) openEffect(ev.target.dataset.id); });
$("#dlg").addEventListener("close", () => history.replaceState(null, "", location.pathname));
$("#tryApp").onclick = openApp;
$("#q").addEventListener("input", ev => { query = ev.target.value; render(); });
$("#lang-zh").onclick = () => { lang="zh"; localStorage.setItem("ml.lang","zh"); render(); };
$("#lang-en").onclick = () => { lang="en"; localStorage.setItem("ml.lang","en"); render(); };
render();
if (location.hash.length > 1) openEffect(decodeURIComponent(location.hash.slice(1)));
</script>
</body>
</html>
"""

if __name__ == "__main__":
    main()
