import SwiftUI

extension Effect {
    static let buttonsPressScale = Effect(
        id: "buttons.press-scale",
        category: .buttons,
        interaction: .tap,
        name: L("Press Scale", "按压缩放"),
        summary: L("A spring-loaded press that sinks and rebounds.", "按下时下沉、松手后弹性回弹的按钮。"),
        prompt: L(
            "A pill-shaped primary button with an indigo-to-violet gradient and a soft tinted drop shadow. On touch-down it instantly scales to about 94%, dims slightly and its shadow tightens (radius 16 → 6 pt), as if pressed into the surface. On release it springs back (response 0.35 s, damping 0.6), overshooting to roughly 103% before settling at 100%, while the shadow blooms back out. A light haptic tick lands on release. The feel is tactile, immediate on press and elastic on release.",
            "胶囊形主按钮，靛蓝到紫罗兰渐变，底部带同色系柔和投影。手指按下瞬间缩放至约 94%，亮度略降，投影半径从 16pt 收紧到 6pt，仿佛被按进了界面。松手后以弹簧曲线（响应 0.35 秒、阻尼 0.6）回弹，先过冲到约 103% 再稳定到 100%，投影同步舒展恢复。松手时伴随一次轻触觉反馈。按下干脆、回弹有弹性，手感真实可触。"
        ),
        implementation: L(
            "A custom ButtonStyle reads configuration.isPressed and drives scaleEffect, brightness and shadow through a single spring animation keyed on the pressed state.",
            "自定义 ButtonStyle 读取 configuration.isPressed，用一条以按压状态为 key 的弹簧动画同时驱动 scaleEffect、brightness 与投影。"
        ),
        apis: ["ButtonStyle", "scaleEffect", "spring(response:dampingFraction:)", "brightness"],
        tags: ["press", "bounce", "spring", "弹性", "按压", "回弹", "micro-interaction", "微交互"],
        params: [
            .slider("scale", L("Pressed scale", "按下缩放"), 0.8...1.0, default: 0.94),
            .slider("response", L("Spring response", "弹簧响应"), 0.1...1.0, default: 0.35, unit: "s"),
            .slider("damping", L("Damping", "阻尼"), 0.2...1.0, default: 0.6),
        ]
    ) { ctx in
        ButtonPressScaleDemo(ctx: ctx)
    }
}

private struct ButtonPressScaleDemo: View {
    let ctx: DemoContext
    @State private var autoPressed = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            Button {
                Haptics.tap()
            } label: {
                HStack(spacing: 8) {
                    Text(ctx.language == .zh ? "继续" : "Continue")
                    Image(systemName: "arrow.right")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(width: 200, height: 58)
                .background(Palette.primary, in: Capsule())
                .overlay(Capsule().strokeBorder(Color.white.opacity(0.22), lineWidth: 1))
            }
            .buttonStyle(
                ButtonPressScaleStyle(
                    scale: ctx.cg("scale"),
                    response: ctx["response"],
                    damping: ctx["damping"],
                    forcePressed: autoPressed
                )
            )
            Spacer()
            DemoHint(text: L("Press and hold the button", "按住按钮再松开"), ctx: ctx)
                .padding(.bottom, 18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 0.9) { autoPressed.toggle() }
    }
}

private struct ButtonPressScaleStyle: ButtonStyle {
    let scale: CGFloat
    let response: Double
    let damping: Double
    let forcePressed: Bool

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed || forcePressed
        return configuration.label
            .brightness(pressed ? -0.06 : 0)
            .shadow(
                color: Palette.indigo.opacity(pressed ? 0.22 : 0.4),
                radius: pressed ? 6 : 16,
                y: pressed ? 3 : 10
            )
            .scaleEffect(pressed ? scale : 1)
            .animation(.spring(response: response, dampingFraction: damping), value: pressed)
    }
}
