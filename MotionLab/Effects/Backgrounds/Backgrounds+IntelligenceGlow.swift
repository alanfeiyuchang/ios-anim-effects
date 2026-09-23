import SwiftUI

extension Effect {
    static let backgroundsIntelligenceGlow = Effect(
        id: "backgrounds.intelligence-glow",
        category: .backgrounds,
        interaction: .tap,
        name: L("Intelligence Edge Glow", "智能边缘光"),
        summary: L(
            "A Siri-style iridescent glow flows around the screen edge — tap to make it think.",
            "Siri 风格的虹彩光晕沿屏幕边缘流转，点击让它进入思考状态。"
        ),
        prompt: L(
            "A dark, almost-black screen framed by a luminous, continuous-corner border of shifting colour — lavender, blush pink, periwinkle, coral and apricot. The border is four stacked angular-gradient strokes of increasing width and blur (crisp hairline, 5 pt, 14 pt and 28 pt blur), each rotating at its own rate and one in the opposite direction, so hues flow around the edge organically instead of spinning as a block; stroke width breathes on a ~3 s sine. Tapping switches to a listening/thinking state: over ~300 ms the glow eases to nearly double thickness and 2.5× flow speed while the centred prompt text cross-fades, with a light haptic. It feels intelligent, warm and alive — Apple Intelligence's signature presence.",
            "近乎全黑的屏幕，四周环绕一圈连续圆角、色彩不断流转的发光边框——薰衣草紫、腮红粉、长春花蓝、珊瑚红与杏色。边框由四层角向渐变描边叠加：从锐利细线到 5pt、14pt、28pt 模糊，逐层加宽加柔；每层以不同速率旋转，其中一层反向，使色彩沿边缘有机流动而非整体转圈，线宽按约 3 秒的正弦节奏呼吸。点击进入聆听/思考状态：光晕在约 300 毫秒内缓动到接近两倍粗细、流速提升至 2.5 倍，中央提示文字交叉淡入淡出，并伴随轻触觉反馈。整体聪慧、温暖、富有生命感，正是 Apple 智能的标志性存在感。"
        ),
        implementation: L(
            "TimelineView drives four RoundedRectangle.strokeBorder layers filled with rotating AngularGradients and progressively larger blurs, flattened with drawingGroup() so the blur passes run in one Metal render; a tiny model eases an energy value that scales width and speed.",
            "TimelineView 驱动四层 RoundedRectangle.strokeBorder，分别填充旋转的 AngularGradient 并施加逐级增大的模糊，再以 drawingGroup() 合并为一次 Metal 渲染；小型模型缓动能量值，用于放大线宽与流速。"
        ),
        apis: ["AngularGradient", "strokeBorder", "blur(radius:)", "TimelineView(.animation)", "contentTransition"],
        tags: ["siri", "apple intelligence", "glow", "edge", "光晕", "边缘光", "智能", "流光"],
        params: [
            .choice("style", L("Palette", "配色"), [L("Intelligence", "智能"), L("Siri", "Siri"), L("Ember", "余烬")]),
            .slider("speed", L("Flow speed", "流动速度"), 0.2...2.0, default: 0.8, unit: "×"),
            .slider("width", L("Thickness", "粗细"), 2...14, default: 6, decimals: 0, unit: "pt"),
        ]
    ) { ctx in
        IntelligenceGlowDemo(ctx: ctx)
    }
}

private enum GlowPalette {
    static func colors(_ index: Int) -> [Color] {
        let hexes: [UInt32]
        switch index {
        case 1:
            hexes = [0x2E6BFF, 0x00D4FF, 0x7A2BFF, 0xFF2E93, 0x2E6BFF]
        case 2:
            hexes = [0xFF7A45, 0xFFC247, 0xFF4D5E, 0xFF5FA2, 0xFF7A45]
        default:
            hexes = [0xBC82F3, 0xF5B9EA, 0x8D9FFF, 0xAA6EEE, 0xFF6778, 0xFFBA71, 0xC686FF, 0xBC82F3]
        }
        return hexes.map { Color(hex: $0) }
    }
}

private final class GlowModel {
    let clock = BackgroundClock()
    private(set) var energy: Double = 0

    func step(now: Double, speed: Double, active: Bool) -> Double {
        let t = clock.advance(to: now, speed: speed * (1 + energy * 1.5))
        energy += ((active ? 1 : 0) - energy) * clock.follow(rate: 7)
        return t
    }
}

private struct IntelligenceGlowDemo: View {
    let ctx: DemoContext
    @State private var model = GlowModel()
    @State private var active = false

    var body: some View {
        ZStack {
            Color(hex: 0x08080D)
            TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: ctx.isPreview))) { timeline in
                let t = model.step(now: timeline.date.timeIntervalSinceReferenceDate, speed: ctx["speed"], active: active)
                GlowRing(t: t, energy: model.energy, width: ctx.cg("width"), colors: GlowPalette.colors(ctx.int("style")))
            }
            prompt
        }
        .contentShape(Rectangle())
        .onTapGesture {
            Haptics.tap()
            toggle()
        }
        .autoplay(ctx.isPreview, every: 2.6) { toggle() }
        .backgroundsHint(L("Tap to start listening", "点击开始聆听"), ctx)
    }

    private var prompt: some View {
        VStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.system(size: 30, weight: .medium))
                .symbolEffect(.pulse, isActive: active)
            Text(active ? L("Thinking…", "思考中…") : L("Ask anything", "有什么可以帮你"), ctx.language)
                .font(.title3.weight(.semibold))
                .contentTransition(.opacity)
        }
        .foregroundStyle(.white.opacity(0.92))
        .allowsHitTesting(false)
    }

    private func toggle() {
        withAnimation(.smooth(duration: 0.3)) {
            active.toggle()
        }
    }
}

private struct GlowRing: View {
    let t: Double
    let energy: Double
    let width: CGFloat
    let colors: [Color]

    var body: some View {
        let w = width * CGFloat(1 + energy * 0.9 + 0.12 * sin(t * 2.1))
        ZStack {
            layer(lineWidth: w * 5, blur: 28, degrees: t * 40 + 200, opacity: 0.55 + 0.35 * energy)
            layer(lineWidth: w * 3, blur: 14, degrees: -t * 55 + 120, opacity: 0.8)
            layer(lineWidth: w * 1.4, blur: 5, degrees: t * 70 + 40, opacity: 0.9)
            layer(lineWidth: max(w * 0.5, 1.5), blur: 0, degrees: t * 90, opacity: 1)
        }
        // Flatten the four blurred strokes into one Metal-rendered layer each frame.
        .drawingGroup()
    }

    private func layer(lineWidth: CGFloat, blur: CGFloat, degrees: Double, opacity: Double) -> some View {
        RoundedRectangle(cornerRadius: 30, style: .continuous)
            .strokeBorder(
                AngularGradient(gradient: Gradient(colors: colors), center: .center, angle: .degrees(degrees)),
                lineWidth: lineWidth
            )
            .blur(radius: blur)
            .opacity(opacity)
    }
}
