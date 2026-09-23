import SwiftUI

extension Effect {
    static let textShimmer = Effect(
        id: "text.shimmer",
        category: .text,
        interaction: .loop,
        name: L("Shimmer Text", "流光文字"),
        summary: L("A soft band of light sweeps across the letters.", "一道柔光带从文字上缓缓扫过。"),
        prompt: L(
            "Dimmed text — a headline such as \"Thinking…\" and a \"slide to unlock\" pill — is lit by a soft diagonal band of light that sweeps from left to right inside the glyphs only. The letters rest at about 30% opacity of the primary colour; the band ramps to full brightness at its centre and fades out on both sides, crossing the word about every 2.2 s on a continuous linear loop with no visible reset. In the aurora variant the band carries a violet-pink-amber gradient. It reads as a calm, intelligent \"working\" state rather than a loading spinner.",
            "处于弱化状态的文字——如“思考中…”标题与“滑动来解锁”胶囊——被一道柔和的斜向光带照亮，光只在字形内部从左向右扫过。文字静止时约为主色 30% 的不透明度；光带中心提亮到 100%，两侧渐隐，以约 2.2 秒一轮的匀速连续循环穿过文字，不留任何重置痕迹。极光变体中光带带有紫—粉—琥珀的渐变色。整体传达的是冷静、智能的“正在处理”状态，而非生硬的加载转圈。"
        ),
        implementation: L(
            "The text's foregroundStyle is a LinearGradient whose start/end UnitPoints travel across (and beyond) the text bounds, driven by TimelineView(.animation).",
            "文字的 foregroundStyle 是一个 LinearGradient，其起止 UnitPoint 在 TimelineView(.animation) 驱动下横穿（并越过）文字边界。"
        ),
        apis: ["LinearGradient", "UnitPoint", "TimelineView(.animation)", "foregroundStyle"],
        tags: ["shimmer", "shine", "gloss", "slide to unlock", "流光", "扫光", "闪光", "滑动解锁"],
        params: [
            .slider("speed", L("Speed", "速度"), 0.3...2.5, default: 1.0),
            .slider("band", L("Band width", "光带宽度"), 0.08...0.5, default: 0.2),
            .choice("style", L("Style", "风格"), [L("Mono", "单色"), L("Aurora", "极光")], default: 0),
        ]
    ) { ctx in
        ShimmerDemo(ctx: ctx)
    }
}

private struct ShimmerDemo: View {
    let ctx: DemoContext

    var body: some View {
        VStack(spacing: 34) {
            HStack(spacing: 10) {
                Image(systemName: "sparkle")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Palette.primary)
                    .symbolEffect(.pulse, isActive: true)
                ShimmerText(
                    text: ctx.language == .zh ? "思考中…" : "Thinking…",
                    font: .system(size: 34, weight: .semibold, design: .rounded),
                    ctx: ctx
                )
            }
            unlockPill
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var unlockPill: some View {
        HStack(spacing: 14) {
            Image(systemName: "chevron.right.2")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 52, height: 52)
                .background(Palette.primary, in: Circle())
            ShimmerText(
                text: ctx.language == .zh ? "滑动来解锁" : "slide to unlock",
                font: .system(size: 20, weight: .medium),
                ctx: ctx
            )
            Spacer(minLength: 0)
        }
        .padding(6)
        .frame(width: 280)
        .background(.regularMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(Palette.stroke))
    }
}

private struct ShimmerText: View {
    let text: String
    let font: Font
    let ctx: DemoContext

    var body: some View {
        TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: ctx.isPreview))) { timeline in
            Text(verbatim: text)
                .font(font)
                .foregroundStyle(gradient(at: timeline.date))
        }
    }

    private func gradient(at date: Date) -> LinearGradient {
        let band = ctx["band"]
        let period = 2.2 / max(ctx["speed"], 0.05)
        let t = date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: period) / period
        let center = -band + t * (1 + band * 2)
        return LinearGradient(
            colors: colors,
            startPoint: UnitPoint(x: center - band, y: 0.2),
            endPoint: UnitPoint(x: center + band, y: 0.8)
        )
    }

    private var colors: [Color] {
        let dim = Color.primary.opacity(0.28)
        if ctx.int("style") == 1 {
            return [dim, Palette.violet, Palette.pink, Palette.amber, dim]
        }
        return [dim, Color.primary, dim]
    }
}
