# Porting a SwiftUI demo to the web

Every effect in `MotionLab/Effects/<Category>/` gets a React twin in `web/src/effects/<category>/`.
Names, prompts, parameters and families come from the app's exported catalog (`src/catalog.json`);
a port only re-creates the **demo**: what it looks like, how it moves, and how it responds to touch.
The bar is "someone who knows the app cannot tell which one they are touching", apart from the haptic
(which is a small shake of the stage on the web, see below).

## Where things go

```
web/src/effects/<category>/<slug>.tsx   one effect per file, `export default function Xxx({ ctx }: DemoProps)`
web/src/effects/<category>/<helper>.tsx shared pieces of that category (like `showcase/signature.tsx`)
web/src/effects/<category>/index.ts     export const demos: DemoMap = { "<effect-id>": () => import("./<slug>") }
```

`<slug>` is the effect id without its category prefix (`showcase.save-burst` → `save-burst.tsx`).
Several variations may share one file when the Swift source does (export one component per id and
point the ids at small files that re-export, or give each its own default export file).
Look at `showcase/save-burst.tsx` (tap, keyframes, particles, toast) and `showcase/slide-to-start.tsx`
(drag gesture, rubber band, scripted autoplay) before starting.

**Do not edit anything under `src/kit/`, `src/gallery/`, `src/shell/`, `src/catalog*`, or another
category's folder.** Other people are working there at the same time. If the kit is missing something,
write it inside your category folder; if the kit has a bug, work around it locally and report it.

## The canvas

- Demos are laid out on a canvas **340 px wide**; points in Swift = px here. Height is 340 in grid
  previews and 400 on the detail stage. Lay out with flexbox like the SwiftUI stacks do (a `VStack`
  with `Spacer()`s centres its content in either height).
- `ctx.isPreview` is true for grid thumbnails. `ctx.lang` is `"zh" | "en"`; `ctx.t(en, zh)` localizes.
- Parameters: `ctx.n("id")` (number), `ctx.b("id")` (toggle), `ctx.i("id")` (choice index / rounded).
- Colours: `Palette` in `kit/palette.ts` mirrors `Palette` in DemoKit.swift. Adaptive system colours
  (`.primary`, `.secondary`, `Palette.surface`, `.elevated`, `.stroke`, `Color(uiColor: .systemBackground)`)
  are CSS variables there, so the same demo works on the light and the dark stage. `hex(0xFF8A1F, 0.5)`,
  `white(0.3)`, `black(0.2)` for the rest.
- Fonts: `fonts.text`, `fonts.rounded` (`design: .rounded`), `fonts.mono`, `fonts.serif`; `textStyle`
  has SwiftUI's text-style sizes (`.footnote` = 13 px …). Weights: `.medium` 500, `.semibold` 600,
  `.bold` 700, `.heavy` 800, `.black` 900. `.monospacedDigit()` = `fontVariantNumeric: "tabular-nums"`.

## Motion: match the numbers

- `spring(response, dampingFraction)` in `kit/spring.ts` is SwiftUI's spring **exactly** (same curve).
  `anim.spring`, `anim.smooth`, `anim.snappy`, `anim.bouncy`, `anim.interactive`, `anim.easeInOut(d)`,
  `anim.easeIn(d)`, `anim.easeOut(d)`, `anim.linear(d)`, `anim.curve(a,b,c,d, duration)`,
  `springDB(duration, bounce)`, `delayed(t, s)`, `forever(t, autoreverses)`.
- `withAnimation(x) { state = … }` → set React state and give the animated element
  `transition={x}` (motion's `animate` prop), or `animate(motionValue, target, x)` for motion values.
- `.transition(.move / .opacity / .scale …)` → `AnimatePresence` + `initial` / `exit`.
- `keyframeAnimator` / `phaseAnimator` / hand-timed sequences → `useElapsed(trigger, duration)` and
  compute the frame yourself with `springAt(elapsed, response, damping)`, `ease.inOut(p)`,
  `progress(t, start, duration)`, `mix(a, b, p)`; or motion keyframes with `times`.
- `TimelineView(.animation)` → `useClock(running, ctx.isPreview ? 30 : undefined)` (seconds since mount).
- `Canvas { context, size in … }` → a `<canvas>` drawn in a `requestAnimationFrame` loop (scale it by
  `devicePixelRatio`, 2× at least) or SVG, whichever is closer.
- `matchedGeometryEffect` → motion `layoutId` (inside a `LayoutGroup` when needed).
- `.contentTransition(.numericText())` → `<NumericText value={n} />`.
- `symbolEffect(.bounce …)` → `<SymbolBounce trigger={value}>`. `.contentTransition(.symbolEffect(.replace))`
  → `AnimatePresence mode="popLayout"` swapping keyed icons with scale + blur (see save-burst).
- `.blur`, `.shadow`, `.rotation3DEffect` (→ `perspective` + `rotateX/Y`), `.mask`, `.blendMode`,
  `.hueRotation`, gradients (`LinearGradient` → `linear-gradient`, `AngularGradient` → `conic-gradient`,
  `RadialGradient` → `radial-gradient`, `MeshGradient` → layered radial gradients or a small WebGL
  shader) all have CSS equivalents; use them.
- Materials (`.ultraThinMaterial`, `demoGlass`, `DemoMaterial`) → `...glass("ultraThin")`.
  iOS 26 Liquid Glass → glass + a bright specular edge (inset highlights) + slight saturation.
- Metal shaders (`.colorEffect` / `.layerEffect` / `.distortionEffect`, source in
  `MotionLab/Shaders/Shaders.metal`) → `ShaderCanvas` in `kit/shader.tsx`: translate the Metal
  function to GLSL ES 1.0. For a `layerEffect`, draw the layer's content into a 2D canvas and pass it
  as `source`.
- SF Symbols cannot be used on the web: use the closest `lucide-react` icon (`fill="currentColor"`
  + `strokeWidth={0}` for `.fill` symbols when the outline shape is closed), or draw a small SVG when
  the symbol's shape matters to the effect (e.g. a heart that must fill with liquid).

## Interaction

- Taps: `onClick` (or `onPointerDown` when the app reacts on touch-down). Button pressed looks
  (`ButtonStyle` / `configuration.isPressed` / `LatchedPress`) → a `pressed` state from
  `pressHandlers(setPressed)`.
- Drags: `usePan({ onStart, onChange, onEnd }, minimumDistance)` gives `translation`, `location`,
  `start` and `velocity` in canvas points (the web `DragGesture`). Drive motion values with `.set()`
  while dragging and `animate(mv, target, spring(…))` on release (see slide-to-start).
- Double tap: `useDoubleTap(handler)` on `onPointerUp`. Long press: a timer started on pointer-down.
- Pinch / rotate: pointer events with two active pointers (track them in a Map).
- Scroll demos: a `div` with `overflowY: "auto"`, `touchAction: "pan-y"` (the canvas disables browser
  gestures by default) and `onScroll`; derive the effect from `scrollTop` like the Swift code derives it
  from its scroll offset / `onScrollGeometryChange` / `scrollTransition` / `visualEffect`. Hide the
  scrollbar (`scrollbarWidth: "none"`).
- Pointer coordinates inside the scaled canvas: `localPoint(event, element)`.

## Haptics → a small shake

Call `const haptics = useHaptics()` and keep **every** Swift haptic call at the same moment with the same
kind: `Haptics.tap(.medium)` → `haptics.tap("medium")`, `.success()`, `.error()`, `.selection()`,
`.warning()`. The stage shakes a little instead of vibrating; previews and autoplay are silent
automatically, so `if !ctx.isPreview` guards around haptics can be dropped. Never add visual "haptic"
badges or labels.

## Autoplay (previews and the detail intro)

`.autoplay(ctx.isPreview, every: 1.5, delay: 0.4) { … }` → `useAutoplay(ctx.isPreview, () => { … }, { every: 1.5, delay: 0.4 })`
with the **same** numbers and `intro: false` when Swift passes `intro: false`. Demos that loop by
themselves (TimelineView, repeatForever, onAppear sequences) need no autoplay. Grid previews must
show the effect moving, exactly as the app's thumbnails do.

## Verify every effect

The dev server runs at `http://127.0.0.1:5173` (start `npx vite --port <free port>` yourself if it is
not reachable and pass `--base`). The gallery shows `?id=<effect-id>` (live stage, parameters, the
app's own recording beside it) and `?cat=<category>` (all previews).

```
node scripts/shot.mjs <id> [<id>…] --ref --times 0.4,1.5,3 --out <your shots dir>      # detail frames + the app's poster
node scripts/shot.mjs <id> --preview --times 1,2.5 --out <dir>                          # grid preview
node scripts/shot.mjs <id> --click 170,200@1.2 --times 1.0,1.6 --out <dir>              # tap at canvas point
node scripts/shot.mjs <id> --drag 60,200>280,200@1.2 --times 1.0,1.7 --out <dir>       # drag
```

Look at the PNGs next to `<id>.ref.jpg` (the app's recorded frame; it is a square preview-sized
crop): layout, sizes, colours, text and motion state must match. Fix and re-shoot until they do. The
script prints console errors; there must be none. For interactive effects shoot before/after a
`--click` / `--drag` and confirm the response. Typecheck your folder:
`npx tsc --noEmit 2>&1 | grep "src/effects/<category>/"` must print nothing.

Keep screenshots outside the repo (your scratchpad), and do not commit anything.
