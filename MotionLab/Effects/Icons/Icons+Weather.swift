import SwiftUI

extension Effect {
    static let iconsWeather = Effect(
        id: "icons.weather",
        category: .icons,
        interaction: .loop,
        name: L("Ambient Weather Icon", "氛围天气图标"),
        summary: L("Rotating sun rays, drifting clouds, rain and lightning.", "旋转的阳光、漂浮的云、雨滴与闪电。"),
        prompt: L(
            "A living weather glyph built from layers: a warm radial-gradient sun whose twelve rounded rays rotate at about 20°/s and breathe in length, cool-grey clouds that drift a few points on offset sine waves, slanted rain streaks that fall and fade in a staggered loop, and in storm mode an amber bolt that double-flashes every few seconds while the clouds darken. Tapping the stage cycles sunny → cloudy → rain → storm, or tap a glyph in the four-icon strip beneath to jump. Each switch springs the sun behind the cloud (70% scale, offset up-left), cross-fades the precipitation and updates the label. Everything loops seamlessly: calm, glanceable ambience worthy of a widget.",
            "由多层组成的“活”天气图标：暖色径向渐变的太阳，十二道圆角光芒以约每秒20°缓缓旋转并伸缩呼吸；冷灰色云朵沿相位错开的正弦波左右漂移几个点；倾斜的雨丝错落下落并淡出；雷暴模式下云层变暗，一道琥珀色闪电每隔几秒连闪两下。点击舞台按晴→多云→雨→雷暴循环切换，也可以直接点下方四枚图标跳转。每次切换，太阳以弹簧退到云后（缩放70%、向左上偏移），降水层交叉淡变，文字同步更新。所有动画无缝循环，安静、一眼即懂，足以放进小组件。"
        ),
        implementation: L(
            "A TimelineView(.animation) supplies time to a layered ZStack (rotating ray Capsules, SF Symbol clouds, falling Capsule drops); condition changes animate with a spring keyed to the mode.",
            "TimelineView(.animation) 为分层 ZStack 提供时间（旋转的光芒 Capsule、SF Symbol 云朵、下落的 Capsule 雨滴）；天气切换通过绑定到模式的弹簧动画完成。"
        ),
        apis: ["TimelineView(.animation)", "RadialGradient", "rotationEffect", "animation(_:value:)"],
        tags: ["weather", "sun", "rain", "ambient", "天气", "太阳", "下雨", "氛围"],
        params: [
            .choice("mode", L("Starting condition", "初始天气"), [L("Sunny", "晴"), L("Cloudy", "多云"), L("Rain", "雨"), L("Storm", "雷暴")], default: 1),
            .slider("speed", L("Speed", "速度"), 0.3...2, default: 1),
        ]
    ) { ctx in
        WeatherDemo(ctx: ctx)
    }
}

private let weatherSymbols = ["sun.max.fill", "cloud.sun.fill", "cloud.rain.fill", "cloud.bolt.fill"]

private struct WeatherDemo: View {
    let ctx: DemoContext
    /// Condition picked on the stage; `nil` follows the Starting condition parameter.
    @State private var picked: Int?
    /// Scene time carried over from earlier speeds, so moving the Speed slider changes the pace without the sun,
    /// clouds and rain jumping.
    @State private var timeShift: Double = 0

    private var mode: Int { (picked ?? ctx.int("mode")).clamped(to: 0...3) }

    private var label: LocalizedText {
        switch mode {
        case 0: return L("Sunny · 26°", "晴 · 26°")
        case 1: return L("Partly cloudy · 21°", "多云 · 21°")
        case 2: return L("Light rain · 17°", "小雨 · 17°")
        default: return L("Thunderstorm · 15°", "雷阵雨 · 15°")
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: ctx.isPreview))) { timeline in
                WeatherScene(
                    time: Self.clock(timeline.date) * ctx["speed"] + timeShift,
                    mode: mode
                )
            }
            .frame(width: 220, height: 200)
            .animation(.spring(response: 0.7, dampingFraction: 0.75), value: mode)
            Text(label, ctx.language)
                .font(.headline)
                .foregroundStyle(.secondary)
                .contentTransition(.opacity)
                .animation(.snappy, value: mode)
            conditionPicker
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { select((mode + 1) % 4) }
        // Changing the parameter restarts from that condition.
        .onChange(of: ctx.int("mode")) { _, _ in picked = nil }
        .onChange(of: ctx["speed"]) { old, new in
            timeShift += Self.clock(Date()) * (old - new)
        }
        .autoplay(ctx.isPreview, every: 2.8) { select((mode + 1) % 4) }
    }

    private static func clock(_ date: Date) -> Double {
        date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 3_600)
    }

    /// Shows which condition is live; tap a glyph to jump straight to it.
    private var conditionPicker: some View {
        HStack(spacing: 6) {
            ForEach(weatherSymbols.indices, id: \.self) { i in
                Image(systemName: weatherSymbols[i])
                    .symbolRenderingMode(.hierarchical)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(i == mode ? Color.white : Color.secondary)
                    .frame(width: 40, height: 30)
                    .background {
                        if i == mode {
                            Capsule().fill(Palette.primary)
                        }
                    }
                    .contentShape(Capsule())
                    .onTapGesture { select(i) }
            }
        }
        .padding(4)
        .background(Color.primary.opacity(0.06), in: Capsule())
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: mode)
    }

    private func select(_ next: Int) {
        guard next != mode else { return }
        if !ctx.isPreview { Haptics.selection() }
        picked = next
    }
}

private struct WeatherScene: View {
    let time: Double
    let mode: Int

    private var sunOnly: Bool { mode == 0 }
    private var stormy: Bool { mode == 3 }

    var body: some View {
        ZStack {
            SunGlyph(time: time)
                .scaleEffect(sunOnly ? 1 : 0.7)
                .offset(x: sunOnly ? 0 : -34, y: sunOnly ? 0 : -34)
                .opacity(mode <= 1 ? 1 : 0)
            cloud(size: 78, dx: 38, dy: -26, phase: 1.3)
                .opacity(sunOnly ? 0 : 0.75)
            RainLayer(time: time)
                .offset(y: 58)
                .opacity(mode >= 2 ? 1 : 0)
            cloud(size: 118, dx: 0, dy: 6, phase: 0)
                .opacity(sunOnly ? 0 : 1)
                .scaleEffect(sunOnly ? 0.6 : 1)
            Image(systemName: "bolt.fill")
                .font(.system(size: 40, weight: .bold))
                .foregroundStyle(Palette.amber)
                .shadow(color: Palette.amber.opacity(0.8), radius: 12)
                .offset(x: 6, y: 58)
                .opacity(stormy ? flash : 0)
        }
    }

    private var flash: Double {
        let t = time.truncatingRemainder(dividingBy: 3.2)
        if t < 0.08 || (t > 0.18 && t < 0.3) { return 1 }
        return 0
    }

    private func cloud(size: CGFloat, dx: CGFloat, dy: CGFloat, phase: Double) -> some View {
        let drift = CGFloat(sin(time * 0.7 + phase) * 6)
        // Cool blue-grey rather than pure white, so clouds keep their shape on light stages too.
        let top = stormy ? Color(hex: 0x9AA3B5) : Color(hex: 0xF1F4F9)
        let bottom = stormy ? Color(hex: 0x5C6477) : Color(hex: 0xAAB5C8)
        return Image(systemName: "cloud.fill")
            .font(.system(size: size))
            .foregroundStyle(LinearGradient(colors: [top, bottom], startPoint: .top, endPoint: .bottom))
            .shadow(color: .black.opacity(0.15), radius: 10, y: 6)
            .offset(x: dx + drift, y: dy)
    }
}

private struct SunGlyph: View {
    let time: Double

    var body: some View {
        let pulse = CGFloat(sin(time * 2) * 2.5)
        ZStack {
            ZStack {
                ForEach(0..<12, id: \.self) { i in
                    Capsule()
                        .fill(Palette.amber)
                        .frame(width: 5, height: 14 + pulse)
                        .offset(y: -58)
                        .rotationEffect(.degrees(Double(i) * 30))
                }
            }
            .rotationEffect(.degrees(time * 20))
            Circle()
                .fill(RadialGradient(colors: [Color(hex: 0xFFE27A), Palette.amber, Palette.coral], center: .topLeading, startRadius: 4, endRadius: 90))
                .frame(width: 78, height: 78)
                .shadow(color: Palette.amber.opacity(0.6), radius: 20)
        }
    }
}

private struct RainLayer: View {
    let time: Double

    var body: some View {
        ZStack {
            ForEach(0..<9, id: \.self) { i in
                drop(i)
            }
        }
        .frame(width: 120, height: 70)
    }

    private func drop(_ i: Int) -> some View {
        let seed = Double(i) * 0.37
        let cycle = (time * 1.4 + seed).truncatingRemainder(dividingBy: 1)
        let x = CGFloat(-48 + Double(i) * 12)
        return Capsule()
            .fill(Palette.sky)
            .frame(width: 3, height: 14)
            .rotationEffect(.degrees(15))
            .offset(x: x - CGFloat(cycle * 8), y: CGFloat(-26 + cycle * 56))
            .opacity(1 - cycle)
    }
}
