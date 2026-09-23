import SwiftUI

extension Effect {
    static let navigationContextPopover = Effect(
        id: "navigation.context-popover",
        category: .navigation,
        interaction: .tap,
        name: L("Anchored Popover Menu", "锚点弹出菜单"),
        summary: L(
            "A context menu that grows out of its ⋯ button instead of popping in the middle.",
            "从「⋯」按钮本身生长出来的上下文菜单，而非凭空出现。"
        ),
        prompt: L(
            "A note card with a small ⋯ button in its top-right corner sits atop a short list of notes. Tapping the button grows a frosted menu out of that exact point: it scales from 20% to 100% anchored at its top-trailing corner, fades in and sharpens from a 6 pt blur on a lively spring (response ≈0.36 s, damping ≈0.74) with a slight overshoot, while the card recedes to 97% and the notes below fade to 55% behind a 1.5 pt blur. Rows (Edit, Duplicate, Pin, Share, and a destructive red Delete below a hairline divider) settle 30 ms apart from top to bottom. Pressing a row highlights it; choosing one or tapping outside shrinks the menu back into the button in ~180 ms. It should feel spatially anchored — the menu clearly belongs to the control that spawned it.",
            "一张笔记卡片位于笔记列表顶部，右上角有一个小小的「⋯」按钮。点击后，一块磨砂菜单从这个点精准地「长」出来：以右上角为锚点从 20% 放大到 100%，同时淡入并从 6pt 模糊变清晰，采用略带过冲的活泼弹簧（响应约 0.36 秒、阻尼约 0.74）；卡片随之缩小到 97%，下方的笔记淡到 55% 并轻微模糊 1.5pt。菜单项（编辑、复制、置顶、分享，以及细分隔线下方红色的删除）自上而下以 30 毫秒间隔落定。按下某行会高亮；选择后或点击空白处，菜单在约 180 毫秒内缩回按钮。它必须有明确的空间锚定感——一眼就能看出菜单属于触发它的那个控件。"
        ),
        implementation: L(
            "The menu is inserted with an asymmetric transition combining scale(anchor: .topTrailing), opacity and a custom blur modifier; the Origin parameter switches the anchor to .center for comparison. Rows reveal via per-row delayed animations.",
            "菜单以非对称转场插入，组合了 scale(anchor: .topTrailing)、透明度与自定义模糊修饰符；「缩放原点」参数可切换为 .center 以作对比。各行通过逐行延迟动画显现。"
        ),
        apis: ["transition(.scale(scale:anchor:))", "AnyTransition.modifier(active:identity:)", "regularMaterial", "ButtonStyle"],
        tags: ["popover", "context menu", "dropdown", "anchor", "弹出菜单", "上下文菜单", "下拉菜单", "锚点"],
        params: [
            .slider("response", L("Spring response", "弹簧响应"), 0.2...0.8, default: 0.36, unit: "s"),
            .slider("damping", L("Damping", "阻尼"), 0.5...1.0, default: 0.74),
            .choice("origin", L("Scale origin", "缩放原点"), [L("Anchor", "锚点"), L("Center", "中心")], default: 0),
        ]
    ) { ctx in
        ContextPopoverDemo(ctx: ctx)
    }
}

private struct PopoverAction {
    let symbol: String
    let title: LocalizedText
    let destructive: Bool
}

private let popoverActions: [PopoverAction] = [
    PopoverAction(symbol: "pencil", title: L("Edit", "编辑"), destructive: false),
    PopoverAction(symbol: "plus.square.on.square", title: L("Duplicate", "复制"), destructive: false),
    PopoverAction(symbol: "pin", title: L("Pin", "置顶"), destructive: false),
    PopoverAction(symbol: "square.and.arrow.up", title: L("Share", "分享"), destructive: false),
    PopoverAction(symbol: "trash", title: L("Delete", "删除"), destructive: true),
]

private struct ContextPopoverDemo: View {
    let ctx: DemoContext
    @State private var open = false

    private var anchor: UnitPoint { ctx.int("origin") == 0 ? .topTrailing : .center }

    var body: some View {
        ZStack {
            Color.black
                .opacity(open ? 0.12 : 0)
                .contentShape(Rectangle())
                .allowsHitTesting(open)
                .onTapGesture { setOpen(false) }
            VStack(spacing: 12) {
                noteCard
                    .zIndex(1)
                ForEach(0..<2, id: \.self) { index in
                    PopoverNoteRow(index: index, language: ctx.language)
                        .opacity(open ? 0.55 : 1)
                        .blur(radius: open ? 1.5 : 0)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.6) { setOpen(!open) }
    }

    private var noteCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(ctx.language == .zh ? "设计评审笔记" : "Design review notes")
                        .font(.headline)
                    Text(ctx.language == .zh ? "今天 10:24" : "Today, 10:24")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                moreButton
            }
            .zIndex(1)
            PlaceholderLines(count: 3)
        }
        .padding(18)
        .frame(width: 290)
        .demoCard(cornerRadius: 24)
        .scaleEffect(open ? 0.97 : 1)
    }

    private var moreButton: some View {
        Button { setOpen(!open) } label: {
            Image(systemName: "ellipsis")
                .font(.subheadline.weight(.bold))
                .frame(width: 34, height: 34)
                .background(Color.primary.opacity(open ? 0.14 : 0.07), in: Circle())
        }
        .buttonStyle(.plain)
        .overlay(alignment: .topTrailing) {
            if open {
                PopoverMenu(language: ctx.language, onSelect: { setOpen(false) })
                    .fixedSize()
                    .offset(y: 42)
                    .transition(menuTransition)
            }
        }
        .zIndex(1)
    }

    private var menuTransition: AnyTransition {
        .asymmetric(
            insertion: .scale(scale: 0.2, anchor: anchor)
                .combined(with: .opacity)
                .combined(with: .modifier(active: PopoverBlur(radius: 6), identity: PopoverBlur(radius: 0))),
            removal: .scale(scale: 0.2, anchor: anchor)
                .combined(with: .opacity)
                .animation(.easeIn(duration: 0.18))
        )
    }

    private func setOpen(_ value: Bool) {
        guard value != open else { return }
        if !ctx.isPreview { Haptics.tap(value ? .medium : .light) }
        withAnimation(.spring(response: ctx["response"], dampingFraction: ctx["damping"])) {
            open = value
        }
    }
}

private struct PopoverNoteRow: View {
    let index: Int
    let language: AppLanguage

    private let notes: [(String, Color, LocalizedText, LocalizedText)] = [
        ("lightbulb.fill", Palette.amber, L("Onboarding ideas", "新手引导灵感"), L("Yesterday", "昨天")),
        ("paintpalette.fill", Palette.pink, L("Colour tokens", "色彩变量"), L("Monday", "周一")),
    ]

    var body: some View {
        let note = notes[index % notes.count]
        HStack(spacing: 12) {
            Image(systemName: note.0)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(note.1)
                .frame(width: 34, height: 34)
                .background(note.1.opacity(0.14), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(note.2, language)
                    .font(.subheadline.weight(.semibold))
                Text(note.3, language)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .frame(width: 290, height: 60)
        .demoCard(cornerRadius: 18)
    }
}

private struct PopoverBlur: ViewModifier {
    let radius: CGFloat

    func body(content: Content) -> some View {
        content.blur(radius: radius)
    }
}

private struct PopoverMenu: View {
    let language: AppLanguage
    let onSelect: () -> Void
    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(0..<popoverActions.count, id: \.self) { index in
                let action = popoverActions[index]
                if action.destructive {
                    Divider().padding(.vertical, 4)
                }
                Button(action: onSelect) {
                    HStack(spacing: 12) {
                        Text(action.title, language)
                            .font(.subheadline)
                        Spacer(minLength: 24)
                        Image(systemName: action.symbol)
                            .font(.subheadline)
                    }
                    .foregroundStyle(action.destructive ? Palette.red : Color.primary)
                    .padding(.horizontal, 14)
                    .frame(width: 200, height: 40)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PopoverRowStyle())
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : -6)
                .animation(.spring(response: 0.35, dampingFraction: 0.85).delay(0.04 + Double(index) * 0.03), value: appeared)
            }
        }
        .padding(.vertical, 6)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Palette.stroke))
        .shadow(color: .black.opacity(0.18), radius: 24, y: 12)
        .onAppear { appeared = true }
    }
}

private struct PopoverRowStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(Color.primary.opacity(configuration.isPressed ? 0.08 : 0))
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
