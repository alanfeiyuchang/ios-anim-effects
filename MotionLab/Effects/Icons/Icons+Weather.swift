import SwiftUI

extension Effect {
    static let iconsWeather = Effect(
        id: "icons.weather",
        category: .icons,
        interaction: .loop,
        name: L("Ambient Weather Icon", "氛围天气图标"),
        summary: L("Rotating sun rays, drifting clouds, rain and lightning.", "旋转的阳光、漂浮的云、雨滴与闪电。"),
        prompt: L(
            "A living weather glyph built from layers: a warm radial-gradient sun whose twelve rounded rays rotate slowly (≈20°/s) and breathe in length, soft white clouds that drift a few points side to side on offset sine waves, slanted rain streaks that fall and fade in a staggered loop, and, in storm mode, an amber bolt that double-flashes every few seconds while the clouds darken. Switching condition springs the sun behind the cloud (scale 70%, offset up-left) and cross-fades the precipitation. Everything loops seamlessly — calm, glanceable ambience worthy of a widget.",
            "由多层组成的“活”天气图标：暖色径向渐变的太阳，十二道圆角光芒以约每秒 20° 缓慢旋转并伸缩呼吸；柔白的云朵沿相位错开的正弦波左右漂移几个点；倾斜的雨丝按错落节奏下落并淡出；在雷暴模式下，云层变暗，一道琥珀色闪电每隔几秒连闪两下。切换天气时，太阳以弹簧动画退到云后（缩放 70%、向左上偏移），降水层交叉淡入淡出。所有动画无缝循环——安静、一瞥即懂，足以放进小组件。"
        ),
        implementation: L(
            "A TimelineView(.animation) supplies time to a layered ZStack (rotating ray Capsules, SF Symbol clouds, falling Capsule drops); condition changes animate with a spring keyed to the mode.",
            "TimelineView(.animation) 为分层 ZStack 提供时间（旋转的光芒 Capsule、SF Symbol 云朵、下落的 Capsule 雨滴）；天气切换通过绑定到模式的弹簧动画完成。"
        ),
        apis: ["TimelineView(.animation)", "RadialGradient", "rotationEffect", "animation(_:value:)"],
        tags: ["weather", "sun", "rain", "ambient", "天气", "太阳", "下雨", "氛围"],
        params: [
            .choice("mode", L("Condition", "天气"), [L("Sunny", "晴"), L("Cloudy", "多云"), L("Rain", "雨"), L("Storm", "雷暴")], default: 1),
            .slider("speed", L("Speed", "速度"), 0.3...2, default: 1),
        ]
    ) { ctx in
        WeatherDemo(ctx: ctx)
    }
}

private struct WeatherDemo: View {
    let ctx: DemoContext
    @State private var offset = 0

    private var mode: Int { (ctx.int("mode") + offset) % 4 }

    private var label: LocalizedText {
        switch mode {
        case 0: return L("Sunny · 26°", "晴 · 26°")
        case 1: return L("Partly cloudy · 21°", "多云 · 21°")
        case 2: return L("Light rain · 17°", "小雨 · 17°")
        default: return L("Thunderstorm · 15°", "雷阵雨 · 15°")
        }
    }

    var body: some View {
        VStack(spacing: 18) {
            TimelineView(.animation) { timeline in
                WeatherScene(
                    time: timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 3_600) * ctx["speed"],
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
            DemoHint(text: L("Tap to change the weather", "点击切换天气"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { offset += 1 }
        .autoplay(ctx.isPreview, every: 2.8) { offset += 1 }
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
        let top = stormy ? Color(white: 0.62) : Color(white: 0.99)
        let bottom = stormy ? Color(white: 0.42) : Color(white: 0.84)
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
