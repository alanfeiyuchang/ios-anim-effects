import SwiftUI

extension Effect {
    static let gesturesSwipeActions = Effect(
        id: "gestures.swipe-actions",
        category: .gestures,
        interaction: .gesture,
        name: L("Swipe to Reveal & Delete", "左滑操作与删除"),
        summary: L("List rows that reveal actions, and a full swipe that deletes with a collapse.", "列表行左滑露出操作，一滑到底即删除并收拢。"),
        prompt: L(
            "A stack of 64 pt list rows (18 pt corners, tinted icon, title, subtitle, timestamp). Swiping a row left slides its content with the finger and reveals two 56 pt tiles, Pin (amber) and Delete (red), that scale from 60% to 100% and fade in with the reveal. Releasing past half the reveal width, projected with velocity, snaps the row open at −132 pt, otherwise it closes, both on a spring (response 0.4 s, damping 0.82), and opening one row closes the others. Crossing the full-swipe threshold fires one medium haptic, hides Pin and stretches Delete across the reveal; letting go there slides the row out left as the rows below glide up. The tiles are real buttons, Pin toggling an amber badge, and a tap elsewhere closes the open row.",
            "一组64 pt高的列表行（18 pt圆角、彩色图标、标题、副标题与时间）。向左滑动时内容跟手，露出两个56 pt的操作块——置顶（琥珀）和删除（红色），随露出比例从60%放大到100%并淡入。松手时按速度预测，过半就以弹簧（响应0.4秒、阻尼0.82）吸到−132 pt的展开位，否则收回，且只保留一行展开。越过“一滑到底”阈值时一下中等触感，置顶隐去，删除铺满露出区；在此松手，该行向左滑出，下方行上移补位。操作块是真按钮，置顶切换琥珀色图钉，点别处即收起。"
        ),
        implementation: L(
            "Each row owns a horizontal DragGesture (run simultaneously so the page can still scroll) and reports offset and predicted end to the parent, which decides open/close/delete and owns the pinned set; action tiles are Buttons, a background tap closes open rows, and removal uses an asymmetric move transition inside withAnimation.",
            "每一行挂载与页面滚动并行的水平 DragGesture，把偏移与预测终点上报给父视图决定展开、收起或删除，父视图同时维护置顶集合；操作块是 Button，点击背景收起已展开的行，删除在 withAnimation 中配合非对称 move 转场完成。"
        ),
        apis: ["DragGesture", "simultaneousGesture", "predictedEndTranslation", "transition(.asymmetric)", "UIImpactFeedbackGenerator"],
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
    let time: LocalizedText
    let symbol: String
    let tint: Color
}

private let swipeSeed: [SwipeItem] = [
    SwipeItem(id: 0, title: L("Design review", "设计评审"), subtitle: L("Motion specs v3 are ready", "动效规范 v3 已就绪"), time: L("9:41", "9:41"), symbol: "paintbrush.pointed.fill", tint: Palette.violet),
    SwipeItem(id: 1, title: L("Launch checklist", "发布清单"), subtitle: L("4 items left before ship", "上线前还剩 4 项"), time: L("8:15", "8:15"), symbol: "checklist", tint: Palette.mint),
    SwipeItem(id: 2, title: L("Weekly sync", "周会同步"), subtitle: L("Notes and action items", "会议纪要与待办"), time: L("Mon", "周一"), symbol: "person.2.fill", tint: Palette.sky),
]

private struct SwipeActionsDemo: View {
    let ctx: DemoContext
    @State private var items = swipeSeed
    @State private var offsets: [Int: CGFloat] = [:]
    @State private var pinned: Set<Int> = []
    @State private var step = 0
    /// Set by a real drag, so the intro's scheduled close never snaps shut a row the user opened.
    @State private var userTouched = false

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
                    pinned: pinned.contains(item.id),
                    onDrag: { value in
                        userTouched = true
                        offsets[item.id] = value
                    },
                    onEnd: { current, predicted in end(item.id, current: current, predicted: predicted) },
                    onCancel: { cancelSwipe(item.id) },
                    onPin: { togglePin(item.id) },
                    onDelete: {
                        Haptics.tap(.medium)
                        delete(item.id)
                    },
                    onTapContent: closeAll
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
                    Label {
                        Text(L("Restore", "恢复"), ctx.language)
                    } icon: {
                        Image(systemName: "arrow.uturn.backward")
                    }
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
        // Tapping anywhere outside the rows closes whatever is open.
        .contentShape(Rectangle())
        .onTapGesture { closeAll() }
        .autoplay(ctx.isPreview, every: 1.2) { autoStep() }
    }

    private var hasOpenRow: Bool {
        offsets.values.contains { $0 != 0 }
    }

    private func closeAll() {
        guard hasOpenRow else { return }
        withAnimation(spring) { offsets = [:] }
    }

    private func togglePin(_ id: Int) {
        Haptics.selection()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            if pinned.contains(id) { pinned.remove(id) } else { pinned.insert(id) }
        }
        withAnimation(spring) { offsets[id] = 0 }
    }

    private var spring: Animation {
        .spring(response: ctx["response"], dampingFraction: 0.82)
    }

    private func end(_ id: Int, current: CGFloat, predicted: CGFloat) {
        let full = ctx.cg("full")
        if current < -full {
            // The threshold haptic already fired while dragging.
            delete(id)
            return
        }
        if predicted < -full * 1.6 {
            // A hard flick deletes without ever crossing the threshold, so give it its single haptic here.
            Haptics.tap(.medium)
            delete(id)
            return
        }
        let target: CGFloat = predicted < -reveal * 0.5 ? -reveal : 0
        var next = offsets.mapValues { _ in CGFloat(0) }
        next[id] = target
        withAnimation(spring) { offsets = next }
    }

    /// A system-cancelled swipe (the page scrolled) never deletes: the row settles open or closed.
    private func cancelSwipe(_ id: Int) {
        let current = offsets[id] ?? 0
        let target: CGFloat = current < -reveal * 0.5 ? -reveal : 0
        withAnimation(spring) { offsets[id] = target }
    }

    /// The full-swipe haptic already fired when the threshold was crossed, so deleting stays silent here.
    private func delete(_ id: Int) {
        withAnimation(.spring(response: 0.42, dampingFraction: 0.86)) {
            items.removeAll { $0.id == id }
            offsets[id] = nil
        }
    }

    private func restore() {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            items = swipeSeed
            offsets = [:]
            pinned = []
        }
    }

    private func closeAfterIntro(_ id: Int) {
        userTouched = false
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.2))
            guard !userTouched, offsets[id] == -reveal else { return }
            withAnimation(spring) { offsets[id] = 0 }
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
            // The detail intro plays once: reveal the actions, then close so the demo isn't left swiped open.
            if !ctx.isPreview { closeAfterIntro(first.id) }
        case 1:
            togglePin(first.id)
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
    let pinned: Bool
    let onDrag: (CGFloat) -> Void
    let onEnd: (CGFloat, CGFloat) -> Void
    let onCancel: () -> Void
    let onPin: () -> Void
    let onDelete: () -> Void
    let onTapContent: () -> Void
    @State private var start: CGFloat?
    /// Resets on system cancellation too, so a stolen touch never leaves the row at a partial offset.
    @GestureState private var pressing = false

    var body: some View {
        let isFull = offset < -fullSwipe
        let progress = min(max(-offset / reveal, 0), 1)
        ZStack(alignment: .trailing) {
            actions(progress: progress, isFull: isFull)
            content
                .offset(x: offset)
                .onTapGesture(perform: onTapContent)
                .simultaneousGesture(dragGesture)
        }
        .frame(height: 64)
        .onChange(of: isFull) { _, newValue in
            if newValue && !ctx.isPreview { Haptics.tap(.medium) }
        }
        .onChange(of: pressing) { _, isPressing in
            if !isPressing { endHold() }
        }
    }

    /// System cancellation (no `onEnded`): drop the anchor and let the list settle the row.
    private func endHold() {
        guard start != nil else { return }
        start = nil
        onCancel()
    }

    private func actions(progress: CGFloat, isFull: Bool) -> some View {
        HStack(spacing: 8) {
            ActionTile(symbol: pinned ? "pin.slash.fill" : "pin.fill", color: Palette.amber, label: pinned ? L("Unpin", "取消置顶") : L("Pin", "置顶"), language: ctx.language, action: onPin)
                .frame(width: isFull ? 0 : 56)
                .opacity(isFull ? 0 : 1)
            ActionTile(symbol: "trash.fill", color: Palette.red, label: L("Delete", "删除"), language: ctx.language, action: onDelete)
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
                HStack(spacing: 5) {
                    Text(item.title, ctx.language)
                        .font(.subheadline.weight(.semibold))
                    if pinned {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Palette.amber)
                            .rotationEffect(.degrees(35))
                            .transition(.scale(scale: 0.2).combined(with: .opacity))
                    }
                }
                Text(item.subtitle, ctx.language)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .lineLimit(1)
            Spacer(minLength: 4)
            Text(item.time, ctx.language)
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
            .updating($pressing) { _, state, _ in state = true }
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
    let label: LocalizedText
    let language: AppLanguage
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(color.gradient)
                .overlay {
                    Image(systemName: symbol)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .contentTransition(.symbolEffect(.replace))
                }
                .frame(height: 64)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(label, language))
    }
}
