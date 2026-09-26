#!/usr/bin/env node
/**
 * Screenshots ported demos for visual checks against the app's recordings.
 *
 *   node scripts/shot.mjs <id> [<id>…] [--times 0.3,1.2,2.5] [--preview] [--lang en] [--scheme light]
 *                         [--click x,y@t] [--drag x1,y1>x2,y2@t] [--ref] [--out shots]
 *
 * Needs the dev server (npm run dev) on http://127.0.0.1:5173 (or --base <url>).
 * Writes <out>/<id>[.preview].<t>s.png per time; --ref also saves the app's poster frame
 * (<out>/<id>.ref.jpg) from the published docs site. Pointer coordinates are canvas points
 * (340 wide). Console errors of the page are printed.
 */
import { chromium } from "playwright";
import { mkdirSync, writeFileSync } from "node:fs";
import { join } from "node:path";

const args = process.argv.slice(2);
const ids = [];
const opt = { times: [0.4, 1.5, 3], preview: false, lang: "zh", scheme: "dark", out: "shots", base: "http://127.0.0.1:5173", actions: [], ref: false };
for (let i = 0; i < args.length; i++) {
  const a = args[i];
  if (a === "--times") opt.times = args[++i].split(",").map(Number);
  else if (a === "--preview") opt.preview = true;
  else if (a === "--lang") opt.lang = args[++i];
  else if (a === "--scheme") opt.scheme = args[++i];
  else if (a === "--out") opt.out = args[++i];
  else if (a === "--base") opt.base = args[++i];
  else if (a === "--ref") opt.ref = true;
  else if (a === "--click") {
    const [pt, at] = args[++i].split("@");
    const [x, y] = pt.split(",").map(Number);
    opt.actions.push({ kind: "click", x, y, at: Number(at ?? 0) });
  } else if (a === "--drag") {
    const [pts, at] = args[++i].split("@");
    const [p1, p2] = pts.split(">");
    const [x1, y1] = p1.split(",").map(Number);
    const [x2, y2] = p2.split(",").map(Number);
    opt.actions.push({ kind: "drag", x1, y1, x2, y2, at: Number(at ?? 0) });
  } else ids.push(a);
}
if (!ids.length) {
  console.error("usage: node scripts/shot.mjs <effect-id> [...] [--times 0.4,1.5,3] [--preview] [--click x,y@t] [--drag x1,y1>x2,y2@t] [--ref]");
  process.exit(2);
}
mkdirSync(opt.out, { recursive: true });

const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 400, height: 500 }, deviceScaleFactor: 2 });
page.on("console", (m) => { if (m.type() === "error") console.log(`  console.error: ${m.text()}`); });
page.on("pageerror", (e) => console.log(`  pageerror: ${e.message}`));

for (const id of ids) {
  const url = `${opt.base}/?shot=1&id=${encodeURIComponent(id)}&lang=${opt.lang}&scheme=${opt.scheme}${opt.preview ? "&preview=1" : ""}`;
  await page.goto(url, { waitUntil: "networkidle" });
  const t0 = Date.now();
  const stage = page.locator("#shot");
  await stage.waitFor();
  const box = await stage.boundingBox();
  const s = box.width / 340;
  const events = [
    ...opt.times.map((t) => ({ at: t, kind: "shot" })),
    ...opt.actions,
  ].sort((a, b) => a.at - b.at);
  for (const ev of events) {
    const wait = ev.at * 1000 - (Date.now() - t0);
    if (wait > 0) await page.waitForTimeout(wait);
    if (ev.kind === "shot") {
      const file = join(opt.out, `${id}${opt.preview ? ".preview" : ""}.${ev.at}s.png`);
      await stage.screenshot({ path: file });
      console.log(file);
    } else if (ev.kind === "click") {
      await page.mouse.click(box.x + ev.x * s, box.y + ev.y * s);
    } else if (ev.kind === "drag") {
      await page.mouse.move(box.x + ev.x1 * s, box.y + ev.y1 * s);
      await page.mouse.down();
      const steps = 14;
      for (let k = 1; k <= steps; k++) {
        await page.mouse.move(box.x + (ev.x1 + ((ev.x2 - ev.x1) * k) / steps) * s, box.y + (ev.y1 + ((ev.y2 - ev.y1) * k) / steps) * s);
        await page.waitForTimeout(16);
      }
      await page.mouse.up();
    }
  }
  if (opt.ref) {
    const res = await fetch(`https://alanfeiyuchang.github.io/motionary-ios-animations/media/${id}.${opt.lang}.jpg`);
    if (res.ok) {
      const file = join(opt.out, `${id}.ref.jpg`);
      writeFileSync(file, Buffer.from(await res.arrayBuffer()));
      console.log(file);
    } else console.log(`  no reference poster (${res.status})`);
  }
}
await browser.close();
