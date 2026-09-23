import SwiftUI

extension Effect {
    static let morphBlindsReveal = Effect(
        id: "morph.blinds-reveal",
        category: .morph,
        interaction: .tap,
        name: L("Venetian Blinds", "百叶窗揭示"),
        summary: L(
            "The next scene opens through a row of slats that widen one after another like blinds.",
            "下一幕透过一排依次张开的百叶窗板条出现。"
        ),
        prompt: L(
            "A 260 × 300 pt scene card (dawn, day, night — each a gradient sky with a large SF Symbol and a title). A tap replaces it through nine horizontal slats: each slat of the incoming scene opens from a hairline at its own centre to full height, and the slats start in a top-to-bottom cascade that spreads their starts across the first half of the 0.9 s transition, on a strong ease-in-out (cubic-bezier 0.65, 0, 0.35, 1). Mid-way the card reads as alternating stripes of old and new; as the last slat closes the gap the new scene is whole. A toggle turns the slats vertical, sweeping left to right. Mechanical, graphic and crisp, like a stage shutter.",
            "一张 260 × 300pt 的场景卡片（黎明、白昼、夜晚，各为渐变天空加大号 SF Symbol 与标题）。点击后，新场景通过九条横向板条出现：每条板条从自身中线的一条细线张开到满高，各板条自上而下依次启动，启动时间分布在 0.9 秒过渡的前半段，曲线为强缓入缓出（cubic-bezier 0.65, 0, 0.35, 1）。过程中卡片呈现新旧交替的条纹，最后一条合拢后新场景完整呈现。可切换为竖向板条，由左向右扫过。机械、图形感强且干脆，像舞台上的百叶快门。"
        ),
        implementation: L(
            "An Animatable stage view receives a monotonically increasing step; its fractional part drives a Shape that adds one rect per slat with a staggered local progress, used as the mask of the incoming scene over the outgoing one.",
            "可动画的舞台视图接收单调递增的步进值，其小数部分驱动一个 Shape：按错峰后的局部进度为每条板条添加一个矩形，作为新场景的遮罩叠在旧场景之上。"
        ),
        apis: ["Animatable", "Shape", "mask", "timingCurve", "Path.addRect"],
        tags: ["blinds", "reveal", "wipe", "stripes", "百叶窗", "揭示", "擦除", "条纹"],
        params: [
            .slider("duration", L("Duration", "时长"), 0.4...1.6, default: 0.9, unit: "s"),
            .slider("spread", L("Cascade spread", "错峰范围"), 0.0...0.8, default: 0.5),
            .slider("slats", L("Slats", "板条数"), 4...14, default: 9, step: 1, decimals: 0),
            .toggle("vertical", L("Vertical slats", "竖向板条"), default: false),
        ]
    ) { ctx in
        BlindsRevealDemo(ctx: ctx)
    }
}

private struct BlindsScene {
    let title: LocalizedText
    let symbol: String
    let colors: [Color]
}

private let blindsScenes: [BlindsScene] = [
    BlindsScene(title: L("Dawn", "黎明"), symbol: "sunrise.fill", colors: [Color(hex: 0xFFB36B), Color(hex: 0xFF6B8B)]),
    BlindsScene(title: L("Day", "白昼"), symbol: "sun.max.fill", colors: [Color(hex: 0x3AC4FF), Color(hex: 0x4F7CFF)]),
    BlindsScene(title: L("Night", "夜晚"), symbol: "moon.stars.fill", colors: [Color(hex: 0x2B2F77), Color(hex: 0x141432)]),
]

private struct BlindsRevealDemo: View {
    let ctx: DemoContext
    @State private var step: Double = 0

    var body: some View {
        VStack(spacing: 18) {
            BlindsStage(
                step: step,
                slats: max(ctx.int("slats"), 2),
                spread: ctx["spread"],
                vertical: ctx.bool("vertical"),
                language: ctx.language
            )
            .frame(width: 260, height: 300)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .shadow(color: .black.opacity(0.18), radius: 18, y: 10)
            .onTapGesture { advance() }
            DemoHint(text: L("Tap the card", "点击卡片"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.7) { advance() }
    }

    private func advance() {
        if !ctx.isPreview { Haptics.tap(.soft) }
        withAnimation(.timingCurve(0.65, 0, 0.35, 1, duration: ctx["duration"])) {
            step += 1
        }
    }
}

/// Renders scene floor(step) underneath and scene floor(step) + 1 through the slat mask.
private struct BlindsStage: View, Animatable {
    var step: Double
    let slats: Int
    let spread: Double
    let vertical: Bool
    let language: AppLanguage

    var animatableData: Double {
        get { step }
        set { step = newValue }
    }

    var body: some View {
        let base: Double = max(step, 0).rounded(.down)
        let t: Double = max(step, 0) - base
        let count = blindsScenes.count
        let from = blindsScenes[Int(base) % count]
        let to = blindsScenes[(Int(base) + 1) % count]
        return ZStack {
            BlindsSceneView(scene: from, language: language)
            BlindsSceneView(scene: to, language: language)
                .mask {
                    SlatMask(progress: t, slats: slats, spread: spread, vertical: vertical)
                }
        }
    }
}

private struct BlindsSceneView: View {
    let scene: BlindsScene
    let language: AppLanguage

    var body: some View {
        ZStack {
            LinearGradient(colors: scene.colors, startPoint: .top, endPoint: .bottom)
            VStack(spacing: 14) {
                Image(systemName: scene.symbol)
                    .font(.system(size: 64, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                Text(scene.title, language)
                    .font(.title.weight(.bold))
            }
            .foregroundStyle(.white)
        }
    }
}

private struct SlatMask: Shape {
    let progress: Double
    let slats: Int
    let spread: Double
    let vertical: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let span: Double = max(1 - spread, 0.05)
        let length: CGFloat = vertical ? rect.width : rect.height
        let slat: CGFloat = length / CGFloat(slats)
        for i in 0..<slats {
            let start: Double = slats > 1 ? Double(i) / Double(slats - 1) * spread : 0
            let local: Double = min(max((progress - start) / span, 0), 1)
            let size: CGFloat = slat * CGFloat(local) + (local >= 1 ? 0.5 : 0)
            let origin: CGFloat = CGFloat(i) * slat + (slat - size) / 2
            if vertical {
                path.addRect(CGRect(x: rect.minX + origin, y: rect.minY, width: size, height: rect.height))
            } else {
                path.addRect(CGRect(x: rect.minX, y: rect.minY + origin, width: rect.width, height: size))
            }
        }
        return path
    }
}
