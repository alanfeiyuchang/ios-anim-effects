import SwiftUI

extension Effect {
    static let gesturesSwipeComplete = Effect(
        id: "gestures.swipe-complete",
        category: .gestures,
        interaction: .gesture,
        name: L("Swipe to Complete", "右滑完成任务"),
        summary: L("Swipe a task right past a detent: it strikes itself through and sinks to the bottom of the list.", "把任务向右滑过阈值：文字划线勾掉，并沉到列表底部。"),
        prompt: L(
            "Four 58 pt task rows (18 pt continuous corners, elevated surface, round checkbox, title, tinted dot). Dragging a row right slides it over a green well whose opacity rises with the pull while a checkmark scales from 60% to 100%. At 110 pt the row arms: the glyph fills with a bounce and a medium haptic clicks; beyond that the row resists with a rubber band. Released while armed, the row springs home (response 0.35 s, damping 0.75), its checkbox fills, a 1.5 pt line draws across the title left to right over 300 ms and the text fades to 40%; 450 ms later the row glides to the bottom of the list while the others slide up to close the gap. Swiping a finished task over an amber well restores it to the top. Satisfying, list-native closure.",
            "四条高 58pt 的任务行（18pt 连续圆角、浮起表面、圆形复选框、标题与彩色小圆点）。向右拖动某行时，它滑过下方的绿色底槽，底槽不透明度随拉动增加，对勾图标从 60% 放大到 100%。拉到 110pt 时进入“就绪”：图标填充并弹跳一下，伴随一次中等触感；再往后则有橡皮筋阻力。就绪状态下松手，该行以弹簧（响应 0.35 秒、阻尼 0.75）回位，复选框填满，一条 1.5pt 的线在 300ms 内从左到右划过标题，文字淡到 40%；450ms 后该行滑到列表底部，其余各行上移补位。已完成的任务滑过琥珀色底槽即可恢复并回到顶部。干净利落，完成感十足。"
        ),
        implementation: L(
            "Rows own a horizontal DragGesture run with simultaneousGesture so vertical page scrolling still works; the parent stores offsets, flips done inside withAnimation and then reorders the array in a second spring so ForEach animates the move. sensoryFeedback fires when the armed flag flips on.",
            "每行挂载与页面滚动并行的水平 DragGesture（simultaneousGesture），竖向滚动不受影响；父视图保存偏移量，在 withAnimation 中切换完成状态，再用第二段弹簧重排数组，让 ForEach 动画化行的移动。就绪标记变为 true 时由 sensoryFeedback 触发触感。"
        ),
        apis: ["DragGesture", "simultaneousGesture", "sensoryFeedback", "symbolEffect(.bounce)", "scaleEffect(x:anchor:)", "ForEach"],
        tags: ["swipe", "complete", "todo", "strikethrough", "list", "右滑", "完成", "待办", "删除线"],
        params: [
            .slider("threshold", L("Arm distance", "就绪距离"), 70...160, default: 110, step: 1, decimals: 0, unit: "pt"),
            .slider("sinkDelay", L("Sink delay", "下沉延迟"), 0.1...1.0, default: 0.45, unit: "s"),
        ]
    ) { ctx in
        SwipeCompleteDemo(ctx: ctx)
    }
}

private struct CompleteTask: Identifiable, Equatable {
    let id: Int
    let title: LocalizedText
    let tint: Color
    var done: Bool
}

private let completeSeed: [CompleteTask] = [
    CompleteTask(id: 0, title: L("Book flights", "订机票"), tint: Palette.sky, done: false),
    CompleteTask(id: 1, title: L("Review designs", "评审设计稿"), tint: Palette.violet, done: false),
    CompleteTask(id: 2, title: L("Water the plants", "给植物浇水"), tint: Palette.mint, done: false),
    CompleteTask(id: 3, title: L("Call the bank", "给银行打电话"), tint: Palette.coral, done: false),
]

private struct SwipeCompleteDemo: View {
    let ctx: DemoContext
    @State private var items = completeSeed
    @State private var offsets: [Int: CGFloat] = [:]

    var body: some View {
        let threshold = ctx.cg("threshold")
        VStack(spacing: 10) {
            ForEach(items) { item in
                CompleteRow(
                    item: item,
                    offset: offsets[item.id] ?? 0,
                    threshold: threshold,
                    ctx: ctx,
                    onDrag: { offsets[item.id] = $0 },
                    onEnd: { finish(item.id) }
                )
            }
            DemoHint(text: L("Swipe a task to the right", "把任务向右滑"), ctx: ctx)
                .padding(.top, 6)
        }
        .frame(width: 300)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.8) { autoStep() }
    }

    private func finish(_ id: Int) {
        let armed = (offsets[id] ?? 0) >= ctx.cg("threshold")
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            offsets[id] = 0
            if armed, let index = items.firstIndex(where: { $0.id == id }) {
                items[index].done.toggle()
            }
        }
        guard armed else { return }
        if !ctx.isPreview { Haptics.success() }
        let delay = ctx["sinkDelay"]
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(delay))
            withAnimation(.spring(response: 0.5, dampingFraction: 0.82)) { resort(id) }
        }
    }

    /// Finished tasks sink to the bottom; restored ones float back to the top.
    private func resort(_ id: Int) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        let item = items.remove(at: index)
        if item.done {
            items.append(item)
        } else {
            items.insert(item, at: 0)
        }
    }

    private func autoStep() {
        guard let next = items.first(where: { !$0.done }) else {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) { items = completeSeed }
            return
        }
        withAnimation(.easeOut(duration: 0.45)) { offsets[next.id] = ctx.cg("threshold") + 18 }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.5))
            finish(next.id)
        }
    }
}

private struct CompleteRow: View {
    let item: CompleteTask
    let offset: CGFloat
    let threshold: CGFloat
    let ctx: DemoContext
    let onDrag: (CGFloat) -> Void
    let onEnd: () -> Void
    @State private var tracking = false

    var body: some View {
        let progress = min(max(offset / max(threshold, 1), 0), 1)
        let armed = offset >= threshold
        ZStack(alignment: .leading) {
            well(progress: progress, armed: armed)
            content
                .offset(x: offset)
                .simultaneousGesture(dragGesture)
        }
        .frame(height: 58)
        .sensoryFeedback(.impact(weight: .medium), trigger: armed) { _, newValue in
            newValue && !ctx.isPreview
        }
    }

    private func well(progress: CGFloat, armed: Bool) -> some View {
        let color = item.done ? Palette.amber : Palette.green
        return RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(color.opacity(0.15 + 0.85 * Double(progress)))
            .overlay(alignment: .leading) {
                Image(systemName: item.done ? "arrow.uturn.backward.circle.fill" : (armed ? "checkmark.circle.fill" : "checkmark.circle"))
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.white)
                    .symbolEffect(.bounce, value: armed)
                    .scaleEffect(0.6 + 0.4 * progress)
                    .padding(.leading, 18)
            }
    }

    private var content: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .strokeBorder(item.done ? Palette.green : Color.primary.opacity(0.25), lineWidth: 2)
                Circle()
                    .fill(Palette.green)
                    .padding(4)
                    .scaleEffect(item.done ? 1 : 0.01)
                    .opacity(item.done ? 1 : 0)
            }
            .frame(width: 22, height: 22)
            Text(item.title, ctx.language)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.primary.opacity(item.done ? 0.4 : 1))
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(Color.primary.opacity(0.55))
                        .frame(height: 1.5)
                        .scaleEffect(x: item.done ? 1 : 0.001, y: 1, anchor: .leading)
                        .animation(.easeInOut(duration: 0.3), value: item.done)
                }
            Spacer(minLength: 4)
            Circle()
                .fill(item.tint)
                .frame(width: 8, height: 8)
        }
        .padding(.horizontal, 16)
        .frame(height: 58)
        .background(Palette.elevated, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Palette.stroke, lineWidth: 1))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { value in
                if !tracking {
                    guard abs(value.translation.width) > abs(value.translation.height) else { return }
                    tracking = true
                }
                let raw = value.translation.width
                if raw < 0 {
                    onDrag(rubberBand(raw, limit: 24))
                } else if raw > threshold {
                    onDrag(threshold + rubberBand(raw - threshold, limit: 70))
                } else {
                    onDrag(raw)
                }
            }
            .onEnded { _ in
                guard tracking else { return }
                tracking = false
                onEnd()
            }
    }
}
