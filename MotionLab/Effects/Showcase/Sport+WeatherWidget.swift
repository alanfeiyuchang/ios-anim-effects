import SwiftUI

extension Effect {
    static let showcaseWeatherWidget = Effect(
        id: "showcase.weather-widget",
        category: .showcase,
        interaction: .tap,
        name: L("Summit Weather", "山顶天气"),
        summary: L("Pick an hour: the temperature rolls, the glyph morphs and the card's weather comes alive.", "选择时段：温度滚动、天气图标形变，卡片里的天气随之活起来。"),
        prompt: L(
            "A dark SUMMIT WEATHER widget: a large rounded temperature numeral, the condition name, a palette-coloured weather glyph, a low–high range bar with a white marker, and a strip of five hourly chips. Tapping a chip slides the orange selection plate to it via shared geometry (spring, response 0.45 s, damping 0.8); the temperature rolls digit by digit, the glyph symbol-replaces (snow cloud → sun-behind-cloud → blazing sun) and the marker springs along the range bar with a slight overshoot. Behind the content the card's own weather cross-fades over 600 ms: drifting, swaying snowflakes with parallax speeds, slow blurred cloud banks, or a pulsing sun glow with slowly turning rays. Calm, atmospheric and glanceable.",
            "深色“山顶天气”小组件：大号圆体温度数字、天气名称、分层着色的天气图标、带白色标记点的最低–最高温区间条，以及一排五个逐时小卡。点击某个时段，橙色选中底板借助共享几何滑到该处（弹簧，响应 0.45 秒、阻尼 0.8）；温度逐位滚动，图标以符号替换形变（雪云 → 云后太阳 → 烈日），标记点带轻微过冲弹到区间条的新位置。内容背后，卡片自身的天气在 600 毫秒内交叉渐变：速度不一、左右摇曳的飘雪，缓慢漂移的模糊云层，或一团呼吸的暖阳光晕配缓缓转动的光芒。安静、有氛围，一眼即懂。"
        ),
        implementation: L(
            "The selection plate is a matchedGeometryEffect background; the numeral uses contentTransition(.numericText(value:)) and the glyph .symbolEffect(.replace). Each condition is a TimelineView(.animation(paused:)) + Canvas layer drawn from time with a deterministic hash, and only the active layer runs.",
            "选中底板是 matchedGeometryEffect 背景；温度数字使用 contentTransition(.numericText(value:))，图标使用 .symbolEffect(.replace)。每种天气是一层由时间和确定性哈希绘制的 TimelineView(.animation(paused:)) + Canvas，只有当前天气层在运行。"
        ),
        apis: ["matchedGeometryEffect", "contentTransition(.numericText(value:))", "contentTransition(.symbolEffect(.replace))", "TimelineView(.animation(paused:))", "Canvas"],
        tags: ["weather", "widget", "snow", "temperature", "天气", "小组件", "降雪", "温度"],
        params: [
            .slider("density", L("Snow density", "降雪密度"), 10...90, default: 45, step: 1, decimals: 0),
            .slider("response", L("Spring response", "弹簧响应"), 0.2...0.9, default: 0.45, unit: "s"),
            .slider("damping", L("Damping", "阻尼"), 0.5...1.0, default: 0.8),
            .choice("unit", L("Units", "单位"), [L("°C", "°C"), L("°F", "°F")], default: 0),
        ]
    ) { ctx in
        SportWeatherDemo(ctx: ctx)
    }
}

private struct WeatherHour {
    let label: LocalizedText
    let temp: Int
    /// 0 = snow, 1 = partly cloudy, 2 = sunny.
    let kind: Int
}

private enum WeatherLook {
    static func symbol(_ kind: Int) -> String {
        switch kind {
        case 0: return "cloud.snow.fill"
        case 1: return "cloud.sun.fill"
        default: return "sun.max.fill"
        }
    }

    static func name(_ kind: Int) -> LocalizedText {
        switch kind {
        case 0: return L("Light snow", "小雪")
        case 1: return L("Partly cloudy", "多云间晴")
        default: return L("Bluebird sky", "晴朗无云")
        }
    }

    /// Palette layers: for clouds the first colour is the cloud, the second the snow / sun.
    static func colors(_ kind: Int) -> (Color, Color) {
        switch kind {
        case 0: return (Color.white, Color(hex: 0x8FD3FF))
        case 1: return (Color.white, Signature.accent)
        default: return (Signature.accent, Signature.accentSoft)
        }
    }
}

private struct SportWeatherDemo: View {
    let ctx: DemoContext
    @State private var selected = 0
    @Namespace private var ns

    private static let hours: [WeatherHour] = [
        WeatherHour(label: L("Now", "现在"), temp: -6, kind: 0),
        WeatherHour(label: L("11:00", "11:00"), temp: -3, kind: 1),
        WeatherHour(label: L("12:00", "12:00"), temp: 1, kind: 2),
        WeatherHour(label: L("13:00", "13:00"), temp: 3, kind: 2),
        WeatherHour(label: L("14:00", "14:00"), temp: -1, kind: 1),
    ]
    private static let low = -6
    private static let high = 3
    private let barWidth: CGFloat = 168

    private var hour: WeatherHour { Self.hours[selected] }

    var body: some View {
        SignatureStage {
            VStack(spacing: 0) {
                Spacer()
                card
                Spacer()
                DemoHint(text: L("Tap an hour", "点击某个时段"), ctx: ctx)
                    .padding(.bottom, 14)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .autoplay(ctx.isPreview, every: 1.6, delay: 0.6) {
            select((selected + 1) % Self.hours.count)
        }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 14) {
            SportEyebrowRow(title: L("Summit weather", "山顶天气")(ctx.language), symbol: "mountain.2.fill", trailing: "Nordkette")
            current
            rangeBar
            hourStrip
        }
        .padding(18)
        .frame(width: 292)
        .background {
            ambience
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        }
        .signatureCard()
    }

    private var current: some View {
        let colors = WeatherLook.colors(hour.kind)
        return HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: "\(display(hour.temp))°")
                    .font(Signature.number(52))
                    .foregroundStyle(Color.white)
                    .contentTransition(.numericText(value: Double(hour.temp)))
                Text(WeatherLook.name(hour.kind), ctx.language)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(Signature.textSecondary)
                    .contentTransition(.opacity)
            }
            Spacer(minLength: 0)
            Image(systemName: WeatherLook.symbol(hour.kind))
                .font(.system(size: 46, weight: .regular))
                .symbolRenderingMode(.palette)
                .foregroundStyle(colors.0, colors.1)
                .contentTransition(.symbolEffect(.replace))
                .shadow(color: colors.1.opacity(0.5), radius: 10)
                .frame(width: 70, height: 60)
        }
    }

    private var rangeBar: some View {
        let fraction = CGFloat(hour.temp - Self.low) / CGFloat(Self.high - Self.low)
        return HStack(spacing: 10) {
            Text(verbatim: "\(display(Self.low))°")
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: 0x8FD3FF), Signature.accentSoft, Signature.accent],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 5)
                    .opacity(0.8)
                Circle()
                    .fill(Color.white)
                    .frame(width: 12, height: 12)
                    .shadow(color: .black.opacity(0.5), radius: 3, y: 1)
                    .offset(x: fraction * (barWidth - 12))
                    .animation(.spring(response: ctx["response"], dampingFraction: 0.6), value: selected)
            }
            .frame(width: barWidth, height: 12)
            Text(verbatim: "\(display(Self.high))°")
        }
        .font(.system(size: 11, weight: .semibold, design: .rounded).monospacedDigit())
        .foregroundStyle(Signature.textSecondary)
    }

    private var hourStrip: some View {
        HStack(spacing: 4) {
            ForEach(Self.hours.indices, id: \.self) { index in
                hourChip(index)
            }
        }
    }

    private func hourChip(_ index: Int) -> some View {
        let item = Self.hours[index]
        let isSelected = index == selected
        let ink = isSelected ? Signature.ink : Color.white
        return Button {
            select(index)
        } label: {
            VStack(spacing: 6) {
                Text(item.label, ctx.language)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(isSelected ? Signature.ink.opacity(0.7) : Signature.textSecondary)
                Image(systemName: WeatherLook.symbol(item.kind))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(ink)
                Text(verbatim: "\(display(item.temp))°")
                    .font(.system(size: 12, weight: .semibold, design: .rounded).monospacedDigit())
                    .foregroundStyle(ink)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 68)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Signature.accentGradient)
                        .shadow(color: Signature.accent.opacity(0.5), radius: 8, y: 3)
                        .matchedGeometryEffect(id: "hour", in: ns)
                } else {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white.opacity(0.04))
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(SportPressStyle(scale: 0.94, dim: 0))
    }

    private var ambience: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { kind in
                WeatherAmbience(kind: kind, density: ctx.int("density"), active: hour.kind == kind)
                    .opacity(hour.kind == kind ? 1 : 0)
                    .animation(.easeInOut(duration: 0.6), value: selected)
            }
        }
    }

    private func display(_ celsius: Int) -> Int {
        guard ctx.int("unit") == 1 else { return celsius }
        return Int((Double(celsius) * 9 / 5 + 32).rounded())
    }

    private func select(_ index: Int) {
        guard index != selected else { return }
        if !ctx.isPreview { Haptics.selection() }
        withAnimation(.spring(response: ctx["response"], dampingFraction: ctx["damping"])) {
            selected = index
        }
    }
}

/// One weather condition drawn procedurally behind the card content. Pauses when not visible.
private struct WeatherAmbience: View {
    let kind: Int
    let density: Int
    let active: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: nil, paused: !active)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                switch kind {
                case 0: WeatherAmbience.drawSnow(&context, size: size, t: t, count: density)
                case 1: WeatherAmbience.drawClouds(&context, size: size, t: t)
                default: WeatherAmbience.drawSun(&context, size: size, t: t)
                }
            }
        }
        .allowsHitTesting(false)
    }

    private static func drawSnow(_ context: inout GraphicsContext, size: CGSize, t: Double, count: Int) {
        let full = Path(CGRect(origin: .zero, size: size))
        context.fill(
            full,
            with: .radialGradient(
                Gradient(colors: [Color(hex: 0x8FD3FF).opacity(0.14), .clear]),
                center: CGPoint(x: size.width * 0.85, y: 0),
                startRadius: 0,
                endRadius: size.width * 0.9
            )
        )
        let width = Double(size.width)
        let span = Double(size.height) + 12
        for i in 0..<max(count, 0) {
            let s = Double(i) * 1.37
            let speed = 12 + sportHash(s) * 24
            let y = (t * speed + sportHash(s + 3.1) * span).truncatingRemainder(dividingBy: span) - 6
            let x = sportHash(s + 7.7) * width + sin(t * 0.7 + s) * 6
            let r = 0.7 + sportHash(s + 5.3) * 1.6
            let alpha = 0.15 + sportHash(s + 9.9) * 0.4
            let rect = CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)
            context.fill(Path(ellipseIn: rect), with: .color(Color.white.opacity(alpha)))
        }
    }

    private static func drawClouds(_ context: inout GraphicsContext, size: CGSize, t: Double) {
        context.addFilter(.blur(radius: 18))
        for i in 0..<3 {
            let s = Double(i)
            let w = size.width * CGFloat(0.7 + 0.12 * s)
            let drift = CGFloat(sin(t * 0.12 + s * 2.1)) * 30
            let x = size.width * CGFloat(0.15 + 0.32 * s) - w / 2 + drift
            let y = size.height * CGFloat(0.02 + 0.14 * s)
            let rect = CGRect(x: x, y: y, width: w, height: w * 0.36)
            context.fill(Path(ellipseIn: rect), with: .color(Color.white.opacity(0.07)))
        }
    }

    private static func drawSun(_ context: inout GraphicsContext, size: CGSize, t: Double) {
        let center = CGPoint(x: size.width * 0.84, y: size.height * 0.2)
        let pulse = CGFloat(1 + 0.06 * sin(t * 1.6))
        context.fill(
            Path(CGRect(origin: .zero, size: size)),
            with: .radialGradient(
                Gradient(colors: [Signature.accent.opacity(0.3), Signature.accent.opacity(0.06), .clear]),
                center: center,
                startRadius: 0,
                endRadius: size.width * 0.75 * pulse
            )
        )
        var rays = Path()
        for i in 0..<12 {
            let angle = Double(i) / 12 * 2 * .pi + t * 0.15
            let inner = 44.0
            let outer = 104.0 + 18 * sin(t + Double(i))
            rays.move(to: CGPoint(x: center.x + CGFloat(cos(angle) * inner), y: center.y + CGFloat(sin(angle) * inner)))
            rays.addLine(to: CGPoint(x: center.x + CGFloat(cos(angle) * outer), y: center.y + CGFloat(sin(angle) * outer)))
        }
        context.stroke(rays, with: .color(Signature.accentSoft.opacity(0.12)), style: StrokeStyle(lineWidth: 2, lineCap: .round))
    }
}
