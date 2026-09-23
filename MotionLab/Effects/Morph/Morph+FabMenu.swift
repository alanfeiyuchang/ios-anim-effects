import SwiftUI

extension Effect {
    static let morphFabMenu = Effect(
        id: "morph.fab-menu",
        category: .morph,
        interaction: .tap,
        name: L("FAB to Menu", "悬浮按钮变菜单"),
        summary: L(
            "A floating action button stretches from its corner into an action menu.",
            "悬浮按钮从角落伸展成一块操作菜单。"
        ),
        prompt: L(
            "A 60 pt circular floating action button with a plus glyph sits in the bottom-right corner. On tap the button itself grows up and to the left, pinned to its bottom-trailing corner, into a 224 × 258 pt menu panel: size and corner radius (30 → 24 pt) animate on one spring (response ≈0.45 s, damping ≈0.8) while the fill inverts from brand indigo to high-contrast ink. The plus rotates 135° into a close ×, and four action rows slide in from 16 pt right with a blur-to-sharp fade, staggered 40 ms starting from the row nearest the button. A light scrim dims the page; tapping outside or choosing an action collapses everything back into the circle.",
            "右下角是一枚 60pt 的圆形悬浮按钮，中间是加号。点击后按钮本身以右下角为锚点，向左上方生长为 224 × 258pt 的菜单面板：尺寸与圆角（30 → 24pt）由同一条弹簧（响应约 0.45 秒、阻尼约 0.8）驱动，底色从品牌靛蓝反转为高对比度墨色。加号旋转 135° 变成关闭符号，四行操作项从右侧 16pt 处带着模糊淡入滑入，从最靠近按钮的一行开始，每行错开 40 毫秒。页面覆盖一层浅色遮罩；点击空白处或选择操作后，一切收回为圆形按钮。"
        ),
        implementation: L(
            "One container animates its frame (anchored bottom-trailing), corner radius and fill; rows are always laid out at full width and clipped, revealed by per-row delayed animations.",
            "同一个容器以右下角对齐动画其尺寸、圆角与填充色；菜单行始终按完整宽度排版并被裁剪，通过逐行延迟动画显现。"
        ),
        apis: ["frame(width:height:alignment:)", "clipShape", "rotationEffect", "animation(_:value:)"],
        tags: ["fab", "floating action button", "speed dial", "menu", "悬浮按钮", "快捷菜单", "展开", "形变"],
        params: [
            .slider("response", L("Spring response", "弹簧响应"), 0.2...0.9, default: 0.45, unit: "s"),
            .slider("damping", L("Damping", "阻尼"), 0.5...1.0, default: 0.8),
            .slider("stagger", L("Row stagger", "行错开"), 0.0...0.1, default: 0.04, decimals: 3, unit: "s"),
        ]
    ) { ctx in
        FabMenuDemo(ctx: ctx)
    }
}

private struct FabAction {
    let symbol: String
    let title: LocalizedText
}

private let fabActions: [FabAction] = [
    FabAction(symbol: "square.and.pencil", title: L("New note", "新建笔记")),
    FabAction(symbol: "camera", title: L("Scan document", "扫描文稿")),
    FabAction(symbol: "mic", title: L("Voice memo", "语音备忘")),
    FabAction(symbol: "folder.badge.plus", title: L("New folder", "新建文件夹")),
]

private struct FabMenuDemo: View {
    let ctx: DemoContext
    @State private var open = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color.black
                .opacity(open ? 0.16 : 0)
                .allowsHitTesting(open)
                .onTapGesture { toggle() }
            FabPanel(open: open, ctx: ctx, onToggle: toggle)
                .padding(22)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.8) { toggle() }
    }

    private func toggle() {
        if !ctx.isPreview { Haptics.tap(open ? .light : .medium) }
        withAnimation(.spring(response: ctx["response"], dampingFraction: ctx["damping"])) {
            open.toggle()
        }
    }
}

private struct FabPanel: View {
    let open: Bool
    let ctx: DemoContext
    let onToggle: () -> Void

    private let rowHeight: CGFloat = 46
    private let openWidth: CGFloat = 224
    private var openHeight: CGFloat { 10 + CGFloat(fabActions.count) * rowHeight + 64 }
    private var ink: Color { Color(uiColor: .systemBackground) }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            rows
            plus
        }
        .frame(width: open ? openWidth : 60, height: open ? openHeight : 60, alignment: .bottomTrailing)
        .background(open ? Color.primary : Palette.indigo)
        .clipShape(RoundedRectangle(cornerRadius: open ? 24 : 30, style: .continuous))
        .shadow(color: Palette.indigo.opacity(open ? 0.15 : 0.4), radius: open ? 24 : 14, y: 10)
    }

    private var rows: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(fabActions.enumerated()), id: \.offset) { index, action in
                Button(action: onToggle) {
                    HStack(spacing: 12) {
                        Image(systemName: action.symbol)
                            .font(.subheadline.weight(.semibold))
                            .frame(width: 32, height: 32)
                            .background(ink.opacity(0.14), in: Circle())
                        Text(action.title, ctx.language)
                            .font(.subheadline.weight(.medium))
                        Spacer(minLength: 0)
                    }
                    .foregroundStyle(ink)
                    .frame(height: rowHeight)
                    .padding(.horizontal, 12)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .opacity(open ? 1 : 0)
                .offset(x: open ? 0 : 16)
                .blur(radius: open ? 0 : 5)
                .animation(rowAnimation(index), value: open)
            }
            Color.clear.frame(height: 64)
        }
        .padding(.top, 10)
        .frame(width: openWidth, alignment: .leading)
    }

    private var plus: some View {
        Image(systemName: "plus")
            .font(.title2.weight(.semibold))
            .foregroundStyle(open ? ink : Color.white)
            .rotationEffect(.degrees(open ? 135 : 0))
            .frame(width: 60, height: 60)
            .contentShape(Rectangle())
            .onTapGesture(perform: onToggle)
    }

    private func rowAnimation(_ index: Int) -> Animation {
        let fromBottom = Double(fabActions.count - 1 - index)
        if open {
            return .spring(response: 0.42, dampingFraction: 0.85).delay(0.06 + fromBottom * ctx["stagger"])
        }
        return .easeOut(duration: 0.12)
    }
}
