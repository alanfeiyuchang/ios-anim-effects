import SwiftUI

extension Effect {
    static let buttonsPressScale = Effect(
        id: "buttons.press-scale",
        category: .buttons,
        interaction: .tap,
        name: L("Press Scale", "按压缩放"),
        summary: L("A spring-loaded press that sinks and rebounds.", "按下时下沉、松手后弹性回弹的按钮。"),
        prompt: L(
            "A 220 × 58 pt pill primary button with an indigo-to-violet gradient, a glossy top highlight and a soft tinted drop shadow, closing an onboarding step. On touch-down it instantly scales to about 94%, dims slightly and its shadow tightens (radius 16 → 6 pt), as if pressed into the surface. On release it springs back (response 0.35 s, damping 0.6), overshooting to roughly 103% before settling, while the shadow blooms back out and the trailing arrow nudges 7 pt forward and bounces home — a hint of \"onward\". A light haptic ticks on release. Immediate on press, elastic on release.",
            "引导流程末尾的 220 × 58pt 胶囊主按钮：靛蓝到紫罗兰渐变，顶部一道光泽高光，底部是同色系柔和投影。手指按下瞬间缩放至约 94%，亮度略降，投影半径从 16pt 收紧到 6pt，像被按进界面；松手后以弹簧（响应 0.35 秒、阻尼 0.6）回弹，先过冲到约 103% 再落定，投影随之舒展，尾部箭头向前轻推 7pt 再弹回，暗示“继续前进”。松手时伴随一次轻触觉。按下干脆、回弹有弹性，手感真实可触。"
        ),
        implementation: L(
            "A custom ButtonStyle reads configuration.isPressed and drives scaleEffect, brightness and shadow through a single spring keyed on the pressed state; the arrow runs a keyframeAnimator triggered by a release counter.",
            "自定义 ButtonStyle 读取 configuration.isPressed，用一条以按压状态为 key 的弹簧同时驱动 scaleEffect、brightness 与投影；箭头由松手计数触发 keyframeAnimator。"
        ),
        apis: ["ButtonStyle", "scaleEffect", "spring(response:dampingFraction:)", "brightness", "keyframeAnimator"],
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
    @State private var releases = 0

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 20) {
                header
                button
                Text(L("7-day free trial · cancel anytime", "7 天免费试用 · 随时取消"), ctx.language)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.tertiary)
            }
            Spacer()
            DemoHint(text: L("Press and hold the button", "按住按钮再松开"), ctx: ctx)
                .padding(.bottom, 18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 0.9) {
            autoPressed.toggle()
            if !autoPressed { releases += 1 }
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { index in
                    Capsule()
                        .fill(index == 2 ? AnyShapeStyle(Palette.primary) : AnyShapeStyle(Color.primary.opacity(0.12)))
                        .frame(width: index == 2 ? 22 : 7, height: 7)
                }
            }
            Text(L("You're all set", "一切准备就绪"), ctx.language)
                .font(.title3.weight(.bold))
                .foregroundStyle(.primary)
        }
    }

    private var button: some View {
        Button {
            Haptics.tap()
            releases += 1
        } label: {
            HStack(spacing: 8) {
                Text(ctx.language == .zh ? "继续" : "Continue")
                Image(systemName: "arrow.right")
                    .keyframeAnimator(initialValue: CGFloat(0), trigger: releases) { content, x in
                        content.offset(x: x)
                    } keyframes: { _ in
                        KeyframeTrack(\.self) {
                            CubicKeyframe(7, duration: 0.14)
                            SpringKeyframe(0, duration: 0.45, spring: .bouncy)
                        }
                    }
            }
            .font(.headline)
            .foregroundStyle(.white)
            .frame(width: 220, height: 58)
            .background(Palette.primary, in: Capsule())
            .overlay {
                // Glossy top highlight: reads as a lit, slightly convex surface.
                Capsule()
                    .fill(LinearGradient(colors: [Color.white.opacity(0.28), .clear], startPoint: .top, endPoint: .center))
                    .padding(1.5)
                    .allowsHitTesting(false)
            }
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
