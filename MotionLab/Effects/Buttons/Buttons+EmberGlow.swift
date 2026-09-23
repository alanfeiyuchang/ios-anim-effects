import SwiftUI

extension Effect {
    static let buttonsEmberGlow = Effect(
        id: "buttons.ember-glow",
        category: .buttons,
        interaction: .loop,
        name: L("Ember Sparks", "余烬火花"),
        summary: L("Glowing embers drift up off a warm button; a tap stokes the fire.", "发光的余烬从暖色按钮上方飘起，点击会让火势更旺。"),
        prompt: L(
            "On a dark ember-tinted panel sits a 220 × 60 pt charcoal capsule \"Go live\" with a 1.5 pt amber-to-coral rim. A steady stream of ~24 tiny embers (2–4 pt) rises from its top edge: each drifts up ~100 pt over 1.6–2.6 s along a gentle sine sway, shrinks as it cools from pale amber to coral and fades out, blended additively so overlaps flare. The rim glow flickers softly with layered noise (radius 12 ± 4 pt). A tap stokes the fire: for ~0.8 s the plume climbs 40% higher and burns brighter, the glow swells, the button dips to 96% and a medium haptic fires. Warm, alive and a little dangerous — perfect for live or hot-deal CTAs.",
            "余烬色调的深色面板上，一枚 220 × 60pt 的炭黑胶囊“开始直播”，外沿是 1.5pt 琥珀到珊瑚色描边。约 24 颗 2–4pt 的余烬持续从顶边升起：每颗在 1.6–2.6 秒内沿正弦摆动上升约 100pt，冷却时由浅琥珀变珊瑚色、逐渐缩小淡出，叠加混合让重叠处更亮。描边辉光随叠加噪声轻轻闪烁（半径 12 ± 4pt）。点击即“添柴”：约 0.8 秒内火苗蹿高 40%、更亮，辉光膨胀，按钮下沉到 96% 并伴随中等触感。温暖、鲜活，带点危险气息。"
        ),
        implementation: L(
            "A TimelineView(.animation) redraws a Canvas each frame; every ember derives its life phase, sway and colour from its seeded index and the time, drawn with plusLighter blending. The last tap time feeds a decaying boost that scales plume height and brightness.",
            "TimelineView(.animation) 每帧重绘 Canvas；每颗余烬根据带种子的序号与时间推算生命周期、摆动与颜色，并以 plusLighter 混合绘制。最近一次点击时间转换为逐渐衰减的增益，放大上升高度与亮度。"
        ),
        apis: ["TimelineView", "Canvas", "GraphicsContext.blendMode", "keyframeAnimator", "shadow"],
        tags: ["ember", "fire", "particles", "glow", "火花", "余烬", "粒子", "辉光"],
        params: [
            .slider("count", L("Ember count", "余烬数量"), 8...40, default: 24, step: 1, decimals: 0),
            .slider("rise", L("Rise height", "上升高度"), 60...140, default: 100, decimals: 0, unit: "pt"),
            .slider("heat", L("Heat", "热度"), 0.3...1.0, default: 0.7),
        ]
    ) { ctx in
        ButtonEmberGlowDemo(ctx: ctx)
    }
}

private struct ButtonEmberGlowDemo: View {
    let ctx: DemoContext
    @State private var lastStoke = Date.distantPast
    @State private var stokes = 0

    private let buttonSize = CGSize(width: 220, height: 60)
    private let canvasSize = CGSize(width: 300, height: 250)

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            stage
            Spacer()
            DemoHint(text: L("Tap to stoke the embers", "点击让火花更旺"), ctx: ctx)
                .padding(.bottom, 18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 2.6, delay: 1.0) { stoke() }
    }

    private var stage: some View {
        TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: ctx.isPreview))) { timeline in
            let now = timeline.date
            let age = now.timeIntervalSince(lastStoke)
            let boost = max(0, 1 - age / 0.8)
            let t = now.timeIntervalSinceReferenceDate
            ZStack(alignment: .bottom) {
                ButtonEmberField(
                    time: t,
                    boost: boost,
                    count: ctx.int("count"),
                    rise: ctx.cg("rise"),
                    heat: ctx["heat"],
                    emitterWidth: buttonSize.width - 30,
                    emitterY: canvasSize.height - 40 - buttonSize.height
                )
                .frame(width: canvasSize.width, height: canvasSize.height)
                button(time: t, boost: boost)
                    .padding(.bottom, 40)
            }
            .frame(width: canvasSize.width, height: canvasSize.height)
        }
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(LinearGradient(colors: [Color(hex: 0x1A1210), Color(hex: 0x0D0A09)], startPoint: .top, endPoint: .bottom))
        )
    }

    private func button(time: Double, boost: Double) -> some View {
        let fast: Double = sin(time * 23.7) * 0.3
        let flicker: Double = sin(time * 9.1) * 0.5 + fast + sin(time * 4.3) * 0.2
        let heat = ctx["heat"]
        let glowRadius = CGFloat(12 + 4 * flicker + 10 * boost)
        let glowOpacity: Double = (0.35 + 0.2 * boost) * heat + 0.1
        return Button(action: stoke) {
            HStack(spacing: 8) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(LinearGradient(colors: [Palette.amber, Palette.coral], startPoint: .top, endPoint: .bottom))
                Text(ctx.language == .zh ? "开始直播" : "Go live")
                    .foregroundStyle(Color.white)
            }
            .font(.headline)
            .frame(width: buttonSize.width, height: buttonSize.height)
            .background(Color(hex: 0x1E1715), in: Capsule())
            .overlay(
                Capsule().strokeBorder(
                    LinearGradient(colors: [Palette.amber, Palette.coral], startPoint: .top, endPoint: .bottom),
                    lineWidth: 1.5
                )
            )
            .shadow(color: Palette.coral.opacity(glowOpacity), radius: glowRadius)
            .keyframeAnimator(initialValue: CGFloat(1), trigger: stokes) { content, scale in
                content.scaleEffect(scale)
            } keyframes: { _ in
                KeyframeTrack(\.self) {
                    CubicKeyframe(0.96, duration: 0.08)
                    SpringKeyframe(1, duration: 0.45, spring: .bouncy)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func stoke() {
        lastStoke = Date()
        stokes += 1
        Haptics.tap(.medium)
    }
}

private struct ButtonEmberField: View {
    let time: Double
    let boost: Double
    let count: Int
    let rise: CGFloat
    let heat: Double
    let emitterWidth: CGFloat
    let emitterY: CGFloat

    var body: some View {
        Canvas { context, size in
            context.blendMode = .plusLighter
            let total = max(count, 1)
            for index in 0..<total {
                drawEmber(index, in: &context, size: size)
            }
        }
        .allowsHitTesting(false)
    }

    private func noise(_ index: Int, _ channel: Double) -> Double {
        let n = sin(Double(index) * 12.9898 + channel * 78.233) * 43758.5453
        return n - n.rounded(.down)
    }

    private func drawEmber(_ index: Int, in context: inout GraphicsContext, size: CGSize) {
        let period = 1.6 + noise(index, 1) * 1.0
        let shifted = time + noise(index, 2) * period
        let life = shifted.truncatingRemainder(dividingBy: period) / period
        let startX = size.width / 2 + CGFloat(noise(index, 3) - 0.5) * emitterWidth
        let sway = CGFloat(sin(time * 2.2 + Double(index))) * 8 * CGFloat(life)
        let x = startX + sway
        // A stoke lifts the plume higher instead of changing speed, so the phase never jumps.
        let lift: CGFloat = rise * CGFloat(1 + 0.4 * boost)
        let y = emitterY - lift * CGFloat(life)
        let radius: CGFloat = CGFloat(1 + noise(index, 4) * 1.5) * CGFloat(1.2 - 0.7 * life)
        let warmth: Double = 0.55 + 0.45 * heat
        let alpha: Double = (1 - life) * warmth * (0.7 + 0.3 * boost)
        let rect = CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)
        context.fill(Path(ellipseIn: rect.insetBy(dx: -radius, dy: -radius)), with: .color(Self.coolDown(life, opacity: alpha * 0.25)))
        context.fill(Path(ellipseIn: rect), with: .color(Self.coolDown(life, opacity: alpha)))
    }

    /// Ember colour over its life: amber (#FFC247) blending smoothly to coral (#FF7A5C) between 20 % and 70 %.
    private static func coolDown(_ life: Double, opacity: Double) -> Color {
        let x: Double = ((life - 0.2) / 0.5).clamped(to: 0...1)
        let t: Double = x * x * (3 - 2 * x)
        let green: Double = (194 + (122 - 194) * t) / 255
        let blue: Double = (71 + (92 - 71) * t) / 255
        return Color(.sRGB, red: 1, green: green, blue: blue, opacity: opacity)
    }
}
