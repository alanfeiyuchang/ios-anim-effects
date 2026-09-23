import SwiftUI

extension Effect {
    static let buttonsExpandActions = Effect(
        id: "buttons.expand-actions",
        category: .buttons,
        interaction: .tap,
        name: L("Expanding Action Button", "展开式操作按钮"),
        summary: L("A floating plus rotates into a close and fans out quick actions.", "悬浮加号旋转成关闭按钮，并扇形展开快捷操作。"),
        prompt: L(
            "A notes screen card with a 60 pt indigo-violet floating action button pinned to its bottom-trailing corner. On tap the plus rotates 135° into a close mark while the button dips to 92% and rebounds, and three 48 pt action circles (scan, photo, note), each tinted differently, burst out of its center and fan up and to the left along a quarter arc of 100 pt radius. Each scales from 30% to 100%, fades in and travels on a spring (response 0.4 s, damping 0.7) with a 40 ms stagger; closing reverses the order. Meanwhile the list recedes — 95% scale, 6 pt blur, 50% opacity over 350 ms — and tapping it closes the menu. Choosing an action tucks the fan away and slides a new, briefly highlighted note in at the top of the list with a success haptic. Playful yet orderly.",
            "笔记卡片右下角固定一枚 60pt 靛紫悬浮按钮。点击后加号旋转 135° 成关闭符号，按钮下沉到 92% 再回弹；扫描、照片、笔记三个 48pt 彩色圆从中心迸出，沿半径 100pt 的四分之一弧向左上展开，各自从 30% 缩放淡入，弹簧（响应 0.4 秒、阻尼 0.7）驱动，间隔 40 毫秒，收起时倒序。列表同时在 350 毫秒内缩到 95%、模糊 6pt、半透明，点它即可收起。选中操作后扇面收回，一条带高亮的新笔记从顶部滑入，并触发成功触觉。俏皮而有序。"
        ),
        implementation: L(
            "The FAB lives in a bottomTrailing overlay of the card; each action reads one open flag and applies its own delayed spring via animation(_:value:), reversed on close, at polar positions between 90° and 180° (or a vertical stack). Picking an action inserts a note with a move-from-top transition.",
            "悬浮按钮位于卡片的 bottomTrailing 叠层中；每个操作读取同一个展开状态，并通过 animation(_:value:) 应用各自带延迟的弹簧，收起时顺序反转，位置取 90° 到 180° 之间的极坐标（或纵向堆叠）。选择操作后以自顶部移入的转场插入新笔记。"
        ),
        apis: ["animation(_:value:)", "spring(response:dampingFraction:)", "rotationEffect", "delay"],
        tags: ["fab", "speed dial", "expand", "menu", "悬浮按钮", "展开", "快捷操作", "扇形"],
        params: [
            .slider("radius", L("Spread radius", "展开半径"), 70...130, default: 100, decimals: 0, unit: "pt"),
            .slider("stagger", L("Stagger", "错峰间隔"), 0...0.15, default: 0.04, unit: "s"),
            .choice("layout", L("Layout", "布局"), [L("Quarter arc", "四分之一弧"), L("Vertical", "纵向")], default: 0),
        ]
    ) { ctx in
        ButtonExpandActionsDemo(ctx: ctx)
    }
}

private struct ButtonActionItem {
    let symbol: String
    let color: Color
    let name: LocalizedText
    let newTitle: LocalizedText
}

private struct ButtonNote: Identifiable {
    let id: Int
    let symbol: String
    let color: Color
    let title: LocalizedText
    let detail: LocalizedText
}

private struct ButtonExpandActionsDemo: View {
    let ctx: DemoContext
    @State private var open = false
    @State private var presses = 0
    @State private var notes: [ButtonNote] = ButtonExpandActionsDemo.initialNotes
    @State private var freshID: Int?
    @State private var nextID = 100
    @State private var step = 0
    @State private var total = 24

    private let items: [ButtonActionItem] = [
        ButtonActionItem(symbol: "doc.viewfinder.fill", color: Palette.coral, name: L("Scan", "扫描"), newTitle: L("New scan", "新扫描件")),
        ButtonActionItem(symbol: "photo.fill", color: Palette.mint, name: L("Photo", "照片"), newTitle: L("Photo note", "照片笔记")),
        ButtonActionItem(symbol: "square.and.pencil", color: Palette.sky, name: L("Note", "笔记"), newTitle: L("Untitled note", "未命名笔记")),
    ]

    private static let initialNotes: [ButtonNote] = [
        ButtonNote(id: 0, symbol: "checklist", color: Palette.sky, title: L("Packing list", "打包清单"), detail: L("Updated 2 h ago", "2 小时前更新")),
        ButtonNote(id: 1, symbol: "photo.fill", color: Palette.mint, title: L("Lake Braies shots", "布拉耶斯湖照片"), detail: L("12 photos", "12 张照片")),
        ButtonNote(id: 2, symbol: "doc.viewfinder.fill", color: Palette.coral, title: L("Whiteboard scan", "白板扫描"), detail: L("Yesterday", "昨天")),
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            card
            Spacer(minLength: 0)
            DemoHint(text: L("Tap +, then pick an action", "点击加号，再选一个操作"), ctx: ctx)
                .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.5, delay: 0.4) { previewTick() }
    }

    private var card: some View {
        ZStack(alignment: .bottomTrailing) {
            notesList
                .scaleEffect(open ? 0.95 : 1)
                .blur(radius: open ? 6 : 0)
                .opacity(open ? 0.5 : 1)
                .animation(.smooth(duration: 0.35), value: open)
                .contentShape(Rectangle())
                .onTapGesture { if open { toggle() } }
            ZStack {
                ForEach(items.indices, id: \.self) { index in
                    actionButton(index)
                }
                mainButton
            }
            .padding(16)
        }
        .frame(width: 300, height: 300)
        .demoCard(cornerRadius: 26)
    }

    private var notesList: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(L("Recent notes", "最近笔记"), ctx.language)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer(minLength: 0)
                Text("\(total)")
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText(value: Double(total)))
            }
            ForEach(notes) { note in
                noteRow(note)
                    .transition(.asymmetric(insertion: .move(edge: .top).combined(with: .opacity), removal: .opacity))
            }
            Spacer(minLength: 0)
        }
        .padding(18)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func noteRow(_ note: ButtonNote) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(note.color.opacity(0.18))
                .frame(width: 40, height: 40)
                .overlay {
                    Image(systemName: note.symbol)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(note.color)
                }
            VStack(alignment: .leading, spacing: 2) {
                Text(note.title, ctx.language)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(note.detail, ctx.language)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(note.color.opacity(freshID == note.id ? 0.14 : 0))
        )
        .animation(.easeOut(duration: 0.6), value: freshID)
    }

    private var mainButton: some View {
        Button(action: toggle) {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(.white)
                .rotationEffect(.degrees(open ? 135 : 0))
                .frame(width: 60, height: 60)
                .background(Palette.primary, in: Circle())
                .shadow(color: Palette.indigo.opacity(0.4), radius: 14, y: 7)
                .keyframeAnimator(initialValue: 1.0, trigger: presses) { content, scale in
                    content.scaleEffect(scale)
                } keyframes: { _ in
                    KeyframeTrack(\.self) {
                        CubicKeyframe(0.92, duration: 0.08)
                        SpringKeyframe(1, duration: 0.4, spring: .bouncy)
                    }
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(open ? L("Close", "关闭") : L("New", "新建"), ctx.language))
        .animation(.spring(response: 0.4, dampingFraction: 0.65), value: open)
    }

    private func actionButton(_ index: Int) -> some View {
        let item = items[index]
        let target = position(for: index)
        let stagger = ctx["stagger"]
        let delay = open ? Double(index) * stagger : Double(items.count - 1 - index) * stagger
        return Button { perform(index) } label: {
            Image(systemName: item.symbol)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(item.color.gradient, in: Circle())
                .shadow(color: item.color.opacity(0.35), radius: 10, y: 6)
        }
        .buttonStyle(SportPressStyle(scale: 0.88, dim: 0.06))
        .accessibilityLabel(Text(item.name, ctx.language))
        .scaleEffect(open ? 1 : 0.3)
        .opacity(open ? 1 : 0)
        .offset(x: open ? target.x : 0, y: open ? target.y : 0)
        .animation(.spring(response: 0.4, dampingFraction: 0.7).delay(delay), value: open)
        .allowsHitTesting(open)
    }

    /// Up and to the left of a bottom-trailing FAB: a quarter arc from 12 o'clock to 9 o'clock.
    private func position(for index: Int) -> CGPoint {
        let radius = ctx.cg("radius")
        if ctx.int("layout") == 1 {
            return CGPoint(x: 0, y: -CGFloat(index + 1) * (radius * 0.62))
        }
        let degrees = -90 - Double(index) * 45
        let radians = degrees * .pi / 180
        return CGPoint(x: CGFloat(cos(radians)) * radius, y: CGFloat(sin(radians)) * radius)
    }

    private func toggle() {
        open.toggle()
        presses += 1
        if !ctx.isPreview { Haptics.tap() }
    }

    private func perform(_ index: Int) {
        guard open else { return }
        let item = items[index]
        let note = ButtonNote(id: nextID, symbol: item.symbol, color: item.color, title: item.newTitle, detail: L("Just now", "刚刚"))
        nextID += 1
        open = false
        presses += 1
        Haptics.success()
        withAnimation(.spring(response: 0.45, dampingFraction: 0.8).delay(0.12)) {
            notes.insert(note, at: 0)
            if notes.count > 3 { notes.removeLast() }
            freshID = note.id
            total += 1
        }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.2))
            if freshID == note.id { freshID = nil }
        }
    }

    private func previewTick() {
        if open {
            perform(step % items.count)
            step += 1
        } else {
            toggle()
        }
    }
}
