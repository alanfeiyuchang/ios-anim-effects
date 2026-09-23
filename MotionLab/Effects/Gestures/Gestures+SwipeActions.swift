import SwiftUI

extension Effect {
    static let gesturesSwipeActions = Effect(
        id: "gestures.swipe-actions",
        category: .gestures,
        interaction: .gesture,
        name: L("Swipe to Reveal & Delete", "左滑操作与删除"),
        summary: L("List rows that reveal actions, and a full swipe that deletes with a collapse.", "列表行左滑露出操作，一滑到底即删除并收拢。"),
        prompt: L(
            "A stack of 64 pt list rows (18 pt continuous corners, elevated surface, tinted icon, title, subtitle and timestamp). Swiping a row left slides its content with the finger and reveals two 56 pt action tiles — Pin (amber) and Delete (red) — that scale from 60% to 100% and fade in proportionally to the reveal. Releasing past ~half the reveal width (projected with velocity) snaps the row open at −132 pt; otherwise it closes, both on a spring (response 0.4 s, damping 0.82), and opening one row closes the others. Crossing the full-swipe threshold fires a medium haptic, hides Pin and stretches Delete across the whole revealed area; letting go there deletes the row, which slides out left while the rows below glide up to close the gap. Rightward drags are rubber-banded.",
            "一组高 64pt 的列表行（18pt 连续圆角、浮起表面、彩色图标、标题、副标题与时间）。向左滑动时，行内容跟手移动，同时露出两个 56pt 的操作块——置顶（琥珀色）与删除（红色），它们随露出比例从 60% 放大到 100% 并淡入。松手时结合速度预测：超过露出宽度一半即以弹簧（响应 0.4 秒、阻尼 0.82）吸附到 −132pt 的展开位，否则收回；展开一行会自动收起其他行。越过“一滑到底”阈值时触发中等触感，置顶按钮隐去，删除按钮拉伸铺满整个露出区域；在此松手即删除该行——它向左滑出，下方各行平滑上移补位。向右拖动带橡皮筋阻尼。"
        ),
        implementation: L(
            "Each row owns a horizontal DragGesture (run simultaneously so the page can still scroll) and reports offset and predicted end to the parent, which decides open/close/delete; removal uses an asymmetric move transition inside withAnimation.",
            "每一行挂载与页面滚动并行的水平 DragGesture，把偏移与预测终点上报给父视图决定展开、收起或删除；删除在 withAnimation 中配合非对称 move 转场完成。"
        ),
        apis: ["DragGesture", "simultaneousGesture", "predictedEndTranslation", "transition(.asymmetric)", "sensoryFeedback"],
        tags: ["swipe", "delete", "list", "actions", "reveal", "左滑", "删除", "列表", "操作"],
        params: [
            .slider("full", L("Full-swipe threshold", "一滑到底阈值"), 170...260, default: 210, step: 1, decimals: 0, unit: "pt"),
            .slider("response", L("Spring response", "弹簧响应"), 0.2...0.8, default: 0.4, unit: "s"),
        ]
    ) { ctx in
        SwipeActionsDemo(ctx: ctx)
    }
}

private struct SwipeItem: Identifiable, Equatable {
    let id: Int
    let title: LocalizedText
    let subtitle: LocalizedText
    let time: String
    let symbol: String
    let tint: Color
}

private let swipeSeed: [SwipeItem] = [
    SwipeItem(id: 0, title: L("Design review", "设计评审"), subtitle: L("Motion specs v3 are ready", "动效规范 v3 已就绪"), time: "9:41", symbol: "paintbrush.pointed.fill", tint: Palette.violet),
    SwipeItem(id: 1, title: L("Launch checklist", "发布清单"), subtitle: L("4 items left before ship", "上线前还剩 4 项"), time: "8:15", symbol: "checklist", tint: Palette.mint),
    SwipeItem(id: 2, title: L("Weekly sync", "周会同步"), subtitle: L("Notes and action items", "会议纪要与待办"), time: "Mon", symbol: "person.2.fill", tint: Palette.sky),
]

private struct SwipeActionsDemo: View {
    let ctx: DemoContext
    @State private var items = swipeSeed
    @State private var offsets: [Int: CGFloat] = [:]
    @State private var step = 0

    private let reveal: CGFloat = 132

    var body: some View {
        VStack(spacing: 10) {
            ForEach(items) { item in
                SwipeRow(
                    item: item,
                    ctx: ctx,
                    offset: offsets[item.id] ?? 0,
                    reveal: reveal,
                    fullSwipe: ctx.cg("full"),
                    onDrag: { value in offsets[item.id] = value },
                    onEnd: { current, predicted in end(item.id, current: current, predicted: predicted) }
                )
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.96)),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            }
            if items.count < swipeSeed.count {
                Button {
                    restore()
                } label: {
                    Label(ctx.language == .zh ? "恢复" : "Restore", systemImage: "arrow.uturn.backward")
                        .font(.footnote.weight(.semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Palette.surface, in: Capsule())
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .transition(.opacity)
            }
            DemoHint(text: L("Swipe a row left — all the way to delete", "向左滑动某行，滑到底即删除"), ctx: ctx)
                .padding(.top, 4)
        }
        .frame(width: 300)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.2) { autoStep() }
    }

    private var spring: Animation {
        .spring(response: ctx["response"], dampingFraction: 0.82)
    }

    private func end(_ id: Int, current: CGFloat, predicted: CGFloat) {
        let full = ctx.cg("full")
        if current < -full || predicted < -full * 1.6 {
            delete(id)
            return
        }
        let target: CGFloat = predicted < -reveal * 0.5 ? -reveal : 0
        var next = offsets.mapValues { _ in CGFloat(0) }
        next[id] = target
        withAnimation(spring) { offsets = next }
    }

    private func delete(_ id: Int) {
        if !ctx.isPreview { Haptics.tap(.medium) }
        withAnimation(.spring(response: 0.42, dampingFraction: 0.86)) {
            items.removeAll { $0.id == id }
            offsets[id] = nil
        }
    }

    private func restore() {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            items = swipeSeed
            offsets = [:]
        }
    }

    private func autoStep() {
        defer { step += 1 }
        guard let first = items.first else {
            restore()
            return
        }
        let second = items.count > 1 ? items[1] : first
        switch step % 5 {
        case 0:
            withAnimation(spring) { offsets[first.id] = -reveal }
        case 1:
            withAnimation(spring) { offsets = [:] }
        case 2:
            withAnimation(.easeInOut(duration: 0.55)) { offsets[second.id] = -(ctx.cg("full") + 30) }
        case 3:
            delete(second.id)
        default:
            restore()
        }
    }
}

private struct SwipeRow: View {
    let item: SwipeItem
    let ctx: DemoContext
    let offset: CGFloat
    let reveal: CGFloat
    let fullSwipe: CGFloat
    let onDrag: (CGFloat) -> Void
    let onEnd: (CGFloat, CGFloat) -> Void
    @State private var start: CGFloat?

    var body: some View {
        let isFull = offset < -fullSwipe
        let progress = min(max(-offset / reveal, 0), 1)
        ZStack(alignment: .trailing) {
            actions(progress: progress, isFull: isFull)
            content
                .offset(x: offset)
                .simultaneousGesture(dragGesture)
        }
        .frame(height: 64)
        .sensoryFeedback(.impact(weight: .medium), trigger: isFull) { _, newValue in
            newValue && !ctx.isPreview
        }
    }

    private func actions(progress: CGFloat, isFull: Bool) -> some View {
        HStack(spacing: 8) {
            ActionTile(symbol: "pin.fill", color: Palette.amber)
                .frame(width: isFull ? 0 : 56)
                .opacity(isFull ? 0 : 1)
            ActionTile(symbol: "trash.fill", color: Palette.red)
                .frame(width: isFull ? max(56, -offset - 8) : 56)
        }
        .scaleEffect(0.6 + 0.4 * progress, anchor: .trailing)
        .opacity(Double(progress))
        .animation(.snappy(duration: 0.25), value: isFull)
    }

    private var content: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(item.tint.gradient)
                .frame(width: 38, height: 38)
                .overlay {
                    Image(systemName: item.symbol)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                }
            VStack(alignment: .leading, spacing: 3) {
                Text(item.title, ctx.language)
                    .font(.subheadline.weight(.semibold))
                Text(item.subtitle, ctx.language)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .lineLimit(1)
            Spacer(minLength: 4)
            Text(item.time)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 12)
        .frame(height: 64)
        .background(Palette.elevated, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Palette.stroke, lineWidth: 1))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { value in
                if start == nil {
                    guard abs(value.translation.width) > abs(value.translation.height) else { return }
                    start = offset
                }
                let base = start ?? offset
                var next = base + value.translation.width
                if next > 0 { next = rubberBand(next, limit: 40) }
                onDrag(next)
            }
            .onEnded { value in
                guard let base = start else { return }
                start = nil
                onEnd(offset, base + value.predictedEndTranslation.width)
            }
    }
}

private struct ActionTile: View {
    let symbol: String
    let color: Color

    var body: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(color.gradient)
            .overlay {
                Image(systemName: symbol)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(height: 64)
    }
}
