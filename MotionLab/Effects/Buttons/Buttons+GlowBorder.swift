import SwiftUI

extension Effect {
    static let buttonsGlowBorder = Effect(
        id: "buttons.glow-border",
        category: .buttons,
        interaction: .loop,
        name: L("Orbiting Glow Border", "流转辉光描边"),
        summary: L("A conic gradient orbits the border and bleeds a soft glow.", "锥形渐变沿描边环绕流转，并向外晕出柔光。"),
        prompt: L(
            "A near-black rounded-rectangle button (corner radius 20 pt) outlined by a 2 pt border painted with a conic (angular) gradient. The gradient's start angle rotates continuously and linearly, one full orbit every ~3 s, so a bright comet of violet, pink and sky blue appears to chase itself around the edge. Beneath the button, a blurred copy of the same gradient (blur ~14 pt, 70% opacity) radiates a colored halo that orbits in sync. On press the button scales to 97% with a quick spring. The mood is futuristic and energetic, like AI or pro-tier features.",
            "近黑色圆角矩形按钮（圆角 20pt），外圈 2pt 描边使用锥形（角向）渐变绘制。渐变起始角度以线性匀速持续旋转，约 3 秒转一圈，看起来像一颗紫、粉、天蓝交织的彗星沿边缘追逐。按钮下方叠一层同款渐变的模糊副本（模糊约 14pt、70% 不透明度），向外晕出同步旋转的彩色光晕。按下时以快速弹簧缩放到 97%。整体充满未来感与能量，适合 AI 或高级功能入口。"
        ),
        implementation: L(
            "TimelineView drives the angle of an AngularGradient used both as a strokeBorder and, blurred, as a glow layer behind the dark face.",
            "TimelineView 驱动 AngularGradient 的角度，该渐变既用作 strokeBorder，也经模糊后作为深色按钮背后的辉光层。"
        ),
        apis: ["TimelineView", "AngularGradient", "strokeBorder", "blur"],
        tags: ["glow", "border", "gradient", "neon", "辉光", "描边", "渐变", "AI"],
        params: [
            .slider("period", L("Orbit period", "旋转周期"), 1.0...8.0, default: 3.0, unit: "s"),
            .slider("glow", L("Glow radius", "辉光半径"), 0...30, default: 14, decimals: 0, unit: "pt"),
            .choice("style", L("Gradient", "渐变样式"), [L("Comet", "彗星"), L("Spectrum", "光谱")], default: 0),
        ]
    ) { ctx in
        ButtonGlowBorderDemo(ctx: ctx)
    }
}

private struct ButtonGlowBorderDemo: View {
    let ctx: DemoContext

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            Button {
                Haptics.tap(.medium)
            } label: {
                TimelineView(.animation) { timeline in
                    ButtonGlowFace(
                        angle: angle(at: timeline.date),
                        glow: ctx.cg("glow"),
                        colors: colors,
                        title: ctx.language == .zh ? "用 AI 生成" : "Generate with AI"
                    )
                }
            }
            .buttonStyle(ButtonGlowPressStyle())
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var colors: [Color] {
        if ctx.int("style") == 1 {
            return Palette.spectrum + [Palette.indigo]
        }
        return [
            Palette.violet.opacity(0), Palette.violet.opacity(0), Palette.violet,
            Palette.pink, Palette.sky, Color.white, Palette.violet.opacity(0),
        ]
    }

    private func angle(at date: Date) -> Angle {
        let period = max(ctx["period"], 0.2)
        let t = date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: period)
        return .degrees(t / period * 360)
    }
}

private struct ButtonGlowFace: View {
    let angle: Angle
    let glow: CGFloat
    let colors: [Color]
    let title: String

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
    }

    private var gradient: AngularGradient {
        AngularGradient(gradient: Gradient(colors: colors), center: .center, angle: angle)
    }

    var body: some View {
        ZStack {
            shape
                .fill(gradient)
                .blur(radius: glow)
                .opacity(0.7)
            shape
                .fill(Color(hex: 0x0E0F1A))
            shape
                .strokeBorder(gradient, lineWidth: 2)
            HStack(spacing: 8) {
                Image(systemName: "wand.and.stars")
                Text(title)
            }
            .font(.headline)
            .foregroundStyle(.white)
        }
        .frame(width: 236, height: 62)
    }
}

private struct ButtonGlowPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
