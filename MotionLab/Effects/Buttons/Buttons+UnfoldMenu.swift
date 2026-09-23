import SwiftUI

extension Effect {
    static let buttonsUnfoldMenu = Effect(
        id: "buttons.unfold-menu",
        category: .buttons,
        interaction: .tap,
        name: L("Paper Unfold Menu", "折纸展开菜单"),
        summary: L("A More button unfolds its actions row by row, like a folded paper strip.", "“更多”按钮把操作一行行展开，像打开一条折叠的纸带。"),
        prompt: L(
            "A file card with a 44 pt round \"…\" button in its header. On tap the ellipsis turns into a close mark via a symbol replace, and a four-row action menu (Share, Rename, Duplicate, Delete) unfolds below the button like a folded paper strip: each 46 pt row starts rotated −90° around its top edge (perspective 0.5) and swings down flat on a spring (response 0.45 s, damping 0.72), 50 ms after the row above, darkening slightly while it is still edge-on so the fold reads in 3D. The destructive last row is tinted red. Closing folds the rows back up bottom-first. The card behind dims to 60% while the menu is open, and a light haptic marks each toggle; choosing a row folds the menu and flashes a confirmation. Tactile, crafted and spatial.",
            "一张文件卡片，头部有一枚 44pt 的圆形“…”按钮。点击后，省略号通过符号替换变为关闭符号，一个四行操作菜单（分享、重命名、复制副本、删除）像折叠的纸带一样在按钮下方展开：每行高 46pt，起始时绕自身顶边旋转 −90°（透视 0.5），再以弹簧（响应 0.45 秒、阻尼 0.72）翻折下来铺平，每行比上一行晚 50 毫秒；行在接近侧立时略微变暗，让折叠更有立体感。最后一行“删除”带红色。收起时从最底行开始向上折回。菜单打开时背后的卡片内容降到 60% 透明度，每次切换都有轻触感；选中某一行会收起菜单并闪现确认提示。有触感、有工艺感、有空间感。"
        ),
        implementation: L(
            "Each row is its own slab (UnevenRoundedRectangle for the first and last) with rotation3DEffect(anchor: .top) and a brightness tied to the same open flag, animated by a per-row delayed spring whose order flips on close.",
            "每行都是独立的面板（首尾使用 UnevenRoundedRectangle），带 rotation3DEffect(anchor: .top)，亮度与同一个展开状态绑定，并由逐行带延迟的弹簧驱动，收起时顺序反转。"
        ),
        apis: ["rotation3DEffect(_:axis:anchor:perspective:)", "UnevenRoundedRectangle", "animation(_:value:)", "contentTransition(.symbolEffect(.replace))", "brightness"],
        tags: ["menu", "unfold", "fold", "3d", "菜单", "展开", "折叠", "立体"],
        params: [
            .slider("stagger", L("Row stagger", "行间错峰"), 0...0.12, default: 0.05, unit: "s"),
            .slider("response", L("Spring response", "弹簧响应"), 0.25...0.8, default: 0.45, unit: "s"),
            .slider("perspective", L("Perspective", "透视强度"), 0.1...1.0, default: 0.5),
        ]
    ) { ctx in
        ButtonUnfoldMenuDemo(ctx: ctx)
    }
}

private struct ButtonMenuRow {
    let symbol: String
    let title: LocalizedText
    let done: LocalizedText
    let destructive: Bool
}

private struct ButtonUnfoldMenuDemo: View {
    let ctx: DemoContext
    @State private var open = false
    @State private var toast: LocalizedText?
    @State private var step = 0

    private static let rows: [ButtonMenuRow] = [
        ButtonMenuRow(symbol: "square.and.arrow.up", title: L("Share", "分享"), done: L("Link copied", "链接已复制"), destructive: false),
        ButtonMenuRow(symbol: "pencil", title: L("Rename", "重命名"), done: L("Renamed", "已重命名"), destructive: false),
        ButtonMenuRow(symbol: "plus.square.on.square", title: L("Duplicate", "复制副本"), done: L("Copy created", "已创建副本"), destructive: false),
        ButtonMenuRow(symbol: "trash", title: L("Delete", "删除"), done: L("Moved to Trash", "已移到废纸篓"), destructive: true),
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            card
            Spacer(minLength: 0)
            DemoHint(text: L("Tap the … button", "点击“…”按钮"), ctx: ctx)
                .padding(.bottom, 14)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.3, delay: 0.4) { previewStep() }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Palette.ocean, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text(L("Launch plan.pdf", "发布计划.pdf"), ctx.language)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(L("2.4 MB · Edited 3 min ago", "2.4 MB · 3 分钟前编辑"), ctx.language)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                moreButton
            }
            PlaceholderLines(count: 4)
                .opacity(open ? 0.6 : 1)
                .animation(.smooth(duration: 0.3), value: open)
            toastView
        }
        .padding(16)
        .frame(width: 300, height: 250, alignment: .top)
        .demoCard(cornerRadius: 24)
        .overlay(alignment: .topTrailing) {
            menu
                .padding(.top, 68)
                .padding(.trailing, 14)
        }
    }

    @ViewBuilder
    private var toastView: some View {
        if let toast {
            Label {
                Text(toast, ctx.language)
            } icon: {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Palette.green)
            }
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.primary)
            .transition(.blurReplace)
        }
    }

    private var moreButton: some View {
        Button(action: toggle) {
            Image(systemName: open ? "xmark" : "ellipsis")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(.primary)
                .contentTransition(.symbolEffect(.replace))
                .frame(width: 44, height: 44)
                .background(Color.primary.opacity(open ? 0.12 : 0.06), in: Circle())
        }
        .buttonStyle(SportPressStyle(scale: 0.9, dim: 0.04))
        .accessibilityLabel(Text(open ? L("Close menu", "关闭菜单") : L("More actions", "更多操作"), ctx.language))
    }

    private var menu: some View {
        VStack(spacing: 0) {
            ForEach(Self.rows.indices, id: \.self) { index in
                row(index)
            }
        }
        .frame(width: 190)
        .shadow(color: .black.opacity(open ? 0.18 : 0), radius: 16, y: 10)
        .allowsHitTesting(open)
    }

    private func row(_ index: Int) -> some View {
        let count = Self.rows.count
        let item = Self.rows[index]
        let order = open ? index : count - 1 - index
        let delay = Double(order) * ctx["stagger"]
        let shape = UnevenRoundedRectangle(
            topLeadingRadius: index == 0 ? 16 : 0,
            bottomLeadingRadius: index == count - 1 ? 16 : 0,
            bottomTrailingRadius: index == count - 1 ? 16 : 0,
            topTrailingRadius: index == 0 ? 16 : 0,
            style: .continuous
        )
        return Button { choose(index) } label: {
            HStack(spacing: 12) {
                Image(systemName: item.symbol)
                    .font(.system(size: 15, weight: .semibold))
                    .frame(width: 20)
                Text(item.title, ctx.language)
                    .font(.subheadline.weight(.medium))
                Spacer(minLength: 0)
            }
            .foregroundStyle(item.destructive ? Palette.red : Color.primary)
            .padding(.horizontal, 16)
            .frame(height: 46)
            .background(Palette.elevated, in: shape)
            .overlay(alignment: .bottom) {
                if index < count - 1 {
                    Rectangle().fill(Palette.stroke).frame(height: 1)
                }
            }
            .contentShape(shape)
        }
        .buttonStyle(.plain)
        .brightness(open ? 0 : -0.25)
        .opacity(open ? 1 : 0)
        .rotation3DEffect(.degrees(open ? 0 : -90), axis: (x: 1, y: 0, z: 0), anchor: .top, perspective: ctx.cg("perspective"))
        .animation(.spring(response: ctx["response"], dampingFraction: 0.72).delay(delay), value: open)
    }

    private func toggle() {
        open.toggle()
        Haptics.tap()
        if open { withAnimation(.smooth(duration: 0.2)) { toast = nil } }
    }

    private func choose(_ index: Int) {
        guard open else { return }
        open = false
        Haptics.success()
        let message = Self.rows[index].done
        withAnimation(.smooth(duration: 0.3).delay(0.2)) { toast = message }
    }

    private func previewStep() {
        switch step % 3 {
        case 0: toggle()
        case 1: choose(0)
        default: withAnimation(.smooth(duration: 0.3)) { toast = nil }
        }
        step += 1
    }
}
