import SwiftUI

extension Effect {
    static let showcaseItinerary = Effect(
        id: "showcase.itinerary",
        category: .showcase,
        interaction: .tap,
        name: L("Unfolding Itinerary", "行程时间轴展开"),
        summary: L(
            "A day-by-day trip timeline that unfolds stop by stop: icons pop, connectors grow, text slides in.",
            "逐日行程时间轴依次展开：图标弹出、连接线生长、文字滑入。"
        ),
        prompt: L(
            "A dark itinerary card for “Lago di Braies · 4 days” lists one stop per day on a vertical rail. On tap the timeline unfolds from top to bottom, one row every 80 ms. In each row the tinted icon badge pops from 20% to 100% scale on a spring (response 0.45 s, damping 0.78), the 2 pt gradient connector below it grows downward from a top anchor 100 ms later, and the day label, title and time slide in 14 pt from the left while unblurring from 4 pt. Tapping again folds the rows away in reverse order at a faster 60% stagger. The header chevron rotates 180° and a light haptic confirms each toggle. The cascade reads as a story unfolding: calm, orderly and anticipatory.",
            "暗色行程卡片「布拉耶斯湖 · 4 天」在一条竖向时间轴上逐日列出站点。点击后时间轴自上而下展开，每行间隔 80 毫秒。每一行里，带色彩的图标徽章以弹簧（响应 0.45 秒、阻尼 0.78）从 20% 弹到 100%；100 毫秒后，下方 2pt 的渐变连接线以顶部为锚点向下生长；日期、标题与时间从左侧 14pt 滑入，同时从 4pt 模糊变清晰。再次点击，各行以 60% 的更快节奏倒序收起。标题栏的箭头旋转 180°，每次切换都有轻触感。这种层层递进的节奏像在讲一段展开的旅程：从容、有序，让人期待。"
        ),
        implementation: L(
            "All rows stay in the layout; each row animates scale, opacity, offset and blur with its own .animation(spring.delay(index × stagger), value: open), and the delay order flips when closing.",
            "所有行常驻布局中；每行使用各自的 .animation(spring.delay(序号 × 错峰), value: open) 驱动缩放、透明度、偏移与模糊，收起时反转延迟顺序。"
        ),
        apis: ["animation(_:value:)", "Animation.delay", "scaleEffect(x:y:anchor:)", "blur(radius:)", "spring(response:dampingFraction:)"],
        tags: ["timeline", "itinerary", "stagger", "cascade", "时间轴", "行程", "错峰", "展开"],
        params: [
            .slider("stagger", L("Stagger", "错峰间隔"), 0.02...0.25, default: 0.08, unit: "s"),
            .slider("response", L("Spring response", "弹簧响应"), 0.2...0.8, default: 0.45, unit: "s"),
            .toggle("reverse", L("Reverse on close", "倒序收起"), default: true),
        ]
    ) { ctx in
        TravelItineraryDemo(ctx: ctx)
    }
}

// MARK: - Model

private struct TravelItineraryStop {
    let day: LocalizedText
    let title: LocalizedText
    let detail: LocalizedText
    let symbol: String
    let tint: Color

    static let all: [TravelItineraryStop] = [
        TravelItineraryStop(day: L("Day 1", "第 1 天"), title: L("Land in Venice", "抵达威尼斯"), detail: L("08:30 · MU 7123", "08:30 · MU 7123"), symbol: "airplane.arrival", tint: Signature.accent),
        TravelItineraryStop(day: L("Day 2", "第 2 天"), title: L("Drive to Braies", "自驾前往布拉耶斯"), detail: L("3h 10m · 190 km", "3 小时 10 分 · 190 公里"), symbol: "car.fill", tint: Color(hex: 0x5AC8FA)),
        TravelItineraryStop(day: L("Day 3", "第 3 天"), title: L("Sunrise rowboat", "日出湖上划船"), detail: L("05:40 · Boathouse", "05:40 · 船屋码头"), symbol: "sailboat.fill", tint: Signature.lime),
        TravelItineraryStop(day: L("Day 4", "第 4 天"), title: L("Seceda ridge hike", "塞切达山脊徒步"), detail: L("12 km · 5h", "12 公里 · 5 小时"), symbol: "figure.hiking", tint: Signature.accentSoft),
    ]
}

// MARK: - Demo

private struct TravelItineraryDemo: View {
    let ctx: DemoContext
    @State private var open = false

    private var zh: Bool { ctx.language == .zh }

    var body: some View {
        SignatureStage {
            VStack(alignment: .leading, spacing: 16) {
                header
                rows
                Spacer(minLength: 0)
            }
            .padding(18)
            .frame(width: 290, height: 318, alignment: .top)
            .signatureCard()
            .contentShape(Rectangle())
            .onTapGesture(perform: toggle)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .autoplay(ctx.isPreview, every: 2.6, delay: 0.3) { toggle() }
        .task {
            guard !ctx.isPreview else { return }
            try? await Task.sleep(for: .milliseconds(350))
            if !open { toggle() }
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            LandscapeArt(seed: 2)
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(zh ? "旅行手账" : "Trip journal")
                    .signatureEyebrow()
                Text(zh ? "布拉耶斯湖 · 4 天" : "Lago di Braies · 4 days")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.down")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color.white)
                .frame(width: 28, height: 28)
                .background(Color.white.opacity(0.1), in: Circle())
                .rotationEffect(.degrees(open ? 180 : 0))
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: open)
        }
    }

    private var rows: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(TravelItineraryStop.all.enumerated()), id: \.offset) { index, stop in
                TravelItineraryRow(
                    stop: stop,
                    language: ctx.language,
                    isLast: index == TravelItineraryStop.all.count - 1,
                    visible: open,
                    delay: delay(for: index),
                    response: ctx["response"]
                )
            }
        }
    }

    private func delay(for index: Int) -> Double {
        let stagger = ctx["stagger"]
        if open || !ctx.bool("reverse") { return Double(index) * stagger }
        return Double(TravelItineraryStop.all.count - 1 - index) * stagger * 0.6
    }

    private func toggle() {
        if !ctx.isPreview { Haptics.tap() }
        open.toggle()
    }
}

// MARK: - Row

private struct TravelItineraryRow: View {
    let stop: TravelItineraryStop
    let language: AppLanguage
    let isLast: Bool
    let visible: Bool
    let delay: Double
    let response: Double

    private var pop: Animation { .spring(response: response, dampingFraction: 0.78).delay(delay) }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            rail
            text
            Spacer(minLength: 0)
        }
    }

    private var rail: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(stop.tint.opacity(0.18))
                    .overlay(Circle().strokeBorder(stop.tint.opacity(0.4), lineWidth: 1))
                Image(systemName: stop.symbol)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(stop.tint)
            }
            .frame(width: 30, height: 30)
            .scaleEffect(visible ? 1 : 0.2)
            .opacity(visible ? 1 : 0)
            .animation(pop, value: visible)
            if !isLast {
                Capsule()
                    .fill(LinearGradient(colors: [stop.tint.opacity(0.7), Color.white.opacity(0.08)], startPoint: .top, endPoint: .bottom))
                    .frame(width: 2, height: 24)
                    .padding(.vertical, 2)
                    .scaleEffect(x: 1, y: visible ? 1 : 0, anchor: .top)
                    .animation(.easeOut(duration: 0.28).delay(delay + 0.1), value: visible)
            }
        }
    }

    private var text: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(stop.day(language))
                .signatureEyebrow()
            Text(stop.title(language))
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.white)
            Text(stop.detail(language))
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Signature.textSecondary)
        }
        .opacity(visible ? 1 : 0)
        .offset(x: visible ? 0 : -14)
        .blur(radius: visible ? 0 : 4)
        .animation(pop, value: visible)
    }
}
