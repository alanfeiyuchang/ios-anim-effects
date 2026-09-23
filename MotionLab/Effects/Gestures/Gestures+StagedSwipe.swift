import SwiftUI

extension Effect {
    static let gesturesStagedSwipe = Effect(
        id: "gestures.staged-swipe",
        category: .gestures,
        interaction: .gesture,
        name: L("Staged Swipe Scrub", "分段滑动操作"),
        summary: L("One swipe, three actions: the further you pull, the well shifts from Archive to Snooze to Delete.", "一次滑动、三种操作：拉得越远，底色从归档依次变为稍后与删除。"),
        prompt: L(
            "Three 62 pt mail rows (18 pt continuous corners, avatar, sender, preview line). Swiping a row left reveals a well whose action depends on distance, like scrubbing: 70 pt arms Archive (indigo, archive box), every further 64 pt steps to Snooze (amber, clock) and then Delete (red, trash). At each step the well cross-fades its colour over 200 ms, the glyph swaps with a symbol replace transition and bounces, the caption changes and a selection haptic ticks; the icon stays centred in the revealed area as it widens. Releasing on a stage flings the row off to the left on a quick ease-in (250 ms), the list closes the gap on a spring (response 0.4 s, damping 0.85) and a chip confirms the action; releasing before the first stage springs back. Precise, expressive, fast triage.",
            "三条高 62pt 的邮件行（18pt 连续圆角，头像、发件人与预览文字）。向左滑动时露出一个底槽，执行的操作取决于滑动距离，就像拖动刻度：到 70pt 进入“归档”（靛蓝、归档盒），此后每多 64pt 依次切换为“稍后”（琥珀、时钟）与“删除”（红色、垃圾桶）。每切换一段，底槽颜色在 200ms 内交叉渐变，图标通过符号替换转场切换并弹跳一下，说明文字随之改变，同时触发一次选择触感；图标始终居中于已露出的区域。在某一段松手时，该行以 250ms 的快速缓入向左甩出，列表以弹簧（响应 0.4 秒、阻尼 0.85）收拢空位，并弹出一枚确认小标签；未到第一段就松手则弹回原位。精准、表达力强，处理邮件又快又爽。"
        ),
        implementation: L(
            "The row's offset maps to a stage enum; the well reads it for colour, symbol and caption with animation(value:), and sensoryFeedback(.selection) fires on stage changes. Release animates the offset past the edge, then removes the item in a spring so the VStack reflows.",
            "行偏移量映射为阶段枚举；底槽据此决定颜色、图标与文字，并用 animation(value:) 过渡；阶段变化时由 sensoryFeedback(.selection) 触发触感。松手时先把偏移动画到屏幕外，再在弹簧中移除该项，让 VStack 重新排布。"
        ),
        apis: ["DragGesture", "simultaneousGesture", "contentTransition(.symbolEffect(.replace))", "sensoryFeedback(.selection)", "transition(.asymmetric)"],
        tags: ["swipe", "mail", "triage", "archive", "snooze", "滑动", "邮件", "归档", "稍后", "分段"],
        params: [
            .slider("first", L("First stage", "首段距离"), 50...110, default: 70, step: 1, decimals: 0, unit: "pt"),
            .slider("step", L("Stage step", "每段距离"), 40...90, default: 64, step: 1, decimals: 0, unit: "pt"),
        ]
    ) { ctx in
        StagedSwipeDemo(ctx: ctx)
    }
}

private enum SwipeStage: Int {
    case none, archive, snooze, delete

    var color: Color {
        switch self {
        case .none: return Color.gray.opacity(0.35)
        case .archive: return Palette.indigo
        case .snooze: return Palette.amber
        case .delete: return Palette.red
        }
    }

    var symbol: String {
        switch self {
        case .none, .archive: return "archivebox.fill"
        case .snooze: return "clock.fill"
        case .delete: return "trash.fill"
        }
    }

    var label: LocalizedText {
        switch self {
        case .none, .archive: return L("Archive", "归档")
        case .snooze: return L("Snooze", "稍后")
        case .delete: return L("Delete", "删除")
        }
    }

    var done: LocalizedText {
        switch self {
        case .none, .archive: return L("Archived", "已归档")
        case .snooze: return L("Snoozed until 6 PM", "已推迟到 18:00")
        case .delete: return L("Deleted", "已删除")
        }
    }
}

private struct StagedMail: Identifiable, Equatable {
    let id: Int
    let sender: LocalizedText
    let preview: LocalizedText
    let tint: Color
}

private let stagedSeed: [StagedMail] = [
    StagedMail(id: 0, sender: L("Ava Chen", "陈安娜"), preview: L("Slides for Thursday", "周四的演示文稿"), tint: Palette.pink),
    StagedMail(id: 1, sender: L("Studio", "工作室"), preview: L("Your order has shipped", "你的订单已发货"), tint: Palette.mint),
    StagedMail(id: 2, sender: L("Leo Park", "朴乐"), preview: L("Dinner on Friday?", "周五一起吃饭吗？"), tint: Palette.sky),
]

private struct StagedSwipeDemo: View {
    let ctx: DemoContext
    @State private var items = stagedSeed
    @State private var offsets: [Int: CGFloat] = [:]
    @State private var chip: SwipeStage?
    @State private var autoIndex = 0

    var body: some View {
        VStack(spacing: 10) {
            ForEach(items) { item in
                StagedRow(
                    mail: item,
                    offset: offsets[item.id] ?? 0,
                    first: ctx.cg("first"),
                    step: ctx.cg("step"),
                    ctx: ctx,
                    onDrag: { offsets[item.id] = $0 },
                    onEnd: { release(item.id) }
                )
                .transition(.asymmetric(insertion: .scale(scale: 0.92).combined(with: .opacity), removal: .opacity))
            }
            chipView
                .frame(height: 34)
            DemoHint(text: L("Swipe a row left — further for more", "向左滑动某行，越远操作越强"), ctx: ctx)
        }
        .frame(width: 300)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 2.4, delay: 0.5) { autoStep() }
    }

    @ViewBuilder
    private var chipView: some View {
        if let stage = chip {
            Label {
                Text(stage.done, ctx.language)
            } icon: {
                Image(systemName: stage.symbol)
            }
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(stage.color, in: Capsule())
            .transition(.scale(scale: 0.6).combined(with: .opacity))
        }
    }

    private func stage(for offset: CGFloat) -> SwipeStage {
        let distance = -offset
        let first = ctx.cg("first")
        guard distance >= first else { return .none }
        let steps = Int(((distance - first) / max(ctx.cg("step"), 1)).rounded(.down))
        return SwipeStage(rawValue: min(steps + 1, 3)) ?? .delete
    }

    private func release(_ id: Int) {
        let current = stage(for: offsets[id] ?? 0)
        guard current != .none else {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { offsets[id] = 0 }
            return
        }
        withAnimation(.easeIn(duration: 0.25)) { offsets[id] = -420 }
        if !ctx.isPreview { Haptics.tap(current == .delete ? .rigid : .medium) }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.25))
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                items.removeAll { $0.id == id }
                offsets[id] = nil
                chip = current
            }
            try? await Task.sleep(for: .seconds(1.3))
            withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                chip = nil
                if let original = stagedSeed.first(where: { $0.id == id }), !items.contains(original) {
                    let position = min(stagedSeed.firstIndex(of: original) ?? 0, items.count)
                    items.insert(original, at: position)
                }
            }
        }
    }

    private func autoStep() {
        guard let target = items.first else { return }
        let stageIndex = autoIndex % 3
        autoIndex += 1
        let first = ctx.cg("first")
        let step = ctx.cg("step")
        let distance: CGFloat = first + step * CGFloat(stageIndex) + step * 0.5
        withAnimation(.easeInOut(duration: 0.8)) { offsets[target.id] = -distance }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.9))
            release(target.id)
        }
    }
}

private struct StagedRow: View {
    let mail: StagedMail
    let offset: CGFloat
    let first: CGFloat
    let step: CGFloat
    let ctx: DemoContext
    let onDrag: (CGFloat) -> Void
    let onEnd: () -> Void
    @State private var tracking = false

    private var stage: SwipeStage {
        let distance = -offset
        guard distance >= first else { return .none }
        let steps = Int(((distance - first) / max(step, 1)).rounded(.down))
        return SwipeStage(rawValue: min(steps + 1, 3)) ?? .delete
    }

    var body: some View {
        let current = stage
        let revealed = max(-offset, 0)
        let progress = min(revealed / max(first, 1), 1)
        ZStack(alignment: .trailing) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(current.color)
                .animation(.easeInOut(duration: 0.2), value: current)
            VStack(spacing: 3) {
                Image(systemName: current.symbol)
                    .font(.system(size: 18, weight: .semibold))
                    .contentTransition(.symbolEffect(.replace))
                    .symbolEffect(.bounce, value: current)
                Text(current.label, ctx.language)
                    .font(.caption2.weight(.bold))
                    .contentTransition(.opacity)
            }
            .foregroundStyle(.white)
            .frame(width: max(revealed, 60))
            .opacity(Double(progress))
            .scaleEffect(0.7 + 0.3 * progress)
            .animation(.snappy(duration: 0.2), value: current)
            content
                .offset(x: offset)
                .simultaneousGesture(dragGesture)
        }
        .frame(height: 62)
        .sensoryFeedback(.selection, trigger: current) { _, _ in !ctx.isPreview }
    }

    private var content: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(mail.tint.gradient)
                .frame(width: 36, height: 36)
                .overlay {
                    Text(String(mail.sender(ctx.language).prefix(1)))
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
            VStack(alignment: .leading, spacing: 3) {
                Text(mail.sender, ctx.language)
                    .font(.subheadline.weight(.semibold))
                Text(mail.preview, ctx.language)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .lineLimit(1)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .frame(height: 62)
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
                onDrag(raw > 0 ? rubberBand(raw, limit: 24) : max(raw, -270))
            }
            .onEnded { _ in
                guard tracking else { return }
                tracking = false
                onEnd()
            }
    }
}
