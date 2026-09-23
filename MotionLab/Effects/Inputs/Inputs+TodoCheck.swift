import SwiftUI

extension Effect {
    static let inputsTodoCheck = Effect(
        id: "inputs.todo-check",
        category: .inputs,
        interaction: .tap,
        name: L("Strike & Sink To-Do", "划线下沉待办"),
        summary: L("Checking a task pops the box, strikes the text through, then sinks the row to the bottom.", "勾选任务时方框弹起、文字被划线，随后整行沉到列表底部。"),
        prompt: L(
            "A four-item to-do card with a progress count. Tapping a round checkbox runs a three-beat choreography: the box fills with mint and pops to 120% then settles on a bouncy spring while the checkmark draws in; 100 ms later a 1.5 pt strike line sweeps across the title from left to right over 280 ms as the text fades to 45%; after a 500 ms pause the whole row sinks below the unfinished ones, the other rows sliding up to close the gap on a smooth spring (response 0.5 s, damping 0.85). Unchecking reverses it: the line retracts and the row rises back to its original place among the open tasks. The header's \"2 of 4 done\" rolls with numeric digits and a success haptic fires when everything is done. Orderly, rewarding and easy to follow.",
            "带进度计数的四项待办卡片。点击圆形复选框触发三段式编排：方框填充薄荷绿、弹到 120% 再以弹性弹簧回落，同时对勾被描出；100 毫秒后一条 1.5pt 删除线在 280 毫秒内从左到右扫过标题，文字淡到 45%；停顿 500 毫秒后整行沉到未完成任务下方，其余行以顺滑弹簧（响应 0.5 秒、阻尼 0.85）上移补位。取消勾选则倒放：删除线收回，该行升回原位。标题“已完成 2/4”数字滚动，全部完成时触发成功触觉。井然有序、有成就感。"
        ),
        implementation: L(
            "Each item stores a done flag and a completion order; the list is sorted with unfinished first and animated with animation(_:value:) keyed on the id order. The strike is a Capsule overlay scaled on x from the leading anchor, and a Task delays the reorder.",
            "每个任务保存完成状态与完成顺序；列表按“未完成在前”排序，并以 id 顺序为键通过 animation(_:value:) 动画重排。删除线是以前缘为锚点、沿 x 轴缩放的 Capsule 叠加层，Task 负责延迟重排。"
        ),
        apis: ["ForEach(id:)", "animation(_:value:)", "scaleEffect(x:y:anchor:)", "trim(from:to:)", "numericText"],
        tags: ["checkbox", "to-do", "strikethrough", "reorder", "复选框", "待办", "删除线", "重排"],
        params: [
            .slider("pause", L("Sink delay", "下沉延迟"), 0...1.5, default: 0.5, unit: "s"),
            .slider("strike", L("Strike duration", "划线时长"), 0.1...0.8, default: 0.28, unit: "s"),
            .toggle("reorder", L("Sink finished rows", "完成后下沉"), default: true),
        ]
    ) { ctx in
        TodoCheckDemo(ctx: ctx)
    }
}

private struct TodoItem: Identifiable, Equatable {
    let id: Int
    let title: LocalizedText
    var done: Bool
    /// Sort key among finished items (older completions stay higher).
    var finishedAt: Int
}

private struct TodoCheckDemo: View {
    let ctx: DemoContext
    @State private var items: [TodoItem] = [
        TodoItem(id: 0, title: L("Book flights", "订机票"), done: false, finishedAt: 0),
        TodoItem(id: 1, title: L("Renew passport", "续签护照"), done: false, finishedAt: 0),
        TodoItem(id: 2, title: L("Pack chargers", "带好充电器"), done: true, finishedAt: 1),
        TodoItem(id: 3, title: L("Water the plants", "给植物浇水"), done: false, finishedAt: 0),
    ]
    /// Display order, updated after the sink delay so the strike plays in place first.
    @State private var order: [Int] = [0, 1, 3, 2]
    @State private var counter = 2
    @State private var step = 0

    private static let previewTaps: [Int] = [0, 3, 1, 1, 0, 3]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            card
            Spacer()
            DemoHint(text: L("Tick a task", "勾选一项任务"), ctx: ctx)
                .padding(.bottom, 18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.5, delay: 0.4) { previewTick() }
    }

    private var doneCount: Int { items.filter(\.done).count }

    private var card: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(L("Trip prep", "出行准备"), ctx.language)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer(minLength: 0)
                Text(ctx.language == .zh ? "已完成 \(doneCount)/\(items.count)" : "\(doneCount) of \(items.count) done")
                    .font(.caption.weight(.semibold).monospacedDigit())
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText(value: Double(doneCount)))
                    .animation(.snappy, value: doneCount)
            }
            VStack(spacing: 6) {
                ForEach(order, id: \.self) { id in
                    if let item = items.first(where: { $0.id == id }) {
                        TodoRow(item: item, strike: ctx["strike"], language: ctx.language) { toggle(id) }
                    }
                }
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.85), value: order)
        }
        .padding(18)
        .frame(width: 300)
        .demoCard(cornerRadius: 24)
    }

    private func sortedOrder() -> [Int] {
        let open = items.filter { !$0.done }.map(\.id)
        let finished = items.filter(\.done).sorted { $0.finishedAt < $1.finishedAt }.map(\.id)
        return open + finished
    }

    private func toggle(_ id: Int) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].done.toggle()
        if items[index].done {
            counter += 1
            items[index].finishedAt = counter
            if !ctx.isPreview {
                if items.allSatisfy(\.done) { Haptics.success() } else { Haptics.tap() }
            }
        } else if !ctx.isPreview {
            Haptics.tap(.soft)
        }
        guard ctx.bool("reorder") else { return }
        let pause = ctx["pause"]
        Task {
            try? await Task.sleep(for: .seconds(pause))
            order = sortedOrder()
        }
    }

    private func previewTick() {
        let id = Self.previewTaps[step % Self.previewTaps.count]
        step += 1
        toggle(id)
    }
}

private struct TodoRow: View {
    let item: TodoItem
    let strike: Double
    let language: AppLanguage
    let action: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            checkbox
            Text(item.title, language)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
                .opacity(item.done ? 0.45 : 1)
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(Color.primary.opacity(0.7))
                        .frame(height: 1.5)
                        .scaleEffect(x: item.done ? 1 : 0, y: 1, anchor: .leading)
                }
                .animation(.easeInOut(duration: strike).delay(item.done ? 0.1 : 0), value: item.done)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .frame(height: 46)
        .background(Palette.surface.opacity(0.6), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .contentShape(Rectangle())
        .onTapGesture(perform: action)
    }

    private var checkbox: some View {
        ZStack {
            Circle()
                .strokeBorder(Color.primary.opacity(0.25), lineWidth: 1.5)
                .opacity(item.done ? 0 : 1)
            Circle()
                .fill(Palette.mint)
                .scaleEffect(item.done ? 1 : 0.2)
                .opacity(item.done ? 1 : 0)
            TodoCheckmark()
                .trim(from: 0, to: item.done ? 1 : 0)
                .stroke(Color.white, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                .frame(width: 11, height: 9)
                .animation(.easeOut(duration: 0.22).delay(item.done ? 0.06 : 0), value: item.done)
        }
        .frame(width: 24, height: 24)
        .keyframeAnimator(initialValue: 1.0, trigger: item.done) { content, scale in
            content.scaleEffect(scale)
        } keyframes: { _ in
            KeyframeTrack(\.self) {
                CubicKeyframe(1.2, duration: 0.1)
                SpringKeyframe(1, duration: 0.35, spring: .bouncy)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: item.done)
    }
}

private struct TodoCheckmark: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.width * 0.38, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        return path
    }
}
