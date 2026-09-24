import SwiftUI

extension Effect {
    static let inputsDayNightToggle = Effect(
        id: "inputs.day-night-toggle",
        category: .inputs,
        interaction: .state,
        name: L("Day / Night Toggle", "昼夜切换开关"),
        summary: L("The sun rolls across and becomes a cratered moon under the stars.", "太阳滚动到另一端化作月亮，星空随之浮现。"),
        prompt: L(
            "A large illustrated theme switch (180 × 76 pt capsule). Day: a sky-blue gradient track, a golden sun knob on the left — given depth by a radial gradient from a pale-yellow core to a deep-orange rim, a soft specular highlight near 10 o'clock and a warm outer glow — wrapped in three concentric translucent halo rings, and white clouds resting along the bottom right. On tap the knob rolls to the right on a spring (response 0.6 s, damping 0.78), rotating as it travels while its fill shifts from warm amber to pale lunar gray and three craters fade in; the halo rings stay as a moonlit aura. The track crossfades to a deep navy night gradient, the clouds sink out of view, and five tiny stars scale in on the left with a 60 ms stagger and a gentle twinkle. Toggling back reverses it all. Whimsical and cinematic.",
            "大尺寸插画主题开关（180 × 76pt 胶囊）。白天：天蓝渐变轨道，左侧金色太阳旋钮由浅黄内核到深橙边缘的径向渐变、10 点钟方向高光和暖色外发光塑造立体感，外围三圈半透明同心光晕，右下铺着蓬松白云。点击后旋钮以弹簧（响应 0.6 秒、阻尼 0.78）边滚边转滑向右侧，填充由暖琥珀变为浅月灰并浮现三个陨石坑，光晕留作清冷月晕；轨道过渡为深藏青夜空，云朵下沉消失，五颗小星星以 60 毫秒错峰缩放出现并轻轻闪烁。再点则全部倒放。童趣而有电影感。"
        ),
        implementation: L(
            "Every layer (track gradients, halos, clouds, stars, craters) reads one isNight flag; a single spring transaction animates offsets, rotation and opacities, with per-star delays via animation(_:value:).",
            "轨道渐变、光晕、云朵、星星与陨石坑都读取同一个 isNight 状态；一次弹簧事务驱动所有位移、旋转与透明度，星星通过 animation(_:value:) 设置各自延迟。"
        ),
        apis: ["withAnimation", "animation(_:value:)", "rotationEffect", "phaseAnimator"],
        tags: ["dark mode", "theme", "day night", "switch", "深色模式", "昼夜", "主题切换", "开关"],
        params: [
            .slider("response", L("Spring response", "弹簧响应"), 0.2...1.2, default: 0.6, unit: "s"),
            .slider("damping", L("Damping", "阻尼"), 0.4...1.0, default: 0.78),
            .toggle("halo", L("Sun halos", "太阳光晕"), default: true),
        ]
    ) { ctx in
        InputDayNightDemo(ctx: ctx)
    }
}

private struct InputDayNightDemo: View {
    let ctx: DemoContext
    @State private var isNight = false

    var body: some View {
        VStack(spacing: 22) {
            Spacer()
            Button(action: toggle) {
                InputDayNightSwitch(isNight: isNight, showHalo: ctx.bool("halo"))
            }
            .buttonStyle(.plain)
            Text(isNight ? L("Dark", "深色") : L("Light", "浅色"), ctx.language)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .contentTransition(.opacity)
            Spacer()
            DemoHint(text: L("Tap the switch", "点击开关切换昼夜"), ctx: ctx)
                .padding(.bottom, 18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.6, delay: 0.5) { toggle() }
    }

    private func toggle() {
        if !ctx.isPreview { Haptics.tap(.medium) }
        withAnimation(.spring(response: ctx["response"], dampingFraction: ctx["damping"])) {
            isNight.toggle()
        }
    }
}

private struct InputDayNightSwitch: View {
    let isNight: Bool
    let showHalo: Bool

    private let size = CGSize(width: 180, height: 76)
    private var knobX: CGFloat { isNight ? 52 : -52 }

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0x74C8FF), Color(hex: 0x3A8DFF)], startPoint: .top, endPoint: .bottom)
            LinearGradient(colors: [Color(hex: 0x1D2247), Color(hex: 0x0B0D1E)], startPoint: .top, endPoint: .bottom)
                .opacity(isNight ? 1 : 0)
            if showHalo {
                halos
            }
            InputStarField(isNight: isNight)
            InputCloudBank()
                .offset(x: 34, y: isNight ? 70 : 22)
                .opacity(isNight ? 0 : 1)
            knob
        }
        .frame(width: size.width, height: size.height)
        .clipShape(Capsule())
        .overlay(Capsule().strokeBorder(Color.black.opacity(0.08), lineWidth: 1))
        .shadow(color: (isNight ? Color(hex: 0x1D2247) : Color(hex: 0x3A8DFF)).opacity(0.35), radius: 16, y: 8)
    }

    private var halos: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { ring in
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 96 + CGFloat(ring) * 36, height: 96 + CGFloat(ring) * 36)
            }
        }
        .offset(x: knobX)
    }

    private var knob: some View {
        ZStack {
            InputSunFace()
            Circle()
                .fill(LinearGradient(colors: [Color(hex: 0xF1F3FA), Color(hex: 0xC4CAD9)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .opacity(isNight ? 1 : 0)
            InputMoonCraters()
                .opacity(isNight ? 1 : 0)
        }
        .frame(width: 60, height: 60)
        .rotationEffect(.degrees(isNight ? 0 : -120))
        .shadow(color: Color(hex: 0xFFB02E).opacity(isNight ? 0 : 0.65), radius: 12)
        .shadow(color: .black.opacity(0.25), radius: 6, x: 2, y: 3)
        .offset(x: knobX)
    }
}

/// A sun with volume: radial core-to-rim gradient, a rim that darkens toward the lower right,
/// and a soft specular highlight near 10 o'clock.
private struct InputSunFace: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(hex: 0xFFF1A8), Color(hex: 0xFFC83D), Color(hex: 0xFF9A1F)],
                        center: UnitPoint(x: 0.36, y: 0.32),
                        startRadius: 2,
                        endRadius: 40
                    )
                )
            Circle()
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.white.opacity(0.55), .clear, Color(hex: 0xC4580A).opacity(0.45)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
            Ellipse()
                .fill(Color.white.opacity(0.55))
                .frame(width: 18, height: 10)
                .rotationEffect(.degrees(-35))
                .blur(radius: 3)
                .offset(x: -12, y: -14)
        }
    }
}

private struct InputMoonCraters: View {
    var body: some View {
        ZStack {
            Circle().fill(Color(hex: 0xA9B0C2)).frame(width: 16, height: 16).offset(x: -8, y: -10)
            Circle().fill(Color(hex: 0xA9B0C2)).frame(width: 10, height: 10).offset(x: 12, y: 4)
            Circle().fill(Color(hex: 0xA9B0C2)).frame(width: 8, height: 8).offset(x: -4, y: 14)
        }
    }
}

private struct InputCloudBank: View {
    var body: some View {
        ZStack {
            Circle().fill(Color.white.opacity(0.7)).frame(width: 46, height: 46).offset(x: -34, y: 6)
            Circle().fill(Color.white.opacity(0.7)).frame(width: 56, height: 56).offset(x: 6, y: -4)
            Circle().fill(Color.white).frame(width: 40, height: 40).offset(x: -18, y: 14)
            Circle().fill(Color.white).frame(width: 50, height: 50).offset(x: 20, y: 12)
            Circle().fill(Color.white).frame(width: 36, height: 36).offset(x: 50, y: 4)
        }
    }
}

private struct InputStarField: View {
    let isNight: Bool

    private static let stars: [CGPoint] = [
        CGPoint(x: -62, y: -18), CGPoint(x: -34, y: -24), CGPoint(x: -48, y: 8),
        CGPoint(x: -14, y: -4), CGPoint(x: -70, y: 16),
    ]

    var body: some View {
        ZStack {
            ForEach(Self.stars.indices, id: \.self) { index in
                let point = Self.stars[index]
                Image(systemName: "sparkle")
                    .font(.system(size: index % 2 == 0 ? 9 : 6, weight: .bold))
                    .foregroundStyle(Color.white)
                    .modifier(InputStarTwinkle(active: isNight, period: 0.9 + Double(index) * 0.2))
                    .scaleEffect(isNight ? 1 : 0.1)
                    .opacity(isNight ? 1 : 0)
                    .offset(x: point.x, y: point.y)
                    .animation(.spring(response: 0.45, dampingFraction: 0.6).delay(isNight ? 0.12 + Double(index) * 0.06 : 0), value: isNight)
            }
        }
    }
}

/// The endless twinkle only exists at night; in day mode the stars are invisible, so nothing keeps animating.
private struct InputStarTwinkle: ViewModifier {
    let active: Bool
    let period: Double

    func body(content: Content) -> some View {
        if active {
            content.phaseAnimator([1.0, 0.45]) { view, phase in
                view.opacity(phase)
            } animation: { _ in
                .easeInOut(duration: period)
            }
        } else {
            content
        }
    }
}
