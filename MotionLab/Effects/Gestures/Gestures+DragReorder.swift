import SwiftUI

extension Effect {
    static let gesturesDragReorder = Effect(
        id: "gestures.drag-reorder",
        category: .gestures,
        interaction: .gesture,
        name: L("Drag to Reorder", "拖拽排序"),
        summary: L("Lift a row by its handle; neighbors slide aside as it passes.", "按住把手提起一行，经过时相邻行自动让位。"),
        prompt: L(
            "A vertical list of five 50 pt rows (16 pt continuous corners, tinted icon, label and a grip handle on the right) spaced 8 pt apart. Pressing the handle lifts the row: it scales to 104%, its shadow deepens from 4 pt to 18 pt blur and it rises above the others with a light haptic. The row tracks the finger vertically 1:1 while every row it passes slides one slot up or down on a spring (response 0.3 s, damping 0.8), with a selection tick each time the target slot changes. On release the lifted row glides into its slot and the model reorders in the same spring (response ≈ 0.38 s), so nothing ever jumps. Precise, calm and satisfying.",
            "一个由五行组成的竖向列表，每行高50pt（16pt连续圆角、彩色图标、文字与右侧拖动把手），行距8pt。按住把手即“提起”该行：放大到104%，投影模糊从4pt加深到18pt，浮于其他行之上，并伴随轻触感。该行在竖直方向1:1跟手，所经过的每一行都以弹簧（响应0.3秒、阻尼0.8）上移或下移一格让位，目标槽位每次变化都有一次选择触感。松手后，被提起的行滑入目标槽位，数据重排在同一弹簧（响应约0.38秒）中完成，全程没有任何跳变。精准、沉稳、令人满足。"
        ),
        implementation: L(
            "A DragGesture on the handle (global coordinate space, so the moving row doesn’t feed back into the translation) computes a target index; other rows get ±slot offsets, and onEnded moves the element in the array inside withAnimation.",
            "把手上的 DragGesture 使用全局坐标系（避免行自身移动干扰位移），据此计算目标索引；其他行获得 ±一格偏移，onEnded 在 withAnimation 中移动数组元素。"
        ),
        apis: ["DragGesture", "ForEach", "offset", "zIndex", "withAnimation"],
        tags: ["reorder", "drag and drop", "sort", "list", "handle", "拖拽排序", "排序", "列表", "重排"],
        params: [
            .slider("response", L("Spring response", "弹簧响应"), 0.15...0.7, default: 0.3, unit: "s"),
            .slider("lift", L("Lift scale", "提起缩放"), 1.0...1.1, default: 1.04),
        ]
    ) { ctx in
        DragReorderDemo(ctx: ctx)
    }
}

private struct ReorderItem: Identifiable, Equatable {
    let id: Int
    let title: LocalizedText
    let symbol: String
    let tint: Color
}

private let reorderSeed: [ReorderItem] = [
    ReorderItem(id: 0, title: L("Inbox", "收件箱"), symbol: "tray.fill", tint: Palette.blue),
    ReorderItem(id: 1, title: L("Today", "今天"), symbol: "star.fill", tint: Palette.amber),
    ReorderItem(id: 2, title: L("Upcoming", "计划"), symbol: "calendar", tint: Palette.coral),
    ReorderItem(id: 3, title: L("Projects", "项目"), symbol: "square.stack.3d.up.fill", tint: Palette.violet),
    ReorderItem(id: 4, title: L("Archive", "归档"), symbol: "archivebox.fill", tint: Palette.mint),
]

private struct DragReorderDemo: View {
    let ctx: DemoContext
    @State private var order = reorderSeed
    @State private var draggingID: Int?
    @State private var dragFrom = 0
    @State private var dragY: CGFloat = 0
    @State private var target = 0
    /// The scripted (preview / intro) drag, cancelled on the first real touch and on disappear.
    @State private var script: Task<Void, Never>?
    /// True while a real finger holds a handle.
    @State private var held = false

    private let rowHeight: CGFloat = 50
    private let spacing: CGFloat = 8
    private var slot: CGFloat { rowHeight + spacing }

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: spacing) {
                ForEach(Array(order.enumerated()), id: \.element.id) { index, item in
                    ReorderRow(
                        item: item,
                        language: ctx.language,
                        isLifted: draggingID == item.id,
                        lift: ctx.cg("lift"),
                        onChanged: { dy in userChanged(id: item.id, dy: dy) },
                        onEnded: { completed in userEnded(completed: completed) }
                    )
                    .frame(height: rowHeight)
                    .offset(y: rowOffset(index: index, id: item.id))
                    .zIndex(draggingID == item.id ? 1 : 0)
                }
            }
            .frame(width: 280)
            DemoHint(text: L("Drag a row by its handle", "按住右侧把手拖动"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 2.2, delay: 0.4) { autoDrag() }
        .onDisappear { settleNow() }
    }

    private func rowOffset(index: Int, id: Int) -> CGFloat {
        guard let draggingID else { return 0 }
        if id == draggingID { return dragY }
        if dragFrom < index && index <= target { return -slot }
        if target <= index && index < dragFrom { return slot }
        return 0
    }

    /// A real finger: the first event takes over from a scripted drag (landing it at once), then drives the row.
    private func userChanged(id: Int, dy: CGFloat) {
        if !held {
            held = true
            if script != nil {
                script?.cancel()
                script = nil
                ended()
            }
        }
        guard draggingID == nil || draggingID == id else { return }
        guard let index = order.firstIndex(where: { $0.id == id }) else { return }
        changed(id: id, index: index, dy: dy)
    }

    /// Single, guarded end of a real drag. A lift commits the move; a system cancellation
    /// (e.g. the page scroll stealing the vertical drag) never does.
    private func userEnded(completed: Bool) {
        guard held else { return }
        held = false
        if completed { ended() } else { cancelDrag() }
    }

    /// Cancelled drag: the lifted row and its neighbours spring back to their slots, order unchanged, silently.
    private func cancelDrag() {
        guard draggingID != nil else { return }
        withAnimation(.spring(response: ctx["response"] + 0.08, dampingFraction: 0.78)) {
            target = dragFrom
            draggingID = nil
            dragY = 0
        }
    }

    /// Leaving the screen: stop the script and drop any lifted row back without reordering.
    private func settleNow() {
        script?.cancel()
        script = nil
        held = false
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            draggingID = nil
            dragY = 0
        }
    }

    private func changed(id: Int, index: Int, dy: CGFloat) {
        if draggingID == nil {
            dragFrom = index
            target = index
            withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) { draggingID = id }
            if !ctx.isPreview { Haptics.tap(.light) }
        }
        dragY = dy
        let raw = (CGFloat(dragFrom) * slot + dy) / slot
        let next = Int(raw.rounded()).clamped(to: 0...(order.count - 1))
        if next != target {
            withAnimation(.spring(response: ctx["response"], dampingFraction: 0.8)) { target = next }
            if !ctx.isPreview { Haptics.selection() }
        }
    }

    private func ended() {
        guard draggingID != nil else { return }
        let from = dragFrom
        let to = target
        withAnimation(.spring(response: ctx["response"] + 0.08, dampingFraction: 0.78)) {
            let item = order.remove(at: from)
            order.insert(item, at: to)
            draggingID = nil
            dragY = 0
        }
    }

    private func autoDrag() {
        guard order.count > 1, !held, draggingID == nil else { return }
        let from = Int.random(in: 0..<order.count)
        var to = Int.random(in: 0..<order.count)
        if to == from { to = (from + 2) % order.count }
        let id = order[from].id
        changed(id: id, index: from, dy: 0)
        let distance = CGFloat(to - from) * slot
        withAnimation(.easeInOut(duration: 0.7)) {
            dragY = distance
            target = to
        }
        script?.cancel()
        script = Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.8))
            guard !Task.isCancelled else { return }
            script = nil
            ended()
        }
    }
}

private struct ReorderRow: View {
    let item: ReorderItem
    let language: AppLanguage
    let isLifted: Bool
    let lift: CGFloat
    let onChanged: (CGFloat) -> Void
    /// `true` for a lift, `false` for a system cancellation.
    let onEnded: (Bool) -> Void
    /// Resets on system cancellation too, so a stolen touch still drops the row (the demo guards double ends).
    @GestureState private var pressing = false

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(item.tint.gradient)
                .frame(width: 30, height: 30)
                .overlay {
                    Image(systemName: item.symbol)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                }
            Text(item.title, language)
                .font(.subheadline.weight(.semibold))
            Spacer()
            handle
        }
        .padding(.leading, 10)
        .frame(maxHeight: .infinity)
        .background(Palette.elevated, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Palette.stroke, lineWidth: 1))
        .shadow(color: .black.opacity(isLifted ? 0.18 : 0.05), radius: isLifted ? 18 : 4, y: isLifted ? 12 : 2)
        .scaleEffect(isLifted ? lift : 1)
    }

    private var handle: some View {
        Image(systemName: "line.3.horizontal")
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(isLifted ? AnyShapeStyle(item.tint) : AnyShapeStyle(.tertiary))
            .frame(width: 48, height: 50)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .global)
                    .updating($pressing) { _, state, _ in state = true }
                    .onChanged { value in onChanged(value.translation.height) }
                    .onEnded { _ in onEnded(true) }
            )
            .onChange(of: pressing) { _, isPressing in
                if !isPressing { onEnded(false) }
            }
    }
}
