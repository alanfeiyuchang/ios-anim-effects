import SwiftUI

extension Effect {
    static let showcaseFlipClock = Effect(
        id: "showcase.flip-clock",
        category: .showcase,
        interaction: .tap,
        name: L("Time-zone Flip Clock", "时区翻页时钟"),
        summary: L(
            "Switch cities and only the digits that change flip over like a split-flap board, with a bouncy landing.",
            "切换城市时，只有变化的数字像机场翻牌一样翻转，落下时轻轻回弹。"
        ),
        prompt: L(
            "A dark travel widget shows the local time of the selected city in four split-flap digit tiles (52×76 pt, rounded digits, 1.5 pt hinge gap), above a row of airport-code chips (HGH · NCE · KEF · JFK) with a sliding orange selection capsule. When the city changes, only the digits that differ flip, left to right, 60 ms apart. Over ~0.6 s the upper flap carrying the old digit folds down around the hinge with a quadratic ease-in and darkens as it turns edge-on, revealing the new digit’s top half. The new lower flap then swings from 90° to flat with an ease-in fall and lands with a small rebound (~8° lift, sine-shaped). Perspective is 0.45. A selection haptic accompanies each switch and the minute ticks live. It feels mechanical, nostalgic and precise.",
            "暗色旅行小组件用四块翻牌数字（52 × 76pt，1.5pt 铰链缝）显示所选城市当地时间，下方是机场代码标签（HGH · NCE · KEF · JFK），橙色选中胶囊在其间滑动。切换城市时，只有变化的数字从左到右依次翻转，间隔 60 毫秒：约 0.6 秒内，旧数字的上半片以二次缓入绕铰链下翻，转到侧面时变暗；新数字的下半片再从 90° 缓入落平，着陆轻弹约 8°。透视 0.45。每次切换一次选择触感，分钟实时走动。机械、怀旧而精准。"
        ),
        implementation: L(
            "Each digit is an Animatable view whose animatableData is a monotonically increasing flip counter. The fractional part is mapped to the upper and lower flap angles for rotation3DEffect(axis: x, anchor: bottom/top), so no state reset is needed between flips. Halves are clipped copies of a full tile, and TimelineView(.everyMinute) keeps the time live.",
            "每个数字是一个 Animatable 视图，其 animatableData 为单调递增的翻转计数，小数部分映射为上下翻片的 rotation3DEffect（x 轴，锚点分别为底部/顶部）角度，因此两次翻转之间无需重置状态；上下半片是整块数字的裁切副本，TimelineView(.everyMinute) 让时间实时走动。"
        ),
        apis: ["Animatable", "rotation3DEffect", "TimelineView(.everyMinute)", "matchedGeometryEffect", "Calendar/TimeZone"],
        tags: ["flip clock", "split flap", "time zone", "world clock", "翻页时钟", "翻牌", "时区", "世界时钟"],
        params: [
            .slider("duration", L("Flip duration", "翻转时长"), 0.3...1.2, default: 0.6, unit: "s"),
            .slider("stagger", L("Digit stagger", "数字错峰"), 0...0.2, default: 0.06, decimals: 2, unit: "s"),
            .slider("bounce", L("Landing bounce", "落下回弹"), 0...1, default: 0.6),
            .slider("perspective", L("Flap perspective", "翻片透视"), 0.1...0.9, default: 0.45),
        ]
    ) { ctx in
        TravelFlipClockDemo(ctx: ctx)
    }
}

// MARK: - Model

private struct TravelClockCity {
    let name: LocalizedText
    let zone: String
    let code: String

    static let all: [TravelClockCity] = [
        TravelClockCity(name: L("Hangzhou", "杭州"), zone: "Asia/Shanghai", code: "HGH"),
        TravelClockCity(name: L("Nice", "尼斯"), zone: "Europe/Paris", code: "NCE"),
        TravelClockCity(name: L("Reykjavík", "雷克雅未克"), zone: "Atlantic/Reykjavik", code: "KEF"),
        TravelClockCity(name: L("New York", "纽约"), zone: "America/New_York", code: "JFK"),
    ]
}

// MARK: - Demo

private struct TravelFlipClockDemo: View {
    let ctx: DemoContext
    @Namespace private var ns
    @State private var city = 0

    private var zh: Bool { ctx.language == .zh }

    var body: some View {
        SignatureStage {
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                VStack(alignment: .leading, spacing: 16) {
                    header
                    TimelineView(.everyMinute) { timeline in
                        clockFace(for: timeline.date)
                    }
                    picker
                }
                .padding(18)
                .frame(width: 310)
                .signatureCard()
                Spacer(minLength: 0)
                DemoHint(text: L("Tap a city to flip the clock", "点击城市切换时钟"), ctx: ctx)
                    .padding(.bottom, 14)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .autoplay(ctx.isPreview, every: 2.0, delay: 0.8) {
            select((city + 1) % TravelClockCity.all.count)
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(zh ? "当地时间" : "Local time")
                    .signatureEyebrow()
                Text(TravelClockCity.all[city].name(ctx.language))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white)
                    .contentTransition(.interpolate)
            }
            Spacer(minLength: 0)
            Image(systemName: "globe.europe.africa.fill")
                .font(.system(size: 18))
                .foregroundStyle(Signature.accent)
                .symbolEffect(.bounce, value: city)
        }
    }

    private func clockFace(for date: Date) -> some View {
        let reading = time(for: date)
        let duration = ctx["duration"]
        let stagger = ctx["stagger"]
        let bounce = ctx["bounce"]
        let depth = ctx.cg("perspective")
        return HStack(spacing: 5) {
            TravelFlipDigit(value: reading.digits[0], duration: duration, delay: 0, bounce: bounce, depth: depth)
            TravelFlipDigit(value: reading.digits[1], duration: duration, delay: stagger, bounce: bounce, depth: depth)
            VStack(spacing: 14) {
                Circle().frame(width: 5, height: 5)
                Circle().frame(width: 5, height: 5)
            }
            .foregroundStyle(Signature.textSecondary)
            TravelFlipDigit(value: reading.digits[2], duration: duration, delay: stagger * 2, bounce: bounce, depth: depth)
            TravelFlipDigit(value: reading.digits[3], duration: duration, delay: stagger * 3, bounce: bounce, depth: depth)
        }
        .frame(maxWidth: .infinity)
    }

    private var picker: some View {
        HStack(spacing: 4) {
            ForEach(0..<TravelClockCity.all.count, id: \.self) { index in
                Button {
                    select(index)
                } label: {
                    Text(TravelClockCity.all[index].code)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(index == city ? Color.black : Signature.textSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 30)
                        .background {
                            if index == city {
                                Capsule()
                                    .fill(Signature.accentGradient)
                                    .matchedGeometryEffect(id: "city", in: ns)
                            }
                        }
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color.white.opacity(0.06), in: Capsule())
    }

    private func select(_ index: Int) {
        guard index != city else { return }
        if !ctx.isPreview { Haptics.selection() }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { city = index }
    }

    /// Four single-character digits (HHMM, 24-hour).
    private func time(for date: Date) -> (digits: [String], suffix: String) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: TravelClockCity.all[city].zone) ?? .current
        let parts = calendar.dateComponents([.hour, .minute], from: date)
        let hour = parts.hour ?? 0
        let minute = parts.minute ?? 0
        let suffix = ""
        let text = String(format: "%02d%02d", hour, minute)
        var digits = text.map { String($0) }
        while digits.count < 4 { digits.insert("0", at: 0) }
        return (digits, suffix)
    }
}

// MARK: - Flip digit

/// Owns the flip counter; strings swap at the moment each flip starts.
private struct TravelFlipDigit: View {
    let value: String
    let duration: Double
    let delay: Double
    let bounce: Double
    let depth: CGFloat

    @State private var current: String
    @State private var previous: String
    @State private var phase: Double = 0
    @State private var target: Double = 0

    init(value: String, duration: Double, delay: Double, bounce: Double, depth: CGFloat) {
        self.value = value
        self.duration = duration
        self.delay = delay
        self.bounce = bounce
        self.depth = depth
        _current = State(initialValue: value)
        _previous = State(initialValue: value)
    }

    var body: some View {
        TravelFlipCard(phase: phase, target: target, current: current, previous: previous, bounce: bounce, depth: depth)
            .onChange(of: value) { _, newValue in
                Task { @MainActor in
                    if delay > 0 { try? await Task.sleep(for: .seconds(delay)) }
                    guard newValue != current else { return }
                    previous = current
                    current = newValue
                    target += 1
                    withAnimation(.linear(duration: duration)) { phase += 1 }
                }
            }
    }
}

/// Renders a split-flap tile for a (fractional) flip progress.
private struct TravelFlipCard: View, Animatable {
    var phase: Double
    let target: Double
    let current: String
    let previous: String
    let bounce: Double
    let depth: CGFloat

    var animatableData: Double {
        get { phase }
        set { phase = newValue }
    }

    /// 0 = flip just started (old digit showing), 1 = at rest on `current`.
    private var progress: Double {
        guard phase < target else { return 1 }
        return min(max(1 - (target - phase), 0), 1)
    }

    private var topAngle: Double {
        let p = progress
        guard p < 0.5 else { return -90 }
        let u = p / 0.5
        return -90 * u * u
    }

    private var bottomAngle: Double {
        let p = progress
        guard p >= 0.5 else { return 90 }
        let s = (p - 0.5) / 0.5
        if s < 0.6 {
            let k = s / 0.6
            return 90 * (1 - k * k)
        }
        return 14 * bounce * sin(.pi * (s - 0.6) / 0.4)
    }

    var body: some View {
        ZStack {
            VStack(spacing: 1.5) {
                TravelFlipHalf(text: current, top: true)
                TravelFlipHalf(text: previous, top: false)
            }
            VStack(spacing: 1.5) {
                TravelFlipHalf(text: previous, top: true)
                    .brightness(topAngle * 0.003)
                    .rotation3DEffect(.degrees(topAngle), axis: (x: 1, y: 0, z: 0), anchor: .bottom, perspective: depth)
                TravelFlipHalf(text: current, top: false)
                    .brightness(-bottomAngle * 0.002)
                    .rotation3DEffect(.degrees(bottomAngle), axis: (x: 1, y: 0, z: 0), anchor: .top, perspective: depth)
            }
        }
        .shadow(color: Color.black.opacity(0.4), radius: 8, y: 5)
    }
}

/// One half (top or bottom) of a digit tile, clipped from a full-size tile.
private struct TravelFlipHalf: View {
    let text: String
    let top: Bool

    private static let size = CGSize(width: 52, height: 76)

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(LinearGradient(colors: [Signature.cardHigh, Color(hex: 0x131316)], startPoint: .top, endPoint: .bottom))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Signature.hairline)
                )
            Text(text)
                .font(Signature.number(50))
                .foregroundStyle(Color.white)
        }
        .frame(width: Self.size.width, height: Self.size.height)
        .frame(width: Self.size.width, height: Self.size.height / 2, alignment: top ? .top : .bottom)
        .clipped()
    }
}
