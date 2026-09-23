import SwiftUI

extension Effect {
    static let inputsTodoCheck = Effect(
        id: "inputs.todo-check",
        category: .inputs,
        interaction: .tap,
        name: L("Fill & Sink To-Do", "填色下沉待办"),
        summary: L("Checking a task closes its ring into a solid dot, washes the row mint, then sinks it to the bottom.", "勾选任务时圆环向内收拢成实心圆点，整行铺上薄荷色，随后沉到列表底部。"),
        prompt: L(
            "A four-item to-do card with a progress count. Tapping a round checkbox runs a three-beat choreography: the grey ring turns mint and thickens inward until it closes into a solid dot (spring, response 0.35 s, damping 0.75), and 180 ms later a white tick stamps in, dropping from 180% to 100% on a snappy, slightly bouncy spring. Meanwhile a pale mint wash sweeps across the row from the checkbox to the trailing edge over 320 ms and the title fades to 45%. After a 500 ms pause the row sinks below the unfinished ones, the others sliding up on a smooth spring (response 0.5 s, damping 0.85). Unchecking reopens the ring, lifts the tick and retracts the wash. The \"2 of 4 done\" count rolls; a success haptic fires when all are done. Calm and rewarding.",
            "带进度计数的四项待办卡片。点击圆形复选框触发三段式编排：灰色圆环转为薄荷绿并向内加粗，直到收拢成实心圆点（弹簧，响应 0.35 秒、阻尼 0.75）；180 毫秒后白色对勾从 180% 盖章般落到 100%，干脆略带回弹。同时浅薄荷色在 320 毫秒内从复选框向右铺满整行，标题淡到 45%。停顿 500 毫秒后该行沉到未完成任务下方，其余行以顺滑弹簧（响应 0.5 秒、阻尼 0.85）上移补位。取消勾选则圆环张开、对勾抬起、底色收回。“已完成 2/4”数字滚动，全部完成时触发成功触觉。沉静而满足。"
        ),
        implementation: L(
            "Each item stores a done flag and a completion order; the list is sorted with unfinished first and animated with animation(_:value:) keyed on the id order. The ring is an even-odd annulus Shape whose animatable hole radius shrinks to zero, the wash is a leading-anchored scaleEffect, and a Task delays the reorder.",
            "每个任务保存完成状态与完成顺序；列表按“未完成在前”排序，并以 id 顺序为键通过 animation(_:value:) 动画重排。圆环是奇偶填充的环形 Shape，其可动画的内孔半径收缩到零；铺色是以前缘为锚点的 scaleEffect，Task 负责延迟重排。"
        ),
        apis: ["Shape + animatableData", "FillStyle(eoFill:)", "scaleEffect(x:y:anchor:)", "animation(_:value:)", "numericText"],
        tags: ["checkbox", "to-do", "fill", "reorder", "复选框", "待办", "填充", "重排"],
        params: [
            .slider("pause", L("Sink delay", "下沉延迟"), 0...1.5, default: 0.5, unit: "s"),
            .slider("wash", L("Wash duration", "铺色时长"), 0.1...0.8, default: 0.32, unit: "s"),
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
    /// Display order, updated after the sink delay so the check plays in place first.
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
                        TodoRow(item: item, wash: ctx["wash"], language: ctx.language) { toggle(id) }
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
    let wash: Double
    let language: AppLanguage
    let action: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            checkbox
            Text(item.title, language)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
                .opacity(item.done ? 0.45 : 1)
                .animation(.easeOut(duration: 0.25), value: item.done)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .frame(height: 46)
        .background { rowBackground }
        .contentShape(Rectangle())
        .onTapGesture(perform: action)
    }

    /// Mint wash sweeping from the checkbox to the trailing edge.
    private var rowBackground: some View {
        let shape = RoundedRectangle(cornerRadius: 12, style: .continuous)
        return shape
            .fill(Palette.surface.opacity(0.6))
            .overlay {
                shape
                    .fill(Palette.mint.opacity(0.14))
                    .scaleEffect(x: item.done ? 1 : 0, y: 1, anchor: .leading)
                    .animation(.easeInOut(duration: wash).delay(item.done ? 0.08 : 0), value: item.done)
            }
            .clipShape(shape)
    }

    private var checkbox: some View {
        let hole: CGFloat = item.done ? 0 : 0.86
        let tickScale: CGFloat = item.done ? 1 : 1.8
        return ZStack {
            Circle()
                .strokeBorder(Color.primary.opacity(0.25), lineWidth: 1.5)
                .opacity(item.done ? 0 : 1)
            TodoRing(hole: hole)
                .fill(Palette.mint, style: FillStyle(eoFill: true))
                .opacity(item.done ? 1 : 0)
                .animation(.spring(response: 0.35, dampingFraction: 0.75), value: item.done)
            TodoCheckmark()
                .stroke(Color.white, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                .frame(width: 11, height: 9)
                .scaleEffect(tickScale)
                .opacity(item.done ? 1 : 0)
                .animation(
                    item.done ? .spring(response: 0.28, dampingFraction: 0.6).delay(0.18) : .easeOut(duration: 0.15),
                    value: item.done
                )
        }
        .frame(width: 24, height: 24)
    }
}

/// A mint annulus whose hole shrinks to nothing, so the ring closes inward into a solid dot.
private struct TodoRing: Shape {
    /// Hole radius as a fraction of the outer radius (0 = solid disc).
    var hole: CGFloat

    var animatableData: CGFloat {
        get { hole }
        set { hole = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let radius: CGFloat = min(rect.width, rect.height) / 2
        let inner: CGFloat = radius * max(hole, 0)
        var path = Path(ellipseIn: rect)
        if inner > 0.1 {
            let center = CGPoint(x: rect.midX, y: rect.midY)
            path.addEllipse(in: CGRect(x: center.x - inner, y: center.y - inner, width: inner * 2, height: inner * 2))
        }
        return path
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
