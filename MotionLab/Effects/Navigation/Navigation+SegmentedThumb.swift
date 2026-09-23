import SwiftUI

extension Effect {
    static let navigationSegmentedThumb = Effect(
        id: "navigation.segmented-thumb",
        category: .navigation,
        interaction: .gesture,
        name: L("Segmented Thumb", "分段控件滑块"),
        summary: L(
            "A segmented control whose thumb can be dragged, squishes as it moves and re-inks labels.",
            "可拖拽的分段控件滑块，移动时轻微挤压，并实时为文字重新着色。"
        ),
        prompt: L(
            "A four-segment control (Day / Week / Month / Year) in a soft gray track with 14 pt continuous corners; the selected segment carries a raised white thumb with a subtle shadow. Tapping a segment glides the thumb there on a spring (response ≈0.35 s, damping ≈0.8). Pressing and dragging picks the thumb up: it widens to 106% and flattens to 92% like a squeezed gel, follows the finger with a light interactive spring, and emits a selection tick each time it crosses a segment. Label ink is masked by the thumb itself, so letters turn from secondary gray to bold primary exactly where the thumb edge passes. On release it snaps to the nearest segment and un-squishes; the headline value above rolls with a numeric transition.",
            "一个四段控件（日 / 周 / 月 / 年），浅灰色轨道，连续圆角 14pt；选中段上方是一块带柔和阴影、微微凸起的白色滑块。点击某段时，滑块以弹簧（响应约 0.35 秒、阻尼约 0.8）滑到该位置。按住并拖动时滑块被「拿起」：像被挤压的凝胶一样宽度变为 106%、高度压扁到 92%，以轻盈的交互式弹簧跟手移动，每跨过一个分段触发一次选择触觉。文字颜色由滑块本身作为遮罩决定，滑块边缘经过之处，文字精确地从次级灰变为加粗主色。松手后吸附到最近的分段并恢复形状；上方的数值以数字滚动过渡更新。"
        ),
        implementation: L(
            "A DragGesture(minimumDistance: 0) maps the finger to a thumb offset; a second, bold copy of the labels is masked by a rectangle at the same offset, and the thumb's scale reads a dragging flag.",
            "DragGesture(minimumDistance: 0) 将手指位置映射为滑块偏移；另一份加粗的文字副本以相同偏移的矩形作为遮罩，滑块的缩放读取拖拽状态。"
        ),
        apis: ["DragGesture", "mask(alignment:_:)", "interactiveSpring", "contentTransition(.numericText(value:))"],
        tags: ["segmented control", "picker", "thumb", "drag", "分段控件", "选择器", "滑块", "拖拽"],
        params: [
            .slider("response", L("Spring response", "弹簧响应"), 0.15...0.8, default: 0.35, unit: "s"),
            .slider("damping", L("Damping", "阻尼"), 0.5...1.0, default: 0.8),
            .toggle("squish", L("Squish while dragging", "拖拽时挤压"), default: true),
        ]
    ) { ctx in
        SegmentedThumbDemo(ctx: ctx)
    }
}

private let segmentTitles: [LocalizedText] = [L("Day", "日"), L("Week", "周"), L("Month", "月"), L("Year", "年")]
private let segmentValues: [Int] = [8_420, 52_310, 214_880, 2_604_119]

private struct SegmentedThumbDemo: View {
    let ctx: DemoContext
    @State private var selected = 0
    @State private var dragX: CGFloat?
    @State private var hovered = 0
    @State private var token = 0
    /// Resets on system cancellation too, so a cancelled drag never leaves the thumb lifted off-segment.
    @GestureState private var touching = false

    private let width: CGFloat = 300
    private let inset: CGFloat = 4
    private var segmentWidth: CGFloat { (width - inset * 2) / CGFloat(segmentTitles.count) }
    private var maxX: CGFloat { segmentWidth * CGFloat(segmentTitles.count - 1) }
    private var thumbX: CGFloat { dragX ?? CGFloat(selected) * segmentWidth }
    private var squished: Bool { dragX != nil && ctx.bool("squish") }

    var body: some View {
        VStack(spacing: 30) {
            VStack(spacing: 4) {
                Text(ctx.language == .zh ? "步数" : "Steps")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                Text(segmentValues[selected], format: .number)
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText(value: Double(segmentValues[selected])))
            }
            control
            DemoHint(text: L("Tap or drag the thumb", "点击或拖动滑块"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.6) { simulateDrag() }
    }

    private var control: some View {
        ZStack(alignment: .leading) {
            labels(bold: false)
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Palette.elevated)
                .shadow(color: .black.opacity(0.12), radius: 6, y: 2)
                .frame(width: segmentWidth, height: 36)
                .scaleEffect(x: squished ? 1.06 : 1, y: squished ? 0.92 : 1)
                .offset(x: thumbX)
            labels(bold: true)
                .mask(alignment: .leading) {
                    Rectangle()
                        .frame(width: segmentWidth, height: 36)
                        .offset(x: thumbX)
                }
                .allowsHitTesting(false)
        }
        .padding(inset)
        .frame(width: width, height: 44)
        .background(Color.primary.opacity(0.07), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .contentShape(Rectangle())
        .gesture(drag)
        .onChange(of: touching) { _, active in
            if !active { settleCancelled() }
        }
    }

    private func labels(bold: Bool) -> some View {
        HStack(spacing: 0) {
            ForEach(0..<segmentTitles.count, id: \.self) { index in
                Text(segmentTitles[index], ctx.language)
                    .font(.subheadline.weight(bold ? .semibold : .medium))
                    .foregroundStyle(bold ? Color.primary : Color.secondary)
                    .frame(width: segmentWidth, height: 36)
            }
        }
    }

    private var drag: some Gesture {
        DragGesture(minimumDistance: 0)
            .updating($touching) { _, state, _ in state = true }
            .onChanged { value in
                let x = (value.location.x - inset - segmentWidth / 2).clamped(to: 0...maxX)
                if dragX == nil {
                    token += 1 // a real finger cancels a simulated drag
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { dragX = x }
                } else {
                    withAnimation(.interactiveSpring(response: 0.18, dampingFraction: 0.86)) { dragX = x }
                }
                let index = Int((x / segmentWidth).rounded())
                if index != hovered {
                    hovered = index
                    if !ctx.isPreview { Haptics.selection() }
                }
            }
            .onEnded { value in
                let x = (value.location.x - inset - segmentWidth / 2).clamped(to: 0...maxX)
                let index = Int((x / segmentWidth).rounded()).clamped(to: 0...(segmentTitles.count - 1))
                withAnimation(.spring(response: ctx["response"], dampingFraction: ctx["damping"])) {
                    selected = index
                    dragX = nil
                }
            }
    }

    /// System cancellation skips `onEnded`: drop the lifted thumb into the segment under it.
    /// After a normal release `dragX` is already nil, so this does nothing.
    private func settleCancelled() {
        guard let x = dragX else { return }
        let index: Int = Int((x / segmentWidth).rounded()).clamped(to: 0...(segmentTitles.count - 1))
        hovered = index
        withAnimation(.spring(response: ctx["response"], dampingFraction: ctx["damping"])) {
            selected = index
            dragX = nil
        }
    }

    /// Autoplay stand-in for a finger: pick the thumb up, drag it slowly across one segment
    /// (showing the squish and the mid-glyph re-ink), then release. Wraps back to Day with a tap.
    private func simulateDrag() {
        let next: Int = (selected + 1) % segmentTitles.count
        guard next != 0 else {
            select(0)
            return
        }
        let from: CGFloat = CGFloat(selected) * segmentWidth
        let to: CGFloat = CGFloat(next) * segmentWidth
        token += 1
        let current = token
        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { dragX = from }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.2))
            guard token == current else { return }
            withAnimation(.easeInOut(duration: 0.6)) { dragX = to }
            try? await Task.sleep(for: .seconds(0.7))
            guard token == current else { return }
            hovered = next
            withAnimation(.spring(response: ctx["response"], dampingFraction: ctx["damping"])) {
                selected = next
                dragX = nil
            }
        }
    }

    private func select(_ index: Int) {
        hovered = index
        withAnimation(.spring(response: ctx["response"], dampingFraction: ctx["damping"])) {
            selected = index
        }
    }
}
