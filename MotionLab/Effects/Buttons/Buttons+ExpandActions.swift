import SwiftUI

extension Effect {
    static let buttonsExpandActions = Effect(
        id: "buttons.expand-actions",
        category: .buttons,
        interaction: .tap,
        name: L("Expanding Action Button", "展开式操作按钮"),
        summary: L("A floating plus rotates into a close and stacks labelled quick actions above it.", "悬浮加号旋转成关闭按钮，上方依次升起带标签的快捷操作。"),
        prompt: L(
            "A notes card with a 60 pt indigo-violet floating action button pinned bottom-trailing, iOS speed-dial style. On tap the plus rotates 135° into a close mark as the button dips to 92% and rebounds, and three 48 pt tinted action circles (scan, photo, note) rise out of it into a vertical stack 62 pt apart, nearest first: each scales from 30% to 100% and fades in on a spring (response 0.4 s, damping 0.72), 50 ms apart. A frosted label pill then slides 16 pt in from the right and fades up beside each circle, 80 ms behind it. Closing reverses the order, top row first. The list recedes (95%, 6 pt blur, 50% opacity over 350 ms); tapping it closes. Picking an action tucks the stack away and slides a highlighted note in at the top with a success haptic. Orderly and legible.",
            "笔记卡片右下角是一枚 60pt 靛紫悬浮按钮，iOS 快速拨号式。点击后加号旋转 135° 成关闭符号，按钮下沉到 92% 再回弹；扫描、照片、笔记三个 48pt 彩色圆由近及远从按钮升起，纵向间距 62pt，从 30% 缩放淡入，弹簧（响应 0.4 秒、阻尼 0.72），间隔 50 毫秒；各圆左侧的磨砂标签晚 80 毫秒从右滑入 16pt。收起时自顶部倒序。列表缩到 95%、模糊 6pt、半透明，点它即收起。选中操作后堆叠收回，高亮新笔记从顶部滑入，伴随成功触觉。"
        ),
        implementation: L(
            "The FAB lives in a bottomTrailing overlay of the card; each row reads one open flag and applies its own delayed spring via animation(_:value:) to its offset, scale and opacity, with the label pill on a second, later spring; delays reverse on close. Picking an action inserts a note with a move-from-top transition.",
            "悬浮按钮位于卡片的 bottomTrailing 叠层中；每一行读取同一个展开状态，通过 animation(_:value:) 为偏移、缩放与透明度应用各自带延迟的弹簧，标签胶囊再用一段更晚的弹簧；收起时延迟顺序反转。选择操作后以自顶部移入的转场插入新笔记。"
        ),
        apis: ["animation(_:value:)", "spring(response:dampingFraction:)", "rotationEffect", "keyframeAnimator"],
        tags: ["fab", "speed dial", "expand", "menu", "悬浮按钮", "快速拨号", "快捷操作", "展开"],
        params: [
            .slider("spacing", L("Row spacing", "行间距"), 52...72, default: 62, decimals: 0, unit: "pt"),
            .slider("stagger", L("Stagger", "错峰间隔"), 0...0.15, default: 0.05, unit: "s"),
            .slider("response", L("Spring response", "弹簧响应"), 0.25...0.8, default: 0.4, unit: "s"),
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
    /// Detail intro: opens, then picks an action so the stage never stays dimmed.
    @State private var introTask: Task<Void, Never>?

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
        .autoplay(ctx.isPreview, every: 1.5, delay: 0.4) {
            if ctx.isPreview { previewTick() } else { playIntro() }
        }
        .onDisappear { cancelIntro() }
    }

    private var card: some View {
        ZStack(alignment: .bottomTrailing) {
            notesList
                .scaleEffect(open ? 0.95 : 1)
                .blur(radius: open ? 6 : 0)
                .opacity(open ? 0.5 : 1)
                .animation(.smooth(duration: 0.35), value: open)
                .contentShape(Rectangle())
                .onTapGesture {
                    cancelIntro()
                    if open { toggle() }
                }
            ZStack(alignment: .bottomTrailing) {
                ForEach(items.indices, id: \.self) { index in
                    actionRow(index)
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
        Button {
            cancelIntro()
            toggle()
        } label: {
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

    private func actionRow(_ index: Int) -> some View {
        let item = items[index]
        let stagger = ctx["stagger"]
        let order = open ? Double(index) : Double(items.count - 1 - index)
        let delay = order * stagger
        let lift = CGFloat(index + 1) * ctx.cg("spacing")
        let spring = Animation.spring(response: ctx["response"], dampingFraction: 0.72)
        return Button {
            cancelIntro()
            perform(index, silent: false)
        } label: {
            HStack(spacing: 10) {
                actionLabel(item)
                    .offset(x: open ? 0 : 16)
                    .opacity(open ? 1 : 0)
                    .animation(spring.delay(open ? delay + 0.08 : delay), value: open)
                actionCircle(item)
                    .scaleEffect(open ? 1 : 0.3)
                    .opacity(open ? 1 : 0)
                    .animation(spring.delay(delay), value: open)
            }
        }
        .buttonStyle(SportPressStyle(scale: 0.94, dim: 0.06))
        .accessibilityLabel(Text(item.name, ctx.language))
        .frame(width: 200, height: 48, alignment: .trailing)
        .padding(.trailing, 6)
        .padding(.bottom, 6)
        .offset(y: open ? -lift : 0)
        .animation(spring.delay(delay), value: open)
        .allowsHitTesting(open)
    }

    private func actionLabel(_ item: ButtonActionItem) -> some View {
        Text(item.name, ctx.language)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.primary)
            .padding(.horizontal, 12)
            .frame(height: 32)
            .background(.regularMaterial, in: Capsule())
            .overlay(Capsule().strokeBorder(Palette.stroke))
            .shadow(color: .black.opacity(0.1), radius: 6, y: 3)
    }

    private func actionCircle(_ item: ButtonActionItem) -> some View {
        Image(systemName: item.symbol)
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 48, height: 48)
            .background(item.color.gradient, in: Circle())
            .shadow(color: item.color.opacity(0.35), radius: 10, y: 6)
    }

    private func toggle() {
        open.toggle()
        presses += 1
        if !ctx.isPreview { Haptics.tap() }
    }

    private func perform(_ index: Int, silent: Bool) {
        guard open else { return }
        let item = items[index]
        let note = ButtonNote(id: nextID, symbol: item.symbol, color: item.color, title: item.newTitle, detail: L("Just now", "刚刚"))
        nextID += 1
        open = false
        presses += 1
        if !silent && !ctx.isPreview { Haptics.success() }
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

    /// Detail intro: the full choreography once — open, then pick an action, which closes the stack.
    private func playIntro() {
        cancelIntro()
        if !open { toggle() }
        introTask = Task {
            try? await Task.sleep(for: .seconds(1.4))
            guard !Task.isCancelled else { return }
            perform(2, silent: true)
            introTask = nil
        }
    }

    private func cancelIntro() {
        introTask?.cancel()
        introTask = nil
    }

    private func previewTick() {
        if open {
            perform(step % items.count, silent: true)
            step += 1
        } else {
            toggle()
        }
    }
}
