import SwiftUI

extension Effect {
    static let gesturesSwipeComplete = Effect(
        id: "gestures.swipe-complete",
        category: .gestures,
        interaction: .gesture,
        name: L("Swipe to Complete", "右滑完成任务"),
        summary: L("Swipe a task right past a detent: it strikes itself through and sinks to the bottom of the list.", "把任务向右滑过阈值：文字划线勾掉，并沉到列表底部。"),
        prompt: L(
            "Four 58 pt task rows show a round checkbox, a title and a tinted dot on 18 pt continuous corners. Dragging a row right slides it over a green well whose opacity rises with the pull while a checkmark scales from 60% to 100%; at 110 pt the row arms as the glyph fills with a bounce and a medium haptic clicks, and beyond that it rubber-bands. Released while armed, the row springs home (response 0.35 s, damping 0.75), its checkbox fills, a 1.5 pt line draws across the title left to right over 300 ms and the text fades to 40%; 450 ms later the row glides to the bottom as the others close the gap. Swiping a finished task over an amber well restores it to the top. Satisfying, list-native closure.",
            "四条58 pt高的任务行（18 pt圆角），带圆形复选框、标题和彩色圆点。向右拖某行，它滑过下方绿色底槽，底槽随拉动渐显，对勾从60%放大到100%；拉到110 pt即“就绪”，图标填满并弹一下，伴随中等触感，再往后带橡皮筋阻力。就绪时松手，该行以弹簧（响应0.35秒、阻尼0.75）回位，复选框填满，一条1.5 pt的线在300毫秒内划过标题，文字淡到40%；450毫秒后该行滑到列表底部，其余行上移补位。已完成的任务滑过琥珀色底槽即恢复到顶部。完成感十足。"
        ),
        implementation: L(
            "Rows own a horizontal DragGesture run with simultaneousGesture so vertical page scrolling still works; the parent stores offsets, flips done inside withAnimation and then reorders the array in a second spring so ForEach animates the move. UIImpactFeedbackGenerator fires when the armed flag flips on.",
            "每行挂载与页面滚动并行的水平 DragGesture（simultaneousGesture），竖向滚动不受影响；父视图保存偏移量，在 withAnimation 中切换完成状态，再用第二段弹簧重排数组，让 ForEach 动画化行的移动。就绪标记变为 true 时由 UIImpactFeedbackGenerator 触发触感。"
        ),
        apis: ["DragGesture", "simultaneousGesture", "UIImpactFeedbackGenerator", "symbolEffect(.bounce)", "scaleEffect(x:anchor:)", "ForEach"],
        tags: ["swipe", "complete", "todo", "strikethrough", "右滑", "完成", "待办", "删除线"],
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
    /// True while autoplay (or the detail intro) swipes a task, so its arm click and success stay silent.
    @State private var scripted = false
    /// The scripted swipe's release timer and its row, cancelled on the first real touch and on disappear.
    @State private var script: Task<Void, Never>?
    @State private var scriptRow: Int?

    var body: some View {
        let threshold = ctx.cg("threshold")
        VStack(spacing: 10) {
            ForEach(items) { item in
                CompleteRow(
                    item: item,
                    offset: offsets[item.id] ?? 0,
                    threshold: threshold,
                    ctx: ctx,
                    scripted: scripted,
                    onDrag: {
                        takeOver(from: item.id)
                        scripted = false
                        offsets[item.id] = $0
                    },
                    onEnd: { finish(item.id) },
                    onCancel: { cancelSwipe(item.id) }
                )
            }
            DemoHint(text: L("Swipe a task to the right", "把任务向右滑"), ctx: ctx)
                .padding(.top, 6)
        }
        .frame(width: 300)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.8) { autoStep() }
        .onDisappear { stopScript() }
    }

    private func finish(_ id: Int, haptic: Bool = true) {
        let armed = (offsets[id] ?? 0) >= ctx.cg("threshold")
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            offsets[id] = 0
            if armed, let index = items.firstIndex(where: { $0.id == id }) {
                items[index].done.toggle()
            }
        }
        guard armed else { return }
        if haptic && !ctx.isPreview { Haptics.success() }
        let delay = ctx["sinkDelay"]
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(delay))
            withAnimation(.spring(response: 0.5, dampingFraction: 0.82)) { resort(id) }
        }
    }

    /// A system-cancelled swipe (the page scrolled) completes nothing: the row slides back.
    private func cancelSwipe(_ id: Int) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) { offsets[id] = 0 }
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

    /// A real finger stops the scripted swipe; a different half-swiped scripted row slides back.
    private func takeOver(from id: Int) {
        guard script != nil else { return }
        let row = scriptRow
        stopScript()
        if let row, row != id {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) { offsets[row] = 0 }
        }
    }

    private func stopScript() {
        script?.cancel()
        script = nil
        scriptRow = nil
    }

    private func autoStep() {
        guard let next = items.first(where: { !$0.done }) else {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) { items = completeSeed }
            return
        }
        scripted = true
        withAnimation(.easeOut(duration: 0.45)) { offsets[next.id] = ctx.cg("threshold") + 18 }
        script?.cancel()
        scriptRow = next.id
        script = Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.5))
            guard !Task.isCancelled else { return }
            script = nil
            scriptRow = nil
            finish(next.id, haptic: false)
        }
    }
}

private struct CompleteRow: View {
    let item: CompleteTask
    let offset: CGFloat
    let threshold: CGFloat
    let ctx: DemoContext
    let scripted: Bool
    let onDrag: (CGFloat) -> Void
    let onEnd: () -> Void
    let onCancel: () -> Void
    @State private var tracking = false
    /// Resets on system cancellation too, so a stolen touch never leaves the row mid-reveal.
    @GestureState private var pressing = false

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
        .onChange(of: armed) { _, newValue in
            if newValue && !ctx.isPreview && !scripted { Haptics.tap(.medium) }
        }
        .onChange(of: pressing) { _, isPressing in
            if !isPressing { endHold() }
        }
    }

    /// System cancellation (no `onEnded`): stop tracking and slide the row back.
    private func endHold() {
        guard tracking else { return }
        tracking = false
        onCancel()
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
            .updating($pressing) { _, state, _ in state = true }
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
