import SwiftUI

extension Effect {
    static let showcaseDateRange = Effect(
        id: "showcase.date-range",
        category: .showcase,
        interaction: .tap,
        name: L("Date Range & Price", "日期区间与总价"),
        summary: L(
            "Pick check-in and check-out: endpoint dots glide, the range band stretches, and the total price rolls.",
            "选择入住与退房：端点圆点滑动、区间色带伸缩，总价数字滚动更新。"
        ),
        prompt: L(
            "A dark booking card shows two weeks of July as a 7-column grid of rounded digits, with a nightly rate and total below. The first tap sets check-in, the second sets check-out. The two endpoint circles (orange gradient, black digits) glide between cells via shared geometry, and a translucent orange capsule band stretches or shrinks behind the days in between, split across week rows, all on one spring (response 0.4 s, damping 0.78). The nights label and the large total price roll to their new values with a numeric content transition. The Reserve pill brightens once a valid range exists. Each tap gives a selection haptic. It feels decisive, informative and smooth.",
            "暗色预订卡片以 7 列网格展示七月的两周日期，数字为圆体，下方是每晚价格与总价。第一次点击设入住日，第二次设退房日。两个端点圆（橙色渐变、黑色数字）通过共享几何在格子间滑动，一条半透明橙色胶囊色带在中间日期背后伸缩，跨周时分行显示，整体使用同一弹簧（响应 0.4 秒、阻尼 0.78）。晚数和醒目的总价用数字滚动过渡更新到新值。选出有效区间后，「预订」按钮随之点亮。每次点击都有选择触感。整体果断、信息清晰、过渡顺滑。"
        ),
        implementation: L(
            "Endpoint circles are matchedGeometryEffect backgrounds inside the start and end DayCells; each week row draws one Capsule whose width and x-offset come from the range's intersection with that row, all animated with one spring. Prices use contentTransition(.numericText(value:)).",
            "端点圆是入住、退房日期格中的 matchedGeometryEffect 背景；每个周行绘制一枚 Capsule，其宽度与横向偏移由区间与该行的交集计算，并由同一弹簧驱动；价格使用 contentTransition(.numericText(value:))。"
        ),
        apis: ["matchedGeometryEffect", "contentTransition(.numericText)", "Text(_:format:)", "spring(response:dampingFraction:)"],
        tags: ["calendar", "date range", "booking", "price", "日历", "日期区间", "预订", "价格"],
        params: [
            .slider("rate", L("Nightly rate", "每晚价格"), 80...400, default: 186, step: 1, decimals: 0),
            .slider("response", L("Spring response", "弹簧响应"), 0.2...0.8, default: 0.4, unit: "s"),
            .slider("damping", L("Damping", "阻尼"), 0.5...1, default: 0.78),
        ]
    ) { ctx in
        TravelDateRangeDemo(ctx: ctx)
    }
}

// MARK: - Model

private enum TravelDayRole {
    case idle, start, end, inside

    var isEndpoint: Bool { self == .start || self == .end }
}

// MARK: - Demo

private struct TravelDateRangeDemo: View {
    let ctx: DemoContext
    @Namespace private var ns
    @State private var start = 2
    @State private var end = 5
    @State private var pickingEnd = false
    @State private var demoStep = 0

    /// July 6, 2026 is a Monday.
    private static let firstDay = 6
    private static let cell: CGFloat = 38
    private static let presets: [(Int, Int)] = [(1, 4), (3, 9), (8, 12), (0, 2), (2, 5)]

    private var zh: Bool { ctx.language == .zh }
    private var spring: Animation { .spring(response: ctx["response"], dampingFraction: ctx["damping"]) }
    private var nights: Int { max(end - start, 0) }
    private var rate: Int { Int(ctx["rate"].rounded()) }
    private var total: Int { nights * rate }

    var body: some View {
        SignatureStage {
            VStack(alignment: .leading, spacing: 12) {
                header
                weekdays
                VStack(spacing: 6) {
                    ForEach(0..<2, id: \.self) { week in
                        TravelWeekRow(
                            week: week,
                            start: start,
                            end: end,
                            cell: Self.cell,
                            firstDay: Self.firstDay,
                            ns: ns,
                            onTap: tap
                        )
                    }
                }
                footer
            }
            .padding(16)
            .frame(width: 7 * Self.cell + 32)
            .signatureCard()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .autoplay(ctx.isPreview, every: 1.6) {
            let preset = Self.presets[demoStep % Self.presets.count]
            demoStep += 1
            withAnimation(spring) {
                start = preset.0
                end = preset.1
            }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(zh ? "2026 年 7 月" : "July 2026")
                    .signatureEyebrow()
                Text(zh ? "蔚蓝海岸 · 海景房" : "Azure Coast · Sea view")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white)
            }
            Spacer(minLength: 0)
            Text(pickingEnd ? (zh ? "选择退房" : "Pick check-out") : (zh ? "选择入住" : "Pick check-in"))
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(Signature.accent)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Signature.accent.opacity(0.14), in: Capsule())
        }
    }

    private var weekdays: some View {
        let names = zh ? ["一", "二", "三", "四", "五", "六", "日"] : ["M", "T", "W", "T", "F", "S", "S"]
        return HStack(spacing: 0) {
            ForEach(0..<7, id: \.self) { index in
                Text(names[index])
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(Signature.textSecondary)
                    .frame(width: Self.cell)
            }
        }
    }

    private var footer: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 0) {
                Text(zh ? "\(nights) 晚 · ¥\(rate)/晚" : "\(nights) nights · $\(rate)/night")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(Signature.textSecondary)
                    .contentTransition(.numericText(value: Double(nights)))
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(zh ? "¥" : "$")
                        .font(Signature.number(15))
                    Text(total, format: .number)
                        .font(Signature.number(28))
                        .contentTransition(.numericText(value: Double(total)))
                }
                .foregroundStyle(Color.white)
            }
            Spacer(minLength: 0)
            Text(zh ? "预订" : "Reserve")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(nights > 0 ? Color.black : Signature.textSecondary)
                .padding(.horizontal, 18)
                .frame(height: 38)
                .background(
                    nights > 0 ? AnyShapeStyle(Signature.accentGradient) : AnyShapeStyle(Color.white.opacity(0.08)),
                    in: Capsule()
                )
                .animation(.easeInOut(duration: 0.25), value: nights > 0)
        }
    }

    private func tap(_ index: Int) {
        if !ctx.isPreview { Haptics.selection() }
        withAnimation(spring) {
            if pickingEnd && index > start {
                end = index
                pickingEnd = false
            } else {
                start = index
                end = index
                pickingEnd = true
            }
        }
    }
}

// MARK: - Week row

private struct TravelWeekRow: View {
    let week: Int
    let start: Int
    let end: Int
    let cell: CGFloat
    let firstDay: Int
    let ns: Namespace.ID
    let onTap: (Int) -> Void

    /// Columns (inclusive) of this row covered by the range, if any.
    private var span: (lo: Int, hi: Int)? {
        let lo = max(start, week * 7)
        let hi = min(end, week * 7 + 6)
        return lo <= hi ? (lo - week * 7, hi - week * 7) : nil
    }

    var body: some View {
        ZStack(alignment: .leading) {
            band
            HStack(spacing: 0) {
                ForEach(0..<7, id: \.self) { column in
                    let index = week * 7 + column
                    TravelDayCell(day: firstDay + index, role: role(for: index), size: cell, ns: ns)
                        .onTapGesture { onTap(index) }
                }
            }
        }
    }

    private var band: some View {
        let range = span ?? (lo: 0, hi: 0)
        return Capsule()
            .fill(Signature.accent.opacity(0.2))
            .frame(width: CGFloat(range.hi - range.lo + 1) * cell, height: cell - 4)
            .offset(x: CGFloat(range.lo) * cell)
            .opacity(span == nil ? 0 : 1)
    }

    private func role(for index: Int) -> TravelDayRole {
        if index == start { return .start }
        if index == end { return .end }
        if index > start && index < end { return .inside }
        return .idle
    }
}

private struct TravelDayCell: View {
    let day: Int
    let role: TravelDayRole
    let size: CGFloat
    let ns: Namespace.ID

    private var textColor: Color {
        switch role {
        case .start, .end: return Color.black
        case .inside: return Color.white
        case .idle: return Color.white.opacity(0.62)
        }
    }

    var body: some View {
        Text("\(day)")
            .font(.system(size: 14, weight: role == .idle ? .medium : .bold, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(textColor)
            .frame(width: size, height: size)
            .background {
                if role == .start {
                    endpoint.matchedGeometryEffect(id: "start", in: ns)
                } else if role == .end {
                    endpoint.matchedGeometryEffect(id: "end", in: ns)
                }
            }
            .contentShape(Rectangle())
    }

    private var endpoint: some View {
        Circle()
            .fill(Signature.accentGradient)
            .padding(2)
            .shadow(color: Signature.accent.opacity(0.5), radius: 6)
    }
}
