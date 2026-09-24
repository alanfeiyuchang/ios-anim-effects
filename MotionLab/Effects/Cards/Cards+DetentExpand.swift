import SwiftUI

extension Effect {
    static let cardsDetentExpand = Effect(
        id: "cards.detent-expand",
        category: .cards,
        interaction: .gesture,
        name: L("Detent Pull-Down Card", "档位下拉卡片"),
        summary: L("Pull a card down to grow it through three snapping heights, with rubber-band edges and ticks.", "向下拖动卡片，让它在三个吸附高度间伸缩，边缘带橡皮筋阻尼与触感。"),
        prompt: L(
            "A 280 pt-wide order card shows a compact summary above a small grab handle. Dragging anywhere on the card stretches the card 1:1 between three detents — 112, 196 and 280 pt tall — and past the smallest or largest it resists with a rubber-band curve (≈55% coefficient over 60 pt). Rows of detail appear progressively: each fades and slides in as the card grows past its line. On release, the predicted end height picks the nearest detent and the card springs there (response 0.42 s, damping 0.78) with a rigid haptic when it lands on a new detent; the handle widens from 36 to 48 pt while grabbed. Precise, physical and controllable, like an iOS sheet in miniature.",
            "一张280 pt宽的订单卡片，上为精简摘要，下为小拖动把手。在卡片上任意位置拖动，卡片在三个档位——112、196、280 pt高——之间1:1伸缩，拉过最小或最大档位时会以橡皮筋曲线产生阻力（系数约55%，作用范围60 pt）。详情行逐步出现：卡片长到哪一行，哪一行就淡入滑出。松手时根据预测的结束高度选择最近的档位，卡片以弹簧（响应0.42秒、阻尼0.78）吸附过去，落到新档位时伴随清脆触感；拖动时把手从36 pt变宽到48 pt。像迷你版iOS面板。"
        ),
        implementation: L(
            "A DragGesture adds the translation to the height at gesture start, applying rubberBand beyond the outer detents; onEnded uses predictedEndTranslation to choose a detent. Each detail row's opacity and offset are derived from the live height.",
            "DragGesture 把位移叠加到手势开始时的高度上，超出最外侧档位时应用 rubberBand；onEnded 使用 predictedEndTranslation 选择档位。每一行详情的透明度与偏移都由实时高度推导。"
        ),
        apis: ["DragGesture", "predictedEndTranslation", "rubberBand", "frame(height:)", "spring(response:dampingFraction:)"],
        tags: ["detent", "expand", "sheet", "drag", "档位", "展开", "面板", "拖动"],
        params: [
            .slider("response", L("Snap response", "吸附响应"), 0.2...0.9, default: 0.42, unit: "s"),
            .slider("damping", L("Snap damping", "吸附阻尼"), 0.4...1.0, default: 0.78),
            .toggle("rubber", L("Rubber-band edges", "橡皮筋边缘"), default: true),
        ]
    ) { ctx in
        CardsDetentDemo(ctx: ctx)
    }
}

private let cardsDetents: [CGFloat] = [112, 196, 280]

private struct CardsDetentDemo: View {
    let ctx: DemoContext
    @State private var height: CGFloat = 112
    @State private var startHeight: CGFloat?
    @State private var detent = 0
    @State private var step = 0
    /// True while the autoplay script drives the card, so simulated snaps never buzz.
    @State private var scripted = false
    /// The scripted overshoot-and-snap, cancelled on the first real touch.
    @State private var script: Task<Void, Never>?
    /// Resets on system cancellation too, so a stolen touch never leaves the card between detents.
    @GestureState private var pressing = false

    var body: some View {
        VStack(spacing: 14) {
            // 280 pt top detent + room for the rubber band above it (≤ 60 pt, ~30–40 pt in practice).
            card
                .frame(height: 330, alignment: .top)
            DemoHint(text: L("Drag the card down", "向下拖动卡片"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: detent) {
            if !ctx.isPreview && !scripted { Haptics.tap(.rigid) }
        }
        .autoplay(ctx.isPreview, every: 1.4) { autoStep() }
        .onChange(of: pressing) { _, isPressing in
            if !isPressing { endHold() }
        }
        .onDisappear { script?.cancel() }
    }

    private var card: some View {
        VStack(spacing: 0) {
            CardsDetentSummary(language: ctx.language)
                .frame(height: 76)
            ForEach(0..<CardsDetentRow.rows.count, id: \.self) { i in
                // Fully shown once the card is tall enough for the whole row; starts 20 pt earlier.
                let rowBottom: CGFloat = 76 + CGFloat(i + 1) * 42
                let reveal = ((height - 24 - rowBottom) / 20 + 1).clamped(to: 0...1)
                CardsDetentRow(index: i, language: ctx.language)
                    .opacity(Double(reveal))
                    .offset(y: (1 - reveal) * -8)
            }
            Spacer(minLength: 0)
        }
        .frame(width: 280, height: max(height - 24, 60), alignment: .top)
        .clipped()
        .overlay(alignment: .bottom) { handle.offset(y: 20) }
        .padding(.bottom, 24)
        .background(Palette.elevated, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(Palette.stroke))
        .shadow(color: .black.opacity(0.12), radius: 18, y: 10)
        .gesture(drag)
    }

    private var handle: some View {
        Capsule()
            .fill(Color.primary.opacity(startHeight == nil ? 0.2 : 0.35))
            .frame(width: startHeight == nil ? 36 : 48, height: 5)
            .frame(width: 120, height: 24)
            .contentShape(Rectangle())
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: startHeight == nil)
    }

    private var drag: some Gesture {
        DragGesture()
            .updating($pressing) { _, state, _ in state = true }
            .onChanged { value in
                if startHeight == nil {
                    startHeight = height
                    script?.cancel()
                    script = nil
                }
                let start = startHeight ?? height
                scripted = false
                height = resisted(start + value.translation.height)
            }
            .onEnded { value in
                guard let start = startHeight else { return }
                startHeight = nil
                let projected = start + value.predictedEndTranslation.height
                snap(to: nearestDetent(projected))
            }
    }

    /// System cancellation (no `onEnded`): clear the anchor and snap to the closest detent.
    private func endHold() {
        guard startHeight != nil else { return }
        startHeight = nil
        snap(to: nearestDetent(height))
    }

    private func resisted(_ raw: CGFloat) -> CGFloat {
        let low = cardsDetents[0]
        let high = cardsDetents[cardsDetents.count - 1]
        guard ctx.bool("rubber") else { return raw.clamped(to: low...high) }
        if raw < low { return low + rubberBand(raw - low, limit: 60) }
        if raw > high { return high + rubberBand(raw - high, limit: 60) }
        return raw
    }

    private func nearestDetent(_ value: CGFloat) -> Int {
        var best = 0
        for (i, candidate) in cardsDetents.enumerated() where abs(candidate - value) < abs(cardsDetents[best] - value) {
            best = i
        }
        return best
    }

    private func snap(to index: Int) {
        detent = index
        withAnimation(.spring(response: ctx["response"], dampingFraction: ctx["damping"])) {
            height = cardsDetents[index]
        }
    }

    private func autoStep() {
        guard startHeight == nil else { return }
        let sequence = [1, 2, 0, 2, 1, 0]
        let next = sequence[step % sequence.count]
        step += 1
        scripted = true
        // Overshoot a little first so the rubber-band and settle read in the preview.
        let target = cardsDetents[next]
        let overshoot: CGFloat = next == 2 ? 26 : (next == 0 ? -20 : 0)
        withAnimation(.easeOut(duration: 0.3)) {
            height = resisted(target + overshoot)
        }
        script?.cancel()
        script = Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.32))
            guard !Task.isCancelled else { return }
            snap(to: next)
        }
    }
}

private struct CardsDetentSummary: View {
    let language: AppLanguage

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "shippingbox.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 42, height: 42)
                .background(Palette.ocean, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(L("Order #4821", "订单 #4821"), language)
                    .font(.subheadline.weight(.semibold))
                Text(L("Arriving tomorrow, 9–11 am", "明天上午 9–11 点送达"), language)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
    }
}

private struct CardsDetentRow: View {
    let index: Int
    let language: AppLanguage

    static let rows: [(symbol: String, title: LocalizedText, value: String)] = [
        ("checkmark.circle.fill", L("Packed", "已打包"), "08:12"),
        ("truck.box.fill", L("Shipped", "已发货"), "10:40"),
        ("building.2.fill", L("At local hub", "到达本地中转"), "18:05"),
        ("house.fill", L("Out for delivery", "派送中"), "—"),
    ]

    var body: some View {
        let row = Self.rows[index]
        HStack(spacing: 10) {
            Image(systemName: row.symbol)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(index < 3 ? Palette.green : Color.secondary)
                .frame(width: 22)
            Text(row.title, language)
                .font(.footnote.weight(.medium))
            Spacer(minLength: 0)
            Text(verbatim: row.value)
                .font(.footnote.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 18)
        .frame(height: 42)
    }
}
