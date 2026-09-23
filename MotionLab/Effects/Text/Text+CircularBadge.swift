import SwiftUI

extension Effect {
    static let textCircularBadge = Effect(
        id: "text.circular-badge",
        category: .text,
        interaction: .loop,
        name: L("Orbiting Text Badge", "环形文字徽章"),
        summary: L("A ring of type slowly orbits a button; a tap whips it around a half turn.", "一圈文字缓缓环绕按钮旋转；点击后猛地甩过半圈。"),
        prompt: L(
            "A circular call-to-action: a 76 pt gradient disc with an arrow sits inside a ring of small, widely tracked caps set on a ~92 pt radius, each glyph rotated to follow the circle, with a hairline guide ring just inside. The ring orbits continuously at a calm ~24°/s. On tap the ring whips an extra half turn on a spring (response 0.8 s, damping 0.72) layered on top of the orbit, the disc squashes to 90% and rebounds, the arrow bounces, and a soft haptic lands. Editorial, playful and endlessly loopable — the kind of badge that invites a scroll or a click.",
            "一枚环形行动按钮：76 pt 的渐变圆盘中是一个箭头，外圈是一圈字距宽松的小号大写文字，排布在约 92 pt 的半径上，每个字形都沿圆周旋转，内侧有一道细线导轨。整圈文字以约 24°/秒的舒缓速度持续公转。点击时，文字环在公转之上叠加一段弹簧（响应 0.8 秒、阻尼 0.72）驱动的额外半圈甩动，圆盘压缩到 90% 再回弹，箭头弹跳一下，并伴随柔和触感。编辑感强、俏皮，且可无缝循环——一个邀请用户滚动或点击的徽章。"
        ),
        implementation: L(
            "Each character is offset up by the radius and then rotated by its share of 360°, so it pivots around the ring centre; a TimelineView supplies the orbit angle, and a separate animated @State rotation adds the tap spin on top.",
            "每个字符先向上偏移一个半径，再按其在 360° 中的份额旋转，从而绕环心排布；TimelineView 提供公转角度，另一个带动画的 @State 旋转在其之上叠加点击甩动。"
        ),
        apis: ["rotationEffect", "offset", "TimelineView(.animation)", "symbolEffect(.bounce)", "spring(response:dampingFraction:)"],
        tags: ["circular text", "badge", "orbit", "rotate", "ring", "环形文字", "徽章", "旋转", "圆形排版"],
        params: [
            .slider("speed", L("Orbit speed", "公转速度"), 0...90, default: 24, step: 1, decimals: 0, unit: "°/s"),
            .slider("radius", L("Radius", "半径"), 70...110, default: 92, step: 1, decimals: 0, unit: "pt"),
            .choice("direction", L("Direction", "方向"), [L("Clockwise", "顺时针"), L("Counter", "逆时针")], default: 0),
        ]
    ) { ctx in
        TextCircularBadgeDemo(ctx: ctx)
    }
}

private struct TextCircularBadgeDemo: View {
    let ctx: DemoContext
    @State private var spin: Double = 0
    @State private var taps = 0
    @State private var pressed = false

    private var phrase: String {
        ctx.language == .zh
            ? "动效词典 · 向下滚动 · 探索更多 · 精心打磨 · "
            : "MOTION LEXICON • SCROLL TO EXPLORE • "
    }

    var body: some View {
        let sign: Double = ctx.int("direction") == 0 ? 1 : -1
        let radius = ctx.cg("radius")
        ZStack {
            Circle()
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
                .frame(width: radius * 2 - 30, height: radius * 2 - 30)
            TimelineView(.animation) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                TextCircularRing(text: phrase, radius: radius, chinese: ctx.language == .zh)
                    .rotationEffect(.degrees((t * ctx["speed"]).truncatingRemainder(dividingBy: 360) * sign))
            }
            .rotationEffect(.degrees(spin * sign))
            disc
        }
        .frame(width: radius * 2 + 30, height: radius * 2 + 30)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 2.6) { tap() }
    }

    private var disc: some View {
        Button { tap() } label: {
            Image(systemName: "arrow.down")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(.white)
                .symbolEffect(.bounce.down, value: taps)
                .frame(width: 76, height: 76)
                .background(Palette.primary, in: Circle())
                .overlay(Circle().strokeBorder(Color.white.opacity(0.3), lineWidth: 1))
                .shadow(color: Palette.indigo.opacity(0.4), radius: 14, y: 8)
                .scaleEffect(pressed ? 0.9 : 1)
        }
        .buttonStyle(.plain)
    }

    private func tap() {
        if !ctx.isPreview { Haptics.tap(.soft) }
        taps += 1
        withAnimation(.spring(response: 0.8, dampingFraction: 0.72)) {
            spin += 180
        }
        withAnimation(.spring(response: 0.18, dampingFraction: 0.7)) { pressed = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.5)) { pressed = false }
        }
    }
}

private struct TextCircularRing: View {
    let text: String
    let radius: CGFloat
    let chinese: Bool

    var body: some View {
        let glyphs = Array(text)
        let step = 360 / Double(max(glyphs.count, 1))
        ZStack {
            ForEach(glyphs.indices, id: \.self) { i in
                Text(verbatim: String(glyphs[i]))
                    .font(.system(size: chinese ? 14 : 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    // Offset first, then rotate: rotation pivots around the ring centre (the layout frame).
                    .offset(y: -radius)
                    .rotationEffect(.degrees(Double(i) * step))
            }
        }
    }
}
