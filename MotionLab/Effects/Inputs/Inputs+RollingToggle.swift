import SwiftUI

extension Effect {
    static let inputsRollingToggle = Effect(
        id: "inputs.rolling-toggle",
        category: .inputs,
        interaction: .tap,
        name: L("Rolling Ball Toggle", "滚球开关"),
        summary: L("The knob is a ball that physically rolls across the track, painting it as it goes.", "旋钮是一颗真实滚过轨道的小球，边滚边给轨道上色。"),
        prompt: L(
            "A 116 × 54 pt track holding a glossy 42 pt ball with a printed stripe and glyph. On tap the ball rolls rather than slides: its rotation is locked to its travel (angle = distance ÷ radius, about 170° for the full 62 pt run), so the stripe visibly turns over while a fixed specular highlight stays on top. Both ride the same spring (response 0.5 s, damping 0.7), so the small overshoot at the end rocks the ball back a few degrees like a real sphere settling. A soft contact shadow rides beneath it, and a sky-to-mint fill paints the track exactly up to the ball's centre, trailing it. A light haptic ticks on landing. Tangible, toy-like and honest to physics.",
            "一条 116 × 54pt 的轨道里放着一颗 42pt 的光泽小球，球面印有条纹与图标。点击后小球是“滚”过去而不是“滑”过去：旋转角与位移严格绑定（角度 = 距离 ÷ 半径，走完 62pt 约转 170°），条纹明显翻滚，而顶部的高光保持不动。位移与旋转共用同一个弹簧（响应 0.5 秒、阻尼 0.7），末端的小过冲会让球像真实球体落定一样回滚几度。柔和的接触阴影始终垫在球下，轨道上天蓝到薄荷色的填充恰好涂到球心位置，紧跟其后。落定时一次轻触觉。可触、像玩具，又符合物理。"
        ),
        implementation: L(
            "One spring transaction drives both the ball's offset and its rotationEffect, where the angle is travel / radius in radians; the fill's width is derived from the same state so it trails the centre.",
            "同一个弹簧事务同时驱动小球的 offset 与 rotationEffect，旋转角为 位移 / 半径（弧度）；填充宽度由同一状态推导，因此紧跟球心。"
        ),
        apis: ["rotationEffect", "offset", "spring(response:dampingFraction:)", "RadialGradient"],
        tags: ["toggle", "switch", "roll", "ball", "开关", "滚动", "小球", "物理"],
        params: [
            .slider("response", L("Spring response", "弹簧响应"), 0.2...1.0, default: 0.5, unit: "s"),
            .slider("damping", L("Damping", "阻尼"), 0.4...1.0, default: 0.7),
            .slider("slip", L("Grip", "抓地力"), 0.3...1.2, default: 1.0),
        ]
    ) { ctx in
        RollingToggleDemo(ctx: ctx)
    }
}

private struct RollingToggleDemo: View {
    let ctx: DemoContext
    @State private var isOn = false

    private let trackWidth: CGFloat = 116
    private let trackHeight: CGFloat = 54
    private let ball: CGFloat = 42
    private var inset: CGFloat { (trackHeight - ball) / 2 }
    private var travel: CGFloat { trackWidth - inset * 2 - ball }

    var body: some View {
        VStack(spacing: 22) {
            Spacer()
            track
            Text(isOn ? L("Auto-Brightness on", "自动亮度已开启") : L("Auto-Brightness off", "自动亮度已关闭"), ctx.language)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .contentTransition(.opacity)
                .animation(.easeInOut(duration: 0.25), value: isOn)
            Spacer()
            DemoHint(text: L("Tap the switch", "点击开关"), ctx: ctx)
                .padding(.bottom, 18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.5, delay: 0.4) { toggle() }
    }

    private var track: some View {
        let x: CGFloat = isOn ? travel : 0
        let radians: Double = Double(x / (ball / 2)) * ctx["slip"]
        let fillWidth: CGFloat = inset + x + ball / 2
        return ZStack(alignment: .leading) {
            Capsule()
                .fill(Color.primary.opacity(0.1))
                .overlay(Capsule().strokeBorder(Palette.stroke))
            Capsule()
                .fill(LinearGradient(colors: [Palette.sky, Palette.mint], startPoint: .leading, endPoint: .trailing))
                .frame(width: fillWidth)
                .opacity(isOn ? 1 : 0.35)
            RollingBall(isOn: isOn, size: ball)
                .rotationEffect(.radians(radians))
                .overlay(alignment: .top) { highlight }
                .background(alignment: .bottom) { contactShadow }
                .offset(x: inset + x)
        }
        .frame(width: trackWidth, height: trackHeight)
        .contentShape(Capsule())
        .onTapGesture { toggle() }
    }

    /// Specular highlight that stays put while the ball turns underneath.
    private var highlight: some View {
        Ellipse()
            .fill(LinearGradient(colors: [.white.opacity(0.75), .white.opacity(0)], startPoint: .top, endPoint: .bottom))
            .frame(width: ball * 0.55, height: ball * 0.3)
            .padding(.top, 3)
            .allowsHitTesting(false)
    }

    private var contactShadow: some View {
        Ellipse()
            .fill(Color.black.opacity(0.22))
            .frame(width: ball * 0.8, height: 6)
            .blur(radius: 3)
            .offset(y: 3)
    }

    private func toggle() {
        withAnimation(.spring(response: ctx["response"], dampingFraction: ctx["damping"])) {
            isOn.toggle()
        }
        let delay = ctx["response"] * 0.6
        Task {
            try? await Task.sleep(for: .seconds(delay))
            if !ctx.isPreview { Haptics.tap() }
        }
    }
}

private struct RollingBall: View {
    let isOn: Bool
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.white, Color(white: 0.86)],
                        center: UnitPoint(x: 0.35, y: 0.3),
                        startRadius: 1,
                        endRadius: size * 0.7
                    )
                )
            Capsule()
                .fill(isOn ? Palette.mint : Palette.coral)
                .frame(width: size, height: 7)
                .opacity(0.85)
            Image(systemName: "sun.max.fill")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(isOn ? Palette.sky : Color.gray)
                .offset(y: -11)
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .shadow(color: .black.opacity(0.18), radius: 4, y: 2)
    }
}
