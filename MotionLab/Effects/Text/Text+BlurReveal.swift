import SwiftUI

extension Effect {
    static let textBlurReveal = Effect(
        id: "text.blur-reveal",
        category: .text,
        interaction: .state,
        name: L("Blur-in Reveal", "逐字模糊显现"),
        summary: L("Glyphs resolve from a soft blur one after another.", "字形依次从柔和的模糊中清晰浮现。"),
        prompt: L(
            "A two-line editorial statement appears glyph by glyph, as if coming into focus. Each character starts fully transparent, blurred by about 10 pt and sitting 10 pt low, then resolves to sharp, opaque and in place with an ease-out-cubic curve; characters start in reading order with overlapping windows, so a soft focus front sweeps through the sentence over ~1.4 s. On dismissal the same choreography runs in reverse and the last glyphs dissolve first. Cinematic, calm and premium — like a title card in an Apple keynote.",
            "两行编辑感的文案逐字出现，仿佛镜头慢慢对焦。每个字符起始时完全透明、带约 10pt 的模糊并下沉 10pt，随后以三次缓出曲线变得清晰、不透明并回到原位；字符按阅读顺序依次启动、时间窗口相互重叠，形成一道柔和的“对焦前沿”在约 1.4 秒内扫过整句。消失时按相反顺序执行，最后的字最先消散。电影感、沉静而高级——如同苹果发布会的标题页。"
        ),
        implementation: L(
            "A custom Transition swaps in a TextRenderer whose animatable progress drives per-glyph opacity, blur filter and offset with a staggered window; the change runs in a linear withAnimation.",
            "自定义 Transition 注入一个 TextRenderer，其可动画的 progress 以错开的时间窗口驱动每个字形的透明度、模糊滤镜与位移；状态变化包裹在线性 withAnimation 中。"
        ),
        apis: ["TextRenderer", "Transition", "Animatable", "GraphicsContext.addFilter(.blur)"],
        tags: ["blur", "reveal", "focus", "stagger", "模糊", "显现", "逐字", "入场"],
        params: [
            .slider("duration", L("Duration", "时长"), 0.6...3, default: 1.4, unit: "s"),
            .slider("blur", L("Blur radius", "模糊半径"), 0...20, default: 10, decimals: 0, unit: "pt"),
            .slider("window", L("Per-glyph window", "单字时长占比"), 0.1...1, default: 0.35),
        ]
    ) { ctx in
        BlurRevealDemo(ctx: ctx)
    }
}

private struct BlurRevealDemo: View {
    let ctx: DemoContext
    @State private var visible: Bool
    @State private var index = 0

    init(ctx: DemoContext) {
        self.ctx = ctx
        // Still snapshots never run onAppear: show the revealed phrase.
        _visible = State(initialValue: ctx.isStill)
    }

    private var phrases: [String] {
        ctx.language == .zh
            ? ["每一个字，\n都经过精心雕琢。", "细节不是细节，\n它们就是设计。", "安静，\n但令人难忘。"]
            : ["Crafted with intention,\ndown to every glyph.", "The details are not details.\nThey make the design.", "Quiet, yet\nimpossible to forget."]
    }

    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                if visible {
                    Text(verbatim: phrases[index % phrases.count])
                        .font(.system(size: 28, weight: .semibold, design: .serif))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.primary)
                        .transition(BlurRevealTransition(blur: ctx["blur"], window: ctx["window"]))
                }
            }
            .frame(width: 310, height: 120)
            DemoHint(text: L("Tap to reveal / dismiss", "点击显现 / 隐藏"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { toggle() }
        // The detail stage reveals once in onAppear (also under Reduce Motion), so no intro play on top.
        .autoplay(ctx.isPreview, every: max(ctx["duration"], 0.6) + 1.2, delay: 0.2, intro: false) { toggle() }
        .onAppear {
            if !ctx.isPreview { toggle() }
        }
    }

    private func toggle() {
        if !visible { index += 1 }
        withAnimation(.linear(duration: ctx["duration"])) {
            visible.toggle()
        }
    }
}

private struct BlurRevealTransition: Transition {
    var blur: Double
    var window: Double

    func body(content: Content, phase: TransitionPhase) -> some View {
        content.textRenderer(
            BlurRevealRenderer(progress: phase.isIdentity ? 1 : 0, blur: blur, window: window)
        )
    }
}

private struct BlurRevealRenderer: TextRenderer {
    var progress: Double
    var blur: Double
    var window: Double

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func draw(layout: Text.Layout, in context: inout GraphicsContext) {
        var slices: [Text.Layout.RunSlice] = []
        for line in layout {
            for run in line {
                for slice in run {
                    slices.append(slice)
                }
            }
        }
        let count = slices.count
        let w = min(max(window, 0.05), 1)
        for (i, slice) in slices.enumerated() {
            let start = count > 1 ? Double(i) / Double(count - 1) * (1 - w) : 0
            let local = min(max((progress - start) / w, 0), 1)
            let eased = 1 - pow(1 - local, 3)
            var copy = context
            copy.opacity = eased
            if blur > 0 && eased < 1 {
                copy.addFilter(.blur(radius: CGFloat((1 - eased) * blur)))
            }
            copy.translateBy(x: 0, y: CGFloat((1 - eased) * 10))
            copy.draw(slice)
        }
    }
}
