import SwiftUI

extension Effect {
    static let iconsRippleGrid = Effect(
        id: "icons.ripple-grid",
        category: .icons,
        interaction: .tap,
        name: L("Symbol Ripple Grid", "符号涟漪矩阵"),
        summary: L("A wave of symbol effects spreads out from the tapped icon.", "从点击的图标开始，一圈符号动效向外扩散。"),
        prompt: L(
            "A 4×4 gallery of colourful hierarchical SF Symbols on soft tinted tiles. Tapping one tile sends a ripple across the grid: each symbol fires a discrete effect (bounce, wiggle or rotate) after a delay proportional to its distance from the origin (~70 ms per tile), while its tile flashes a brighter tint and scales to 108% and back. The wavefront reads as a clean circle expanding outwards, crossing the whole grid in about 0.3 s, like a pebble dropped into a pond of icons, with a single light haptic at the source. Playful, orchestrated and systemic.",
            "4×4的彩色分层SF Symbol画廊，每个图标置于柔和的淡色方块上。点击任意方块，一圈涟漪便在矩阵中扩散：每个符号按与起点的距离延迟触发一次离散动效（弹跳、摇摆或旋转，约每格70毫秒），同时所在方块的底色短暂提亮并缩放到108%再回落。波前呈一个干净的圆形向外扩张，约0.3秒即可扫过整个矩阵，像一颗石子落入由图标组成的池塘，起点处伴随一次轻触感。俏皮、编排精致、充满系统感。"
        ),
        implementation: L(
            "Each cell owns a trigger counter; one stored Task per wave walks the cells sorted by distance and increments each after distance × stagger; the symbol uses .symbolEffect(_:value:) and the tile pulse is a keyframeAnimator on the same trigger.",
            "每个单元持有一个触发计数；每道波纹由一个保存的 Task 按距离排序依次在（距离 × 错开）时刻递增；符号使用 .symbolEffect(_:value:)，方块脉冲是绑定同一触发器的 keyframeAnimator。"
        ),
        apis: ["symbolEffect(_:options:value:)", "keyframeAnimator", "LazyVGrid", "Task.sleep(for:)"],
        tags: ["ripple", "grid", "wave", "stagger", "sf symbols", "涟漪", "矩阵", "波纹", "错开"],
        params: [
            .slider("stagger", L("Stagger per tile", "每格延迟"), 0.02...0.2, default: 0.07, unit: "s"),
            .choice("effect", L("Effect", "效果"), [L("Bounce", "弹跳"), L("Wiggle", "摇摆"), L("Rotate", "旋转")], default: 0),
        ]
    ) { ctx in
        RippleGridDemo(ctx: ctx)
    }
}

private struct RippleGridDemo: View {
    let ctx: DemoContext
    @State private var triggers = Array(repeating: 0, count: 16)
    /// The running wave: one Task walks the cells in distance order. A new tap replaces it
    /// (its wavefront re-covers the grid anyway), and leaving the screen cancels it.
    @State private var wave: Task<Void, Never>?

    private let symbols = [
        "heart.fill", "star.fill", "bolt.fill", "flame.fill",
        "leaf.fill", "moon.stars.fill", "cloud.sun.fill", "drop.fill",
        "bell.fill", "camera.fill", "music.note", "paperplane.fill",
        "gift.fill", "sparkles", "globe.americas.fill", "headphones",
    ]

    var body: some View {
        VStack(spacing: 16) {
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(58), spacing: 12), count: 4), spacing: 12) {
                ForEach(0..<16, id: \.self) { i in
                    RippleCell(
                        symbol: symbols[i],
                        tint: Palette.spectrum[(i + i / 4) % Palette.spectrum.count],
                        trigger: triggers[i],
                        effect: ctx.int("effect")
                    )
                    .onTapGesture { ripple(from: i) }
                }
            }
            DemoHint(text: L("Tap any symbol", "点击任意符号"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.8, delay: 0.3) { ripple(from: Int.random(in: 0..<16)) }
        .onDisappear {
            wave?.cancel()
            wave = nil
        }
    }

    private func ripple(from origin: Int) {
        let stagger = ctx["stagger"]
        let ox = Double(origin % 4)
        let oy = Double(origin / 4)
        if !ctx.isPreview { Haptics.tap(.light) }
        let schedule: [(cell: Int, delay: Double)] = (0..<16).map { i in
            let dx = Double(i % 4) - ox
            let dy = Double(i / 4) - oy
            return (i, (dx * dx + dy * dy).squareRoot() * stagger)
        }.sorted { $0.delay < $1.delay }
        wave?.cancel()
        wave = Task { @MainActor in
            var elapsed: Double = 0
            for step in schedule {
                let wait = step.delay - elapsed
                if wait > 0.001 {
                    try? await Task.sleep(for: .seconds(wait))
                    elapsed = step.delay
                }
                guard !Task.isCancelled else { return }
                triggers[step.cell] += 1
            }
        }
    }
}

private struct RippleCell: View {
    let symbol: String
    let tint: Color
    let trigger: Int
    let effect: Int

    var body: some View {
        glyph
            .font(.system(size: 26, weight: .semibold))
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(tint)
            .frame(width: 58, height: 58)
            .keyframeAnimator(initialValue: 0.0, trigger: trigger) { content, pulse in
                content
                    .background(tint.opacity(0.12 + pulse * 0.2), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .scaleEffect(CGFloat(1 + pulse * 0.08))
            } keyframes: { _ in
                KeyframeTrack(\Double.self) {
                    CubicKeyframe(1.0, duration: 0.12)
                    CubicKeyframe(0.0, duration: 0.4)
                }
            }
    }

    @ViewBuilder
    private var glyph: some View {
        let image = Image(systemName: symbol)
        switch effect {
        case 1:
            image.symbolEffect(.wiggle, value: trigger)
        case 2:
            image.symbolEffect(.rotate, value: trigger)
        default:
            image.symbolEffect(.bounce, value: trigger)
        }
    }
}
