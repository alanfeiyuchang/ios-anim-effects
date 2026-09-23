import SwiftUI

extension Effect {
    static let buttonsShimmer = Effect(
        id: "buttons.shimmer",
        category: .buttons,
        interaction: .loop,
        name: L("Shimmer Sweep", "流光扫过"),
        summary: L("A diagonal band of light glides across a premium CTA.", "一道斜向光带周期性掠过高级感主按钮。"),
        prompt: L(
            "A deep midnight-indigo capsule call-to-action with a crown glyph and a thin inner hairline. Every couple of seconds a narrow, soft-edged band of white light tilted about 20° sweeps from the left edge to the right in ~1.1 s on an ease-in-out curve, then rests for ~1.2 s before the next pass. The band blends additively (plus-lighter) so it brightens the gradient and the label instead of washing them out, and it is clipped to the capsule. The border hairline catches the light as the band passes. The effect feels like polished glass or foil — premium, inviting, never noisy.",
            "深午夜靛蓝色胶囊主按钮，带皇冠图标与一圈细内描边。每隔一两秒，一条约 20° 倾斜、边缘柔和的窄白光带以缓入缓出曲线在约 1.1 秒内从左扫到右，随后静止约 1.2 秒再进行下一次。光带使用叠加提亮（plus-lighter）混合，只提亮渐变与文字而不会发灰，并被裁切在胶囊内；扫过时描边也随之闪亮。质感如抛光玻璃或烫金箔片，高级、诱人又克制。"
        ),
        implementation: L(
            "A TimelineView(.animation) derives the sweep phase from the clock (sweep + pause cycle), eases it and offsets a rotated gradient band masked to the capsule with a plusLighter blend mode.",
            "TimelineView(.animation) 根据时钟计算扫光相位（扫过 + 停顿为一个周期），经缓动后驱动旋转渐变光带的 offset，裁切到胶囊内并使用 plusLighter 混合模式。"
        ),
        apis: ["TimelineView", "LinearGradient", "blendMode(.plusLighter)", "clipShape"],
        tags: ["shimmer", "shine", "sweep", "glare", "流光", "扫光", "高光", "光泽"],
        params: [
            .slider("duration", L("Sweep duration", "扫光时长"), 0.5...2.5, default: 1.1, unit: "s"),
            .slider("pause", L("Pause between", "间隔停顿"), 0.0...3.0, default: 1.2, unit: "s"),
            .slider("width", L("Band width", "光带宽度"), 20...120, default: 56, decimals: 0, unit: "pt"),
            .slider("intensity", L("Intensity", "亮度"), 0.2...1.0, default: 0.6),
        ]
    ) { ctx in
        ButtonShimmerDemo(ctx: ctx)
    }
}

private struct ButtonShimmerDemo: View {
    let ctx: DemoContext
    private let size = CGSize(width: 240, height: 62)

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            Button {
                Haptics.tap(.medium)
            } label: {
                TimelineView(.animation) { timeline in
                    ButtonShimmerFace(
                        progress: progress(at: timeline.date),
                        size: size,
                        bandWidth: ctx.cg("width"),
                        intensity: ctx["intensity"],
                        title: ctx.language == .zh ? "升级到 Pro" : "Upgrade to Pro"
                    )
                }
            }
            .buttonStyle(ButtonShimmerPressStyle())
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// 0...1 while the band travels, parked at 1 during the pause.
    private func progress(at date: Date) -> CGFloat {
        let duration = max(ctx["duration"], 0.1)
        let cycle = duration + ctx["pause"]
        let local = date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: cycle)
        let x = min(local / duration, 1)
        let eased = x < 0.5 ? 2 * x * x : 1 - pow(-2 * x + 2, 2) / 2
        return CGFloat(eased)
    }
}

private struct ButtonShimmerFace: View {
    let progress: CGFloat
    let size: CGSize
    let bandWidth: CGFloat
    let intensity: Double
    let title: String

    var body: some View {
        let travel = size.width / 2 + bandWidth + 20
        let x = -travel + progress * travel * 2
        ZStack {
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: 0x2B2F77), Color(hex: 0x4B2A8C)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            HStack(spacing: 8) {
                Image(systemName: "crown.fill")
                    .foregroundStyle(Palette.amber)
                Text(title)
                    .foregroundStyle(.white)
            }
            .font(.headline)
            band
                .offset(x: x)
        }
        .frame(width: size.width, height: size.height)
        .clipShape(Capsule())
        .overlay(
            Capsule().strokeBorder(Color.white.opacity(0.18 + 0.3 * sin(Double(progress) * .pi)), lineWidth: 1)
        )
        .shadow(color: Color(hex: 0x4B2A8C).opacity(0.45), radius: 18, y: 10)
    }

    private var band: some View {
        LinearGradient(
            colors: [.clear, Color.white.opacity(intensity), .clear],
            startPoint: .leading,
            endPoint: .trailing
        )
        .frame(width: bandWidth, height: size.height * 2.2)
        .rotationEffect(.degrees(20))
        .blendMode(.plusLighter)
        .allowsHitTesting(false)
    }
}

private struct ButtonShimmerPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
