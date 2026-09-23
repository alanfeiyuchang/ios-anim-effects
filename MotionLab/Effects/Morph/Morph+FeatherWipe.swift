import SwiftUI

extension Effect {
    static let morphFeatherWipe = Effect(
        id: "morph.feather-wipe",
        category: .morph,
        interaction: .tap,
        name: L("Feathered Parallax Wipe", "羽化视差擦除"),
        summary: L(
            "A soft, slanted edge sweeps across while the new page glides in faster than the old one drifts away.",
            "一道柔和的斜向羽化边缘扫过，新页面滑入的速度快于旧页面退去的速度。"
        ),
        prompt: L(
            "A 260 × 300 pt article card. A tap wipes in the next card behind a 20°-slanted edge feathered by a ≈18 pt blur, travelling left to right over ≈0.8 s on an expo-out curve (cubic-bezier 0.16, 1, 0.3, 1): fast off the mark, gentle at the end. Two parallax layers sell the depth — the incoming card's content slides in from +60 pt to rest, while the outgoing card drifts only −24 pt and dims by 25%, so the new page seems to overtake the old one. The feather keeps the boundary glowing softly instead of drawing a hard line. Editorial, cinematic and calm.",
            "一张 260 × 300pt 的文章卡片。点击后，下一张卡片在一道倾斜 20°、以约 18pt 模糊羽化的边缘后方擦入，边缘在约 0.8 秒内自左向右扫过，曲线为 expo 缓出（cubic-bezier 0.16, 1, 0.3, 1）：起步迅猛、收尾轻柔。两层视差营造纵深：新卡片的内容从 +60pt 滑到原位，旧卡片只向左漂移 24pt 并变暗 25%，看起来就像新页面追上并越过了旧页面。羽化让交界处呈现柔和的过渡而非生硬的线条。杂志感、电影感、沉静。"
        ),
        implementation: L(
            "An Animatable stage view splits a monotonically increasing step into scene indices and a fraction; the fraction positions a rotated, blurred Rectangle used as the incoming layer's mask and drives both layers' offsets.",
            "可动画的舞台视图把单调递增的步进值拆成场景序号与小数进度；小数进度决定旋转并模糊后的 Rectangle 遮罩位置，同时驱动新旧两层的位移。"
        ),
        apis: ["Animatable", "mask", "blur(radius:)", "rotationEffect", "timingCurve"],
        tags: ["wipe", "parallax", "feather", "page transition", "擦除", "视差", "羽化", "页面转场"],
        params: [
            .slider("duration", L("Duration", "时长"), 0.4...1.6, default: 0.8, unit: "s"),
            .slider("feather", L("Feather", "羽化"), 0...40, default: 18, decimals: 0, unit: "pt"),
            .slider("angle", L("Edge angle", "边缘角度"), 0...40, default: 20, decimals: 0, unit: "°"),
            .slider("parallax", L("Parallax", "视差"), 0...100, default: 60, decimals: 0, unit: "pt"),
        ]
    ) { ctx in
        FeatherWipeDemo(ctx: ctx)
    }
}

private struct WipeArticle {
    let kicker: LocalizedText
    let title: LocalizedText
    let symbol: String
    let tint: Color
}

private let wipeArticles: [WipeArticle] = [
    WipeArticle(kicker: L("Design", "设计"), title: L("The quiet power of springs", "弹簧曲线的静默力量"), symbol: "waveform.path", tint: Palette.violet),
    WipeArticle(kicker: L("Travel", "旅行"), title: L("Twelve hours in Kyoto", "京都十二小时"), symbol: "tram.fill", tint: Palette.coral),
    WipeArticle(kicker: L("Science", "科学"), title: L("Why the sky turns violet", "天空为何会变紫"), symbol: "sparkles", tint: Palette.mint),
]

private struct FeatherWipeDemo: View {
    let ctx: DemoContext
    @State private var step: Double = 0

    var body: some View {
        VStack(spacing: 18) {
            FeatherStage(
                step: step,
                feather: ctx.cg("feather"),
                angle: ctx["angle"],
                parallax: ctx.cg("parallax"),
                language: ctx.language
            )
            .frame(width: 260, height: 300)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).strokeBorder(Palette.stroke))
            .shadow(color: .black.opacity(0.15), radius: 18, y: 10)
            .onTapGesture { advance() }
            DemoHint(text: L("Tap the card", "点击卡片"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.6) { advance() }
    }

    private func advance() {
        if !ctx.isPreview { Haptics.tap(.soft) }
        withAnimation(.timingCurve(0.16, 1, 0.3, 1, duration: ctx["duration"])) {
            step += 1
        }
    }
}

private struct FeatherStage: View, Animatable {
    var step: Double
    let feather: CGFloat
    let angle: Double
    let parallax: CGFloat
    let language: AppLanguage

    var animatableData: Double {
        get { step }
        set { step = newValue }
    }

    private let width: CGFloat = 260
    private let height: CGFloat = 300

    var body: some View {
        let base: Double = max(step, 0).rounded(.down)
        let t = CGFloat(min(max(max(step, 0) - base, 0), 1))
        let count = wipeArticles.count
        let from = wipeArticles[Int(base) % count]
        let to = wipeArticles[(Int(base) + 1) % count]
        let margin: CGFloat = 90 + feather * 2
        let edge: CGFloat = -width / 2 - margin + t * (width + margin * 2)
        let maskWidth: CGFloat = width * 2
        return ZStack {
            ZStack {
                Palette.elevated
                WipeCard(article: from, language: language)
                    .offset(x: -24 * t)
            }
            .brightness(-0.25 * Double(t))
            ZStack {
                Palette.elevated
                WipeCard(article: to, language: language)
                    .offset(x: parallax * (1 - t))
            }
            .mask {
                Rectangle()
                    .frame(width: maskWidth, height: height * 3)
                    .rotationEffect(.degrees(angle))
                    .offset(x: edge - maskWidth / 2)
                    .blur(radius: feather)
                    .frame(width: width, height: height)
            }
        }
        .frame(width: width, height: height)
    }
}

private struct WipeCard: View {
    let article: WipeArticle
    let language: AppLanguage

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(article.tint.gradient)
                .frame(height: 130)
                .overlay {
                    Image(systemName: article.symbol)
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundStyle(.white)
                }
            Text(article.kicker, language)
                .font(.caption.weight(.bold))
                .textCase(.uppercase)
                .foregroundStyle(article.tint)
            Text(article.title, language)
                .font(.title3.weight(.bold))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
            PlaceholderLines(count: 2)
        }
        .padding(16)
        .frame(width: 260, height: 300, alignment: .top)
    }
}
