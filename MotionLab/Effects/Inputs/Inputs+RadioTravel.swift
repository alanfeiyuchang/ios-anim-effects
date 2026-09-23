import SwiftUI

extension Effect {
    static let inputsRadioTravel = Effect(
        id: "inputs.radio-travel",
        category: .inputs,
        interaction: .tap,
        name: L("Travelling Radio Dot", "游走单选圆点"),
        summary: L("One radio dot stretches like a droplet as it travels to the new option; the row highlight follows.", "唯一的单选圆点像水滴一样拉长着游到新选项，行高亮随后跟上。"),
        prompt: L(
            "A shipping-method list of four rows, each with a 22 pt radio ring, a title, an ETA and a price. There is only one inner dot: choosing another row sends it travelling down (or up) the column of rings. The dot's leading edge leaves first on a fast spring (response 0.28 s, damping 0.8) while its trailing edge follows 90 ms later on a softer one (response 0.42 s, damping 0.7), so it stretches into a capsule up to the full distance and then contracts into the new ring like a droplet. The row highlight — a tinted rounded rectangle — glides behind the selected row on a matched spring, the chosen ring's stroke turns indigo and the total at the bottom rolls to the new price. A selection haptic marks the landing. Fluid, continuous and unmistakably single-choice.",
            "配送方式列表共四行，每行有一个 22pt 的单选圆环、标题、预计送达时间与价格。圆环里的实心圆点只有一个：选择另一行时，它会沿着这一列圆环向下（或向上）“游”过去。圆点的前缘先以快速弹簧（响应 0.28 秒、阻尼 0.8）出发，后缘 90 毫秒后以更柔和的弹簧（响应 0.42 秒、阻尼 0.7）跟上，于是它先被拉成跨越整段距离的胶囊，再像水滴一样收缩进新的圆环。行高亮——一块浅色圆角矩形——以匹配的弹簧滑到所选行背后，被选圆环的描边变为靛蓝，底部总价以数字滚动更新到新价格。落定时触发一次选择触觉。流畅、连续，单选语义一目了然。"
        ),
        implementation: L(
            "The dot is a Capsule spanning two stored y-edges; the edge in the direction of travel is set in one spring transaction and the other in a second, delayed one. The highlight uses matchedGeometryEffect and the price uses contentTransition(.numericText).",
            "圆点是跨越两条已存 y 边缘的 Capsule：朝向运动方向的边缘在第一个弹簧事务中更新，另一条在延迟的第二个事务中更新。行高亮使用 matchedGeometryEffect，价格使用 contentTransition(.numericText)。"
        ),
        apis: ["Capsule", "matchedGeometryEffect", "spring(response:dampingFraction:)", "Task.sleep", "numericText"],
        tags: ["radio", "selection", "droplet", "list", "单选", "选择", "水滴", "列表"],
        params: [
            .slider("lag", L("Tail lag", "尾部延迟"), 0...0.25, default: 0.09, unit: "s"),
            .slider("head", L("Head response", "前缘响应"), 0.15...0.6, default: 0.28, unit: "s"),
            .slider("tail", L("Tail response", "尾部响应"), 0.2...0.8, default: 0.42, unit: "s"),
        ]
    ) { ctx in
        RadioTravelDemo(ctx: ctx)
    }
}

private struct ShippingOption {
    let title: LocalizedText
    let eta: LocalizedText
    let price: Double
}

private struct RadioTravelDemo: View {
    let ctx: DemoContext
    @State private var selected = 1
    // Row 1 is selected initially: its ring centre sits at 1.5 × 56 = 84 pt.
    @State private var topEdge: CGFloat = 79
    @State private var bottomEdge: CGFloat = 89
    @State private var generation = 0
    @State private var step = 0
    @Namespace private var highlight

    private let rowHeight: CGFloat = 56
    private let dot: CGFloat = 10
    private static let previewOrder: [Int] = [3, 0, 2, 1]

    private var options: [ShippingOption] {
        [
            ShippingOption(title: L("Standard", "标准配送"), eta: L("5–7 days", "5–7 天"), price: 0),
            ShippingOption(title: L("Express", "快速配送"), eta: L("2–3 days", "2–3 天"), price: 6),
            ShippingOption(title: L("Next day", "次日达"), eta: L("Tomorrow", "明天送达"), price: 12),
            ShippingOption(title: L("Same day", "当日达"), eta: L("By 9 pm", "今晚 9 点前"), price: 18),
        ]
    }

    private func dotCenter(_ index: Int) -> CGFloat {
        CGFloat(index) * rowHeight + rowHeight / 2
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            card
            Spacer(minLength: 0)
            DemoHint(text: L("Choose another option", "选择另一个选项"), ctx: ctx)
                .padding(.bottom, 14)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.2, delay: 0.4) { previewTick() }
    }

    private var total: Double { 42 + options[selected].price }

    private var card: some View {
        VStack(spacing: 10) {
            ZStack(alignment: .topLeading) {
                VStack(spacing: 0) {
                    ForEach(options.indices, id: \.self) { index in
                        row(index)
                    }
                }
                travellingDot
            }
            Divider()
            HStack {
                Text(L("Total", "合计"), ctx.language)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
                Text(total, format: .currency(code: ctx.language == .zh ? "CNY" : "USD"))
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText(value: total))
                    .animation(.snappy, value: total)
            }
            .font(.subheadline.weight(.semibold).monospacedDigit())
            .padding(.horizontal, 8)
        }
        .padding(12)
        .frame(width: 310)
        .demoCard(cornerRadius: 24)
    }

    private func row(_ index: Int) -> some View {
        let option = options[index]
        let isSelected = index == selected
        return HStack(spacing: 12) {
            Circle()
                .strokeBorder(isSelected ? Palette.indigo : Color.primary.opacity(0.25), lineWidth: 2)
                .frame(width: 22, height: 22)
                .animation(.smooth(duration: 0.25), value: isSelected)
            VStack(alignment: .leading, spacing: 1) {
                Text(option.title, ctx.language)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(option.eta, ctx.language)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            Text(option.price == 0 ? L("Free", "免运费")(ctx.language) : String(format: ctx.language == .zh ? "¥%.0f" : "$%.0f", option.price))
                .font(.subheadline.weight(.medium).monospacedDigit())
                .foregroundStyle(isSelected ? Palette.indigo : Color.secondary)
        }
        .padding(.horizontal, 12)
        .frame(height: rowHeight)
        .background {
            if isSelected {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Palette.indigo.opacity(0.1))
                    .matchedGeometryEffect(id: "highlight", in: highlight)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { choose(index) }
    }

    /// Positioned in the ring column: 12 pt row padding + 11 pt ring radius − half the dot.
    private var travellingDot: some View {
        let height: CGFloat = max(bottomEdge - topEdge, dot)
        return Capsule()
            .fill(Palette.indigo)
            .frame(width: dot, height: height)
            .offset(x: 12 + 11 - dot / 2, y: topEdge)
            .allowsHitTesting(false)
    }

    private func choose(_ index: Int) {
        guard index != selected else { return }
        generation += 1
        let current = generation
        let movingDown = index > selected
        let newTop: CGFloat = dotCenter(index) - dot / 2
        let newBottom: CGFloat = dotCenter(index) + dot / 2
        let head = Animation.spring(response: ctx["head"], dampingFraction: 0.8)
        let tail = Animation.spring(response: ctx["tail"], dampingFraction: 0.7)
        let muted = ctx.isPreview || Haptics.isMuted
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { selected = index }
        withAnimation(head) {
            if movingDown { bottomEdge = newBottom } else { topEdge = newTop }
        }
        Task {
            try? await Task.sleep(for: .seconds(ctx["lag"]))
            guard current == generation else { return }
            withAnimation(tail) {
                if movingDown { topEdge = newTop } else { bottomEdge = newBottom }
            }
            try? await Task.sleep(for: .seconds(0.12))
            if !muted { Haptics.selection() }
        }
    }

    private func previewTick() {
        let target = Self.previewOrder[step % Self.previewOrder.count]
        step += 1
        choose(target)
    }
}
