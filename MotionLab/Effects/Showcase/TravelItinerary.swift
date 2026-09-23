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
            "A dark itinerary card for “Lago di Braies · 4 days” lists one stop per day on a vertical rail. On tap the timeline unfolds top to bottom, one row every 80 ms: each tinted icon badge pops from 20% to 100% on a spring (response 0.45 s, damping 0.78), the 2 pt gradient connector below grows downward 100 ms later, and the day, title and time slide in 14 pt from the left while unblurring from 4 pt. Tapping again folds the rows away in reverse at a faster 60% stagger. The card resizes with it: closed it shows only the header and a one-line summary (four tinted stop glyphs, “4 stops · Venice → Seceda”); its height springs open with the cascade and shrinks only after the fold finishes. The chevron rotates 180° and a light haptic confirms each toggle. A story unfolding, calm and orderly.",
            "暗色行程卡片“布拉耶斯湖 · 4 天”在竖向时间轴上逐日列出站点。点击后自上而下展开，每行间隔 80 毫秒：图标徽章以弹簧（响应 0.45 秒、阻尼 0.78）从 20% 弹到 100%，100 毫秒后下方 2pt 渐变连接线向下生长，日期、标题与时间从左侧 14pt 滑入并由 4pt 模糊变清晰。再点则以 60% 的更快节奏倒序收起。卡片高度随之变化：收起时只剩标题与一行站点摘要，展开时随级联弹开，收起时等折叠完才缩回。箭头旋转 180°，每次切换轻触一下。"
        ),
        implementation: L(
            "Each row animates scale, opacity, offset and blur with its own .animation(spring.delay(index × stagger), value: open), flipping the order when closing; the rows' natural height is measured with onGeometryChange and the clipped container animates between 0 and that height.",
            "每行使用各自的 .animation(spring.delay(序号 × 错峰), value: open) 驱动缩放、透明度、偏移与模糊，收起时反转顺序；用 onGeometryChange 测得时间轴自然高度，裁剪容器在 0 与该高度之间做动画。"
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
    /// Natural height of the timeline, measured so the card can animate between summary and full size.
    @State private var rowsHeight: CGFloat = 230

    private var zh: Bool { ctx.language == .zh }

    var body: some View {
        SignatureStage {
            VStack(spacing: 0) {
                // Spacing lives inside the summary and the timeline, so a collapsed card has no dangling gap.
                VStack(alignment: .leading, spacing: 0) {
                    header
                    if !open {
                        summary
                            .padding(.top, 14)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                    rows
                }
                .padding(18)
                .frame(width: 290, alignment: .top)
                .signatureCard()
                .contentShape(Rectangle())
                .onTapGesture(perform: toggle)
                Spacer(minLength: 0)
                DemoHint(text: L("Tap the card to fold or unfold", "点击卡片展开或收起"), ctx: ctx)
                    .padding(.bottom, 14)
            }
            .padding(.top, ctx.isPreview ? 6 : 26)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        // In the detail stage the one-shot intro play unfolds the card once on arrival.
        .autoplay(ctx.isPreview, every: 2.6, delay: 0.3) { toggle() }
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

    /// Collapsed state: one line with the four stop glyphs, so the closed card is compact, not half-empty.
    private var summary: some View {
        HStack(spacing: 6) {
            ForEach(Array(TravelItineraryStop.all.enumerated()), id: \.offset) { _, stop in
                Image(systemName: stop.symbol)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(stop.tint)
                    .frame(width: 24, height: 24)
                    .background(stop.tint.opacity(0.16), in: Circle())
            }
            Text(zh ? "4 站 · 威尼斯 → 塞切达" : "4 stops · Venice → Seceda")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(Signature.textSecondary)
                .lineLimit(1)
                .padding(.leading, 4)
            Spacer(minLength: 0)
        }
    }

    private var closeDuration: Double {
        let count = Double(TravelItineraryStop.all.count - 1)
        return count * ctx["stagger"] * 0.6 + 0.2
    }

    private var rows: some View {
        rowStack
            .padding(.top, 14)
            .fixedSize(horizontal: false, vertical: true)
            .onGeometryChange(for: CGFloat.self) { proxy in
                proxy.size.height
            } action: { height in
                rowsHeight = height
            }
            .frame(height: open ? rowsHeight : 0, alignment: .top)
            .clipped()
            // Grow right away when opening; wait for the reverse fold before shrinking when closing.
            .animation(.spring(response: 0.45, dampingFraction: 0.86).delay(open ? 0 : closeDuration), value: open)
    }

    private var rowStack: some View {
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
        withAnimation(.easeInOut(duration: 0.25).delay(open ? closeDuration : 0)) { open.toggle() }
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
