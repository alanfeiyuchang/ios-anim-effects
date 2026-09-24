# Effect authoring guide

Every entry in Motion Lexicon is one `Effect` value plus a private SwiftUI demo view.
Read `MotionLab/Core/Effect.swift`, `MotionLab/Core/DemoKit.swift` and `MotionLab/Core/Localization.swift` first.

## Toolchain constraints

- Target: **iOS 18.0**, Swift 5 language mode, Xcode 16+. APIs from iOS 18 or earlier are fine without `#available`
  (`MeshGradient`, `TextRenderer`, `.symbolEffect(.wiggle/.rotate/.breathe)`, `onScrollGeometryChange`,
  `scrollTransition`, `visualEffect`, `phaseAnimator`, `keyframeAnimator`, `contentTransition(.numericText)`,
  `@Previewable`, `Tab`, `matchedGeometryEffect`, `Canvas`, `TimelineView`, `sensoryFeedback`, custom `Transition`).
- iOS 26 APIs (Liquid Glass) must be wrapped in `#if compiler(>=6.2)` **and** `if #available(iOS 26.0, *)` with a fallback.
- Pure SwiftUI + UIKit only. No third-party packages, no image assets (use SF Symbols, shapes, gradients).
- The project uses file-system-synchronized groups: any `.swift` file under `MotionLab/` is compiled automatically.

## File layout

```
MotionLab/Effects/<Category>/<Category>Effects.swift   // enum XxxEffects { static let all: [Effect] }
MotionLab/Effects/<Category>/<Category>+<Name>.swift    // one file per effect (or small groups)
```

Each effect file declares a static on `Effect` and its demo view(s) as `private` types:

```swift
import SwiftUI

extension Effect {
    static let buttonsPressScale = Effect(
        id: "buttons.press-scale",            // "<category rawValue>.<kebab-slug>", globally unique
        category: .buttons,
        interaction: .tap,
        name: L("Press Scale", "按压缩放"),
        summary: L("A spring-loaded press that sinks and rebounds.", "按下时下沉、松手后弹性回弹的按钮。"),
        prompt: L(
            "A pill-shaped primary button that responds to touch-down by scaling to 94% with a slight dimming of brightness, then on release overshoots to ~103% and settles back to 100% using a critically-damped spring (response 0.35 s, damping 0.6). The motion is instantaneous on press and elastic on release, giving a tactile, physical feel with a light haptic tick.",
            "胶囊形主按钮：手指按下瞬间缩放至 94% 并轻微降低亮度；松手后以弹簧曲线（响应 0.35 秒、阻尼 0.6）回弹，先轻微过冲到约 103%，再稳定回到 100%。按下反馈即时、松手回弹富有弹性，配合轻触觉反馈，呈现真实可触的物理质感。"
        ),
        implementation: L(
            "A custom ButtonStyle reads configuration.isPressed and drives scaleEffect + brightness through a spring animation.",
            "自定义 ButtonStyle 读取 configuration.isPressed，通过弹簧动画驱动 scaleEffect 与 brightness。"
        ),
        apis: ["ButtonStyle", "scaleEffect", "spring(response:dampingFraction:)", "sensoryFeedback"],
        tags: ["press", "bounce", "弹性", "按压", "micro-interaction", "微交互"],
        params: [
            .slider("scale", L("Pressed scale", "按下缩放"), 0.8...1.0, default: 0.94),
            .slider("response", L("Spring response", "弹簧响应"), 0.1...1.0, default: 0.35, unit: "s"),
            .slider("damping", L("Damping", "阻尼"), 0.2...1.0, default: 0.6),
        ]
    ) { ctx in
        PressScaleDemo(ctx: ctx)
    }
}

private struct PressScaleDemo: View {
    let ctx: DemoContext
    @State private var autoPressed = false

    var body: some View {
        Button { Haptics.tap() } label: {
            Text(ctx.language == .zh ? "继续" : "Continue")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(width: 200, height: 56)
                .background(Palette.primary, in: Capsule())
        }
        .buttonStyle(PressStyle(scale: ctx.cg("scale"), response: ctx["response"], damping: ctx["damping"], forcePressed: autoPressed))
        .autoplay(ctx.isPreview, every: 0.9) { autoPressed.toggle() }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
```

and the category list file:

```swift
enum ButtonEffects {
    static let all: [Effect] = [
        .buttonsPressScale,
        .buttonsMagnetic,
        // …
    ]
}
```

## Family membership (required)

Every effect belongs to exactly one **family** — a group of variations of the same UI element or pattern
(`inputs.slider`, `loading.spinner`, `navigation.tab-indicator`…). Families are shown between a category and its
effects (category page → family page → detail) and power the "Variations" strip on the detail page.

Membership lives outside effect files, in `MotionLab/Families/<Category>Families.swift`:

```swift
enum InputsFamilies {
    static let all: [EffectFamily] = [ /* the category's families, in display order */ ]
    static let membership: [String: String] = [
        "inputs.velocity-slider": "inputs.slider",   // effect id → family id
        // …
    ]
}
```

When you add an effect:

1. Add it to the category's `all` list as usual. Its position there is also its position inside the family.
2. Add **one** line `"<effect id>": "<family id>",` to that category's `membership`. Each effect id appears once —
   a duplicate key in a dictionary literal traps at launch.
3. Pick an existing family from [`docs/FAMILIES.md`](FAMILIES.md). Only add a new `EffectFamily` when no existing one fits;
   its id is `"<category rawValue>.<kebab-slug>"` (note: `shaders.`, not `shader.`), with a bilingual `name` and one-line
   `summary`, and an SF Symbol. Families of one category are listed in `all` in the order they should appear.
4. An effect without a valid membership line is not lost: it shows up in its category's fallback "More · 更多" family.
   Treat that family appearing as a bug to fix.

A variation should differ from its siblings in *motion style* (curve, physics, choreography, material), not just in color —
the Compare mode on the family page plays all variations side by side.

## Demo rules (important)

1. **Stage size.** The demo fills whatever frame it is given. Detail stage ≈ 360×400 pt; grid previews render
   the demo in a **340×340** canvas and scale it down. Design for ~340×340, keep content centered with
   `.frame(maxWidth: .infinity, maxHeight: .infinity)`, never assume the screen size, never use `UIScreen`.
   The container draws the background & clips; demos should not add a full-bleed opaque background
   unless the effect *is* a background.
   Exception: Signature Interactions (Showcase) demos draw their own dark glossy stage (`SignatureStage`) on purpose —
   they reproduce dark widget cards and use white text on it in both appearances.
2. **Previews must move.** In previews (`ctx.isPreview == true`) the demo cannot be touched.
   Tap/gesture/state demos must auto-play using `.autoplay(ctx.isPreview, every: seconds) { … }`
   (call the same function the tap calls, with `withAnimation` inside). Gesture demos should simulate a
   drag (e.g. animate the offset) in preview mode. Scroll demos should auto-scroll or animate their content.
   Loops (`TimelineView`, `phaseAnimator`, `repeatForever`) already move.
   On the detail page the same autoplay action runs **once** on arrival (the intro play). A demo that already
   starts itself in `onAppear` must pass `intro: false` so it doesn't play twice. The intro and autoplay must never
   leave the demo pressed/highlighted, and haptics fired after a delay must be guarded with `!ctx.isPreview`.
   The detail page silences `Haptics.*` for 2.5 s after arrival, a variation switch and Reset (`Haptics.quiet(for:)`),
   so arrival plays never buzz; the first real touch on the stage ends that silence (`TouchDownObserver` → `Haptics.endQuiet()`), so a user's very first interaction always gets its haptic. `.sensoryFeedback` bypasses all of this, so demos use `Haptics.*` instead.
   When `ctx.isStill` is true a still thumbnail is being rendered: show the finished state (chart drawn, text revealed).
   **`onAppear` runs in stills too.** `ImageRenderer` fires `onAppear` before it draws, so a demo that seeds settled
   data and then resets it to zero in `onAppear` (to replay its entrance) renders as empty axes. Guard such resets
   with `guard !ctx.isStill else { return }` (or `@Environment(\.demoIsStill)` in subviews). The screenshot script's
   still audit (`-ML_auditStills YES`, `still-audit.json`) flags Data & Charts stills that come out empty.
   **Materials in stills.** Stills are drawn with `ImageRenderer`, which cannot render `Material`
   (`.ultraThinMaterial`, `.thinMaterial`, `.regularMaterial`, `.bar`, …) or Liquid Glass: they come out as
   solid black slabs, very visible on the light-mode cards. Never put a material behind demo content directly;
   use the still-safe helpers from `DemoKit`, which draw the real material live and a translucent fill tinted for
   the colour scheme (white 72 % in light, dark grey 72 % in dark, plus a hairline) inside a still:
   ```swift
   // before: .background(.ultraThinMaterial, in: Capsule())
   .demoGlass(Capsule())
   .demoGlass(RoundedRectangle(cornerRadius: 18, style: .continuous), material: .regularMaterial)
   .demoGlass(Circle(), material: .bar, fallback: Palette.sky.opacity(0.25))  // custom still fill
   // as a view, e.g. inside a ZStack or `.background { }`:
   DemoMaterial(Capsule(), material: .thinMaterial)
   ```
   Subviews that don't receive `ctx` can read `@Environment(\.demoIsStill)` (the snapshot renderer sets it
   together with `ctx.isStill`), e.g. to skip `.glassEffect(...)` and use `.demoGlass(...)` in a still.
3. **Interactive in detail.** In the detail page everything should respond to touch. Show a short hint via
   `DemoHint(text: L("Tap the button", "点击按钮"), ctx: ctx)` when the interaction isn't obvious (hidden in previews).
4. **Parameters.** 1–4 meaningful parameters per effect (spring response/damping, duration, intensity, count, radius,
   toggle for a variant, a choice between styles…). Read them with `ctx["id"]`, `ctx.cg("id")`, `ctx.bool("id")`,
   `ctx.int("id")`. Parameters change live while `@State` is preserved, so derive values in `body`.
   Keep defaults tasteful — the preview uses them.
5. **Premium feel.** Springs over linear curves, continuous-corner rounded rects, soft shadows, subtle gradients
   from `Palette`, `.monospacedDigit()` for numbers, haptics (`Haptics.tap()` / `.success()`), 60fps-friendly
   (prefer `drawingGroup()` for heavy Canvas / many layers). Light & dark mode must both look good — use
   `.primary`, `.secondary`, `Palette.surface/elevated`, materials (through `.demoGlass`, see rule 2).
6. **Prompts.** The `prompt` is the star of the app: a precise, professional motion-design description a designer
   or an AI code generator can reproduce the effect from. Write each language natively (don't translate word
   for word). Cover: the element & its resting look → trigger → the motion sequence (what moves, from/to values,
   order, stagger, timing in ms/s, curve/spring parameters, overshoot) → secondary details (blur, shadow, haptics,
   color shifts) → the feeling it conveys. 2–5 sentences, 70–150 English words / 110–240 characters in Chinese
   (every non-whitespace character counts: Han, punctuation, digits, Latin)
   (hard cap; cut filler and repetition before cutting timing values).
   The app appends the live parameter values automatically, so don't list the parameters again verbatim.
7. **Implementation** text: 1–2 sentences on how it is built. `apis`: 2–6 key API names.
   `tags`: 4–8 search keywords in both English and Chinese (synonyms people would search for).
8. **Code hygiene.** All helper types `private` (file-scoped) and prefixed-free names are fine since they're private.
   Static property names on `Effect` must be globally unique: prefix with the category (`buttonsXxx`, `loadingXxx`).
   No force unwraps, no `print`, no deprecated APIs (`.animation(_:)` without `value:` is deprecated — always pass `value:`).
   Avoid `GeometryReader` when `containerRelativeFrame`/`visualEffect`/`onGeometryChange` suffices.
   Keep each `body` small; split sub-views to help the type checker. Double-check every API signature — the code
   cannot be compiled before review, so correctness by inspection matters more than cleverness.
