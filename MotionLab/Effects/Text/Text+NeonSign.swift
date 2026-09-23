import SwiftUI

extension Effect {
    static let textNeonSign = Effect(
        id: "text.neon-sign",
        category: .text,
        interaction: .tap,
        name: L("Neon Power-On", "霓虹灯通电"),
        summary: L("Tubes stutter to life letter by letter; one faulty letter keeps buzzing.", "灯管逐字闪烁着亮起，其中一个坏字不时抽动。"),
        prompt: L(
            "A dark sign panel carries two neon lines, a large pink word and a smaller sky-blue sub-line; each letter is a pale tube core wrapped in three stacked glows (4, 12 and 28 pt), and unlit tubes stay faintly visible at 18%. On power-on every letter runs the same stutter (off 80 ms, flash to 90%, drop to 10%, full, sag to 25%, 80%, 15%) and holds at 100% after 0.46 s, but letters start 70 ms apart so ignition crackles across the word, with the sub-line 250 ms behind. A soft pink bloom on the panel brightens with the tubes, and once lit one faulty letter dips for a few frames every 1.4 s. A tap cuts the power and restarts it with a rigid haptic. Moody, nocturnal and cinematic.",
            "深色灯牌上有两行霓虹字：大号粉色单词和较小的天蓝色副标题；每个字母是一根浅色灯芯，外裹三层叠加辉光（4、12、28 pt），未点亮的灯管保留18%的微弱轮廓。通电时每个字母都走同一段抽动：先灭80毫秒，闪到90%，跌到10%，全亮，再塌到25%、80%、15%，0.46秒后稳定在100%；字母之间错开70毫秒，点火沿单词噼啪蔓延，副标题再晚250毫秒。背板粉色柔光随灯管亮起，点亮后有一个坏字母每隔1.4秒闪暗几帧。轻点即断电重启，伴随清脆触感。电影感十足。"
        ),
        implementation: L(
            "A TimelineView evaluates a piecewise flicker table per letter from the time since power-on (offset by the letter's stagger); the value drives the opacity of a lit layer with three shadow glows stacked over a dim tube layer.",
            "TimelineView 根据自通电以来的时间（再减去每个字母的错开量）逐字查询分段闪烁表；得到的数值驱动亮层的透明度，亮层带三层阴影辉光，叠在暗淡的灯管层之上。"
        ),
        apis: ["TimelineView", "shadow(color:radius:)", "opacity", "RadialGradient"],
        tags: ["neon", "flicker", "glow", "sign", "霓虹", "闪烁", "辉光", "灯牌"],
        params: [
            .slider("stagger", L("Letter stagger", "逐字错开"), 0...0.2, default: 0.07, unit: "s"),
            .slider("glow", L("Glow radius", "辉光半径"), 0.3...2.0, default: 1.0, unit: "×"),
            .toggle("faulty", L("Faulty letter", "坏字抽动"), default: true),
        ]
    ) { ctx in
        NeonSignDemo(ctx: ctx)
    }
}

/// (end time, brightness) segments of the power-on stutter.
private let neonFlicker: [(end: Double, level: Double)] = [
    (0.08, 0), (0.12, 0.9), (0.20, 0.1), (0.24, 1), (0.34, 0.25), (0.38, 0.8), (0.46, 0.15),
]

private func neonLevel(_ t: Double) -> Double {
    guard t >= 0 else { return 0 }
    for segment in neonFlicker where t < segment.end {
        return segment.level
    }
    return 1
}

private struct NeonSignDemo: View {
    let ctx: DemoContext
    @State private var poweredAt = Date.distantPast

    private var title: [String] { (ctx.language == .zh ? "深夜食堂" : "OPEN").map { String($0) } }
    private var subtitle: [String] { (ctx.language == .zh ? "营业至凌晨三点" : "late night noodles").map { String($0) } }

    var body: some View {
        VStack(spacing: 16) {
            TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: ctx.isPreview))) { timeline in
                let since: Double = timeline.date.timeIntervalSince(poweredAt)
                let clock: Double = timeline.date.timeIntervalSinceReferenceDate
                panel(since: since, clock: clock)
            }
            DemoHint(text: L("Tap to flip the switch", "点击开关电源"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { repower() }
        .autoplay(ctx.isPreview, every: 4.0, delay: 0.2) { repower() }
    }

    private func panel(since: Double, clock: Double) -> some View {
        let bloom: Double = neonLevel(since - 0.1)
        return VStack(spacing: 10) {
            line(title, since: since, clock: clock, color: Palette.pink, size: ctx.language == .zh ? 50 : 70, lead: 0)
            line(subtitle, since: since, clock: clock, color: Palette.sky, size: 20, lead: 0.25)
        }
        .padding(.horizontal, 26)
        .padding(.vertical, 24)
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: 26, style: .continuous).fill(Color(white: 0.06))
                RadialGradient(colors: [Palette.pink.opacity(0.28 * bloom), .clear], center: .center, startRadius: 10, endRadius: 170)
            }
        }
        .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous).strokeBorder(.white.opacity(0.07)))
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        // Flatten the panel: up to 21 glyphs × 3 glow shadows would otherwise be blurred separately every frame.
        // The panel already clips to its shape, so the offscreen pass changes nothing visually.
        .drawingGroup()
        .shadow(color: .black.opacity(0.3), radius: 18, y: 10)
    }

    private func line(_ chars: [String], since: Double, clock: Double, color: Color, size: CGFloat, lead: Double) -> some View {
        HStack(spacing: 1) {
            ForEach(chars.indices, id: \.self) { index in
                NeonGlyph(
                    char: chars[index],
                    level: level(index: index, since: since, clock: clock, lead: lead, faultyLine: lead == 0),
                    color: color,
                    size: size,
                    glow: ctx.cg("glow")
                )
            }
        }
        .fixedSize()
    }

    private func level(index: Int, since: Double, clock: Double, lead: Double, faultyLine: Bool) -> Double {
        let local: Double = since - lead - Double(index) * ctx["stagger"]
        let base: Double = neonLevel(local)
        guard ctx.bool("faulty"), faultyLine, index == 1, local > 0.6 else { return base }
        let cycle: Double = clock.truncatingRemainder(dividingBy: 1.4)
        if cycle < 0.05 { return 0.2 }
        if cycle > 0.09 && cycle < 0.12 { return 0.35 }
        return base
    }

    private func repower() {
        Haptics.tap(.rigid)
        poweredAt = Date()
    }
}

private struct NeonGlyph: View {
    let char: String
    let level: Double
    let color: Color
    let size: CGFloat
    let glow: CGFloat

    var body: some View {
        ZStack {
            Text(verbatim: char)
                .foregroundStyle(color.opacity(0.18))
            Text(verbatim: char)
                .foregroundStyle(Color.white.opacity(0.9))
                .shadow(color: color, radius: 4 * glow)
                .shadow(color: color.opacity(0.8), radius: 12 * glow)
                .shadow(color: color.opacity(0.5), radius: 28 * glow)
                .opacity(level)
        }
        .font(.system(size: size, weight: .semibold, design: .rounded))
    }
}
