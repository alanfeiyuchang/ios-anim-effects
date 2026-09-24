import SwiftUI

extension Effect {
    static let navigationRippleTabBar = Effect(
        id: "navigation.ripple-tab-bar",
        category: .navigation,
        interaction: .tap,
        name: L("Ripple Tab Bar", "涟漪标签栏"),
        summary: L(
            "A tap sends a wave through the dock: neighbouring icons hop in sequence, smaller the farther they are.",
            "点击后一道波浪穿过标签栏：相邻图标依次跃起，越远跳得越低。"
        ),
        prompt: L(
            "A 316 pt floating dock with five tinted icons. Tapping one selects it (a soft tinted disc scales in behind it and its label appears below) and sends a wave outward along the bar: each icon hops after a delay of ≈50 ms per slot of distance, the tapped icon rising 10 pt and each step away reaching only 55% of the previous height, then landing on a bouncy spring. A faint ring expands from the tapped icon to 3× and fades over 0.6 s, as if the bar were a liquid surface. A light haptic marks the tap. Playful, rhythmic, a dock that feels alive without being noisy.",
            "一个 316pt 宽的悬浮程序坞，含五个带色调的图标。点击某个图标即选中（身后淡色圆盘缩放出现，下方显示文字标签），同时一道波浪沿栏向两侧传开：每个图标按与点击处的距离延迟约 50 毫秒/格依次跃起，被点击的图标升高 10pt，每远一格高度只剩前一格的 55%，随后以弹跳弹簧落回。一圈淡淡的光环从被点击的图标扩散到 3 倍并在 0.6 秒内淡出，仿佛栏面是一层液体。点击时伴随轻触觉。俏皮、有节奏，让程序坞充满生气又不吵闹。"
        ),
        implementation: L(
            "Each icon runs a keyframeAnimator keyed on a wave counter whose first LinearKeyframe holds for a distance-based delay before a CubicKeyframe lift and a bouncy SpringKeyframe landing; the ring is a Circle driven by its own keyframes.",
            "每个图标运行一个以波次计数为触发器的 keyframeAnimator：先用 LinearKeyframe 按距离停留一段延迟，再以 CubicKeyframe 升起、弹跳的 SpringKeyframe 落下；光环是一个由独立关键帧驱动的 Circle。"
        ),
        apis: ["keyframeAnimator", "LinearKeyframe", "CubicKeyframe", "SpringKeyframe", "scaleEffect"],
        tags: ["tab bar", "dock", "ripple", "wave", "标签栏", "程序坞", "涟漪", "波浪"],
        params: [
            .slider("amplitude", L("Hop height", "跃起高度"), 4...20, default: 10, decimals: 0, unit: "pt"),
            .slider("stagger", L("Wave speed", "波速间隔"), 0.02...0.12, default: 0.05, unit: "s"),
            .slider("falloff", L("Falloff", "衰减系数"), 0.2...0.9, default: 0.55),
        ]
    ) { ctx in
        RippleTabBarDemo(ctx: ctx)
    }
}

private struct RippleRing {
    var scale: CGFloat = 0.4
    var opacity: Double = 0
}

private let rippleSymbols: [String] = ["house.fill", "music.note", "play.rectangle.fill", "bag.fill", "person.crop.circle.fill"]
private let rippleTitles: [LocalizedText] = [L("Home", "首页"), L("Music", "音乐"), L("Videos", "视频"), L("Shop", "商店"), L("Me", "我")]
private let rippleColors: [Color] = [Palette.indigo, Palette.pink, Palette.coral, Palette.mint, Palette.sky]

private struct RippleTabBarDemo: View {
    let ctx: DemoContext
    @State private var selected = 0
    @State private var origin = 0
    @State private var waves = 0

    private let slot: CGFloat = 60

    /// Grid previews and still thumbnails get faint screen content above the bar.
    private var thumbnail: Bool { ctx.isPreview || ctx.isStill }

    var body: some View {
        VStack(spacing: 24) {
            if thumbnail {
                NavigationScreenPlaceholder().padding(.top, 20)
            }
            Spacer(minLength: 0)
            dock
            DemoHint(text: L("Tap any icon", "点击任一图标"), ctx: ctx)
                .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.3) {
            let sequence: [Int] = [2, 4, 1, 3, 0]
            tap(sequence[waves % sequence.count])
        }
    }

    private var dock: some View {
        HStack(spacing: 0) {
            ForEach(0..<rippleSymbols.count, id: \.self) { index in
                item(index)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 10)
        .demoGlass(RoundedRectangle(cornerRadius: 28, style: .continuous), material: .regularMaterial)
        .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).strokeBorder(Palette.stroke))
        .shadow(color: .black.opacity(0.12), radius: 18, y: 8)
    }

    private func item(_ index: Int) -> some View {
        let isSelected = index == selected
        let steps: Int = abs(index - origin)
        let delay: Double = max(Double(steps) * ctx["stagger"], 0.001)
        let height: CGFloat = ctx.cg("amplitude") * CGFloat(pow(ctx["falloff"], Double(steps)))
        let color = rippleColors[index]
        return VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.16))
                    .frame(width: 46, height: 46)
                    .scaleEffect(isSelected ? 1 : 0.3)
                    .opacity(isSelected ? 1 : 0)
                ring(index, color: color)
                Image(systemName: rippleSymbols[index])
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(isSelected ? color : Color.secondary)
            }
            .frame(width: 46, height: 46)
            .keyframeAnimator(initialValue: CGFloat(0), trigger: waves) { content, lift in
                content.offset(y: -lift)
            } keyframes: { _ in
                KeyframeTrack(\.self) {
                    LinearKeyframe(0, duration: delay)
                    CubicKeyframe(height, duration: 0.14)
                    SpringKeyframe(0, duration: 0.5, spring: .bouncy)
                }
            }
            Text(rippleTitles[index], ctx.language)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(color)
                .opacity(isSelected ? 1 : 0)
        }
        .frame(width: slot)
        .contentShape(Rectangle())
        .onTapGesture { tap(index) }
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: selected)
    }

    private func ring(_ index: Int, color: Color) -> some View {
        let fires: Bool = index == origin
        return Circle()
            .stroke(color, lineWidth: 2)
            .frame(width: 46, height: 46)
            .keyframeAnimator(initialValue: RippleRing(), trigger: waves) { content, ring in
                content
                    .scaleEffect(ring.scale)
                    .opacity(ring.opacity)
            } keyframes: { _ in
                KeyframeTrack(\.scale) {
                    LinearKeyframe(0.4, duration: 0.01)
                    CubicKeyframe(fires ? 3 : 0.4, duration: 0.6)
                }
                KeyframeTrack(\.opacity) {
                    LinearKeyframe(fires ? 0.5 : 0, duration: 0.01)
                    CubicKeyframe(0, duration: 0.6)
                }
            }
            .allowsHitTesting(false)
    }

    private func tap(_ index: Int) {
        if !ctx.isPreview { Haptics.tap(.light) }
        origin = index
        selected = index
        waves += 1
    }
}
