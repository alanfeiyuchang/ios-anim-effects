import SwiftUI

extension Effect {
    static let gesturesDragSelect = Effect(
        id: "gestures.drag-select",
        category: .gestures,
        interaction: .gesture,
        name: L("Drag to Multi-Select", "滑动多选"),
        summary: L("Sweep a finger down the checkbox column to paint a selection across rows, Photos-style.", "手指沿复选框一列滑过，像“照片”那样一口气选中多行。"),
        prompt: L(
            "Five 46 pt message rows (16 pt continuous corners) with a round checkbox column on the left and a “0 selected” pill above. Pressing in the checkbox column and sliding up or down paints a selection: the first row touched decides the mode (select or deselect), and every row between the start and the finger follows it, while rows outside the range revert, exactly like multi-select in Photos. Each row that changes pops its checkmark in on a bouncy spring (response 0.3 s, damping 0.5), tints indigo and shrinks to 97%; a translucent band marks the swept range and a selection haptic ticks per row. The pill counts with a numeric content transition. Fast, fluid, power-user friendly.",
            "五条高46pt的消息行（16pt连续圆角），左侧是一列圆形复选框，上方有“已选0项”的胶囊。在复选框这一列按下并上下滑动即可“刷选”：第一个触到的行决定模式（选中或取消），起点到手指之间的所有行都随之改变，滑回时范围外的行恢复原状——与“照片”的多选完全一致。每一行变化时，对勾以弹性弹簧（响应0.3秒、阻尼0.5）弹出，行背景染上靛蓝并缩小到97%；一条半透明色带标出刷过的范围，每跨过一行触发一次选择触感。胶囊中的计数以数字内容转场滚动。迅捷流畅。"
        ),
        implementation: L(
            "A DragGesture attached only to the checkbox column maps location.y to a row index; the selection is recomputed from a snapshot taken at touch-down plus the swept range, so moving back restores rows. Checkmarks use spring scale transitions; the counter uses contentTransition(.numericText).",
            "DragGesture 只挂在复选框列上，把 location.y 换算为行号；选择结果由按下时的快照加上刷过的范围重新计算，因此往回滑会恢复原状。对勾使用弹簧缩放，计数使用 contentTransition(.numericText)。"
        ),
        apis: ["DragGesture", "contentTransition(.numericText)", "spring(response:dampingFraction:)", "Haptics.selection", "Set"],
        tags: ["multi-select", "drag select", "checkbox", "list", "多选", "滑动选择", "批量", "复选框"],
        params: [
            .slider("damping", L("Pop damping", "弹出阻尼"), 0.3...1.0, default: 0.5),
            .slider("shrink", L("Selected scale", "选中缩放"), 0.9...1.0, default: 0.97),
        ]
    ) { ctx in
        DragSelectDemo(ctx: ctx)
    }
}

private let selectRowHeight: CGFloat = 46
private let selectSpacing: CGFloat = 8
private let selectCount = 5

private struct DragSelectDemo: View {
    let ctx: DemoContext
    @State private var selected: Set<Int> = []
    @State private var baseline: Set<Int> = []
    @State private var start: Int?
    @State private var current: Int?
    @State private var mode = true
    /// True while a real finger sweeps the column.
    @State private var held = false
    /// The scripted sweep, cancelled on the first real touch.
    @State private var script: Task<Void, Never>?
    /// Resets on system cancellation too, so a stolen touch never leaves the band or a stale baseline behind.
    @GestureState private var pressing = false

    private let names: [LocalizedText] = [
        L("Mia · Weekend plan", "米娅 · 周末计划"),
        L("Design review", "设计评审"),
        L("Receipt #2048", "收据 #2048"),
        L("Team lunch", "团队午餐"),
        L("Flight update", "航班变动"),
    ]

    var body: some View {
        VStack(spacing: 12) {
            counter
            ZStack(alignment: .topLeading) {
                rows
                band
                selectionColumn
            }
            .frame(width: 300)
            DemoHint(text: L("Slide down the checkbox column", "沿复选框一列向下滑"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 3.2, delay: 0.5) { simulate() }
        .onChange(of: pressing) { _, isPressing in
            if !isPressing { endHold() }
        }
        .onDisappear { script?.cancel() }
    }

    private var counter: some View {
        let count = selected.count
        return HStack(spacing: 6) {
            Image(systemName: count > 0 ? "checkmark.circle.fill" : "circle.dashed")
                .contentTransition(.symbolEffect(.replace))
            Text(verbatim: "\(count)")
                .monospacedDigit()
                .contentTransition(.numericText(value: Double(count)))
            Text(L("selected", "项已选"), ctx.language)
        }
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(count > 0 ? AnyShapeStyle(Color.white) : AnyShapeStyle(Color.secondary))
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(count > 0 ? AnyShapeStyle(Palette.primary) : AnyShapeStyle(Palette.elevated), in: Capsule())
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: count)
    }

    private var rows: some View {
        VStack(spacing: selectSpacing) {
            ForEach(0..<selectCount, id: \.self) { index in
                SelectRow(
                    title: names[index],
                    tint: Palette.spectrum[index % Palette.spectrum.count],
                    isSelected: selected.contains(index),
                    shrink: ctx.cg("shrink"),
                    damping: ctx["damping"],
                    language: ctx.language
                )
            }
        }
    }

    @ViewBuilder
    private var band: some View {
        if let first = start, let last = current {
            let low = min(first, last)
            let high = max(first, last)
            let pitch = selectRowHeight + selectSpacing
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Palette.indigo.opacity(0.16))
                .frame(width: 40, height: CGFloat(high - low) * pitch + selectRowHeight)
                .offset(x: 2, y: CGFloat(low) * pitch)
                .allowsHitTesting(false)
                .transition(.opacity)
        }
    }

    private var selectionColumn: some View {
        Color.clear
            .frame(width: 44, height: CGFloat(selectCount) * (selectRowHeight + selectSpacing) - selectSpacing)
            .contentShape(Rectangle())
            .gesture(dragGesture)
    }

    private func index(at y: CGFloat) -> Int {
        let raw = Int((y / (selectRowHeight + selectSpacing)).rounded(.down))
        return raw.clamped(to: 0...(selectCount - 1))
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .updating($pressing) { _, state, _ in state = true }
            .onChanged { value in
                let row = index(at: value.location.y)
                if !held {
                    // Every real sweep starts fresh, even over a scripted one still running.
                    held = true
                    script?.cancel()
                    script = nil
                    baseline = selected
                    mode = !selected.contains(row)
                    current = nil
                    withAnimation(.easeOut(duration: 0.15)) { start = row }
                }
                guard row != current else { return }
                apply(to: row, haptic: true)
            }
            .onEnded { _ in endHold() }
    }

    /// Release or system cancellation: close the sweep so the next one starts from a clean baseline.
    private func endHold() {
        guard held else { return }
        held = false
        endSweep()
    }

    private func apply(to row: Int, haptic: Bool) {
        guard let first = start else { return }
        var next = baseline
        for index in min(first, row)...max(first, row) {
            if mode { next.insert(index) } else { next.remove(index) }
        }
        let changed = next != selected
        withAnimation(.spring(response: 0.3, dampingFraction: ctx["damping"])) {
            current = row
            selected = next
        }
        if changed && haptic && !ctx.isPreview { Haptics.selection() }
    }

    private func endSweep() {
        withAnimation(.easeOut(duration: 0.2)) {
            start = nil
            current = nil
        }
        baseline = selected
    }

    private func simulate() {
        guard !held else { return }
        if !selected.isEmpty {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { selected = [] }
            return
        }
        baseline = selected
        mode = true
        let from = Int.random(in: 0...1)
        let to = Int.random(in: 3...4)
        withAnimation(.easeOut(duration: 0.15)) { start = from }
        script?.cancel()
        script = Task { @MainActor in
            for row in from...to {
                guard !Task.isCancelled else { return }
                apply(to: row, haptic: false)
                try? await Task.sleep(for: .seconds(0.16))
            }
            try? await Task.sleep(for: .seconds(0.2))
            guard !Task.isCancelled else { return }
            endSweep()
        }
    }
}

private struct SelectRow: View {
    let title: LocalizedText
    let tint: Color
    let isSelected: Bool
    let shrink: CGFloat
    let damping: Double
    let language: AppLanguage

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .strokeBorder(isSelected ? Palette.indigo : Color.primary.opacity(0.25), lineWidth: 2)
                if isSelected {
                    Circle()
                        .fill(Palette.indigo)
                        .overlay {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .heavy))
                                .foregroundStyle(.white)
                        }
                        .transition(.scale(scale: 0.2).combined(with: .opacity))
                }
            }
            .frame(width: 22, height: 22)
            Circle()
                .fill(tint.gradient)
                .frame(width: 28, height: 28)
            Text(title, language)
                .font(.subheadline.weight(.medium))
                .lineLimit(1)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .frame(height: selectRowHeight)
        .background(
            isSelected ? AnyShapeStyle(Palette.indigo.opacity(0.12)) : AnyShapeStyle(Palette.elevated),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Palette.stroke, lineWidth: 1))
        .scaleEffect(isSelected ? shrink : 1)
    }
}
