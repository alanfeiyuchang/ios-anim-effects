import SwiftUI

extension Effect {
    static let navigationFoldMenu = Effect(
        id: "navigation.fold-menu",
        category: .navigation,
        interaction: .tap,
        name: L("Paper-Fold Dropdown", "折纸下拉菜单"),
        summary: L(
            "A dropdown whose rows unfold one by one in 3D like a strip of folded paper.",
            "下拉菜单的每一行像折好的纸条一样，逐行在 3D 空间中展开。"
        ),
        prompt: L(
            "A \"Sort: Newest\" pill button with a chevron. Tapping it unfolds a menu beneath: each of the four rows starts rotated −90° about its own top edge (perspective 0.6) and swings down into place on a spring (response ≈0.4 s, damping 0.72), ≈45 ms after the row above, while a shade that is darkest when the row is edge-on fades away — the list opens like a fan of folded paper. The chevron turns 180°. Picking a row slides the checkmark to it, then the menu folds back up in reverse order (bottom row first) and the button's label rolls to the new choice. Crafted, physical and surprisingly calm for a 3D effect.",
            "一个「排序：最新」的胶囊按钮，右侧带箭头。点击后，下方展开菜单：四行各自以自身顶边为轴从 −90° 开始（透视 0.6），以弹簧（响应约 0.4 秒、阻尼 0.72）翻转落下，每行比上一行晚约 45 毫秒；行在侧立时阴影最深，随展开逐渐褪去——整个列表像折纸扇一样打开。箭头旋转 180°。选中某一行时，对勾先滑到该行，随后菜单按相反顺序（从最底行开始）折叠收起，按钮文字滚动为新选项。精致、有物理感，作为 3D 效果却出奇地安静。"
        ),
        implementation: L(
            "Each row applies rotation3DEffect around the x axis anchored at .top plus a black overlay tied to the same angle; animation(_:value:) gives each row a delay by index when opening and by reverse index when closing, and the checkmark uses matchedGeometryEffect.",
            "每一行以 .top 为锚点绕 x 轴应用 rotation3DEffect，并叠加一层与角度联动的黑色阴影；animation(_:value:) 在打开时按序号、收起时按倒序为每行设置延迟，对勾使用 matchedGeometryEffect。"
        ),
        apis: ["rotation3DEffect(_:axis:anchor:perspective:)", "animation(_:value:)", "matchedGeometryEffect", "transition(.push(from:))"],
        tags: ["dropdown", "menu", "fold", "3D", "下拉菜单", "菜单", "折叠", "三维"],
        params: [
            .slider("stagger", L("Row stagger", "行错峰"), 0.0...0.1, default: 0.045, decimals: 3, unit: "s"),
            .slider("response", L("Spring response", "弹簧响应"), 0.2...0.7, default: 0.4, unit: "s"),
            .slider("perspective", L("Perspective", "透视"), 0.2...1.0, default: 0.6),
        ]
    ) { ctx in
        FoldMenuDemo(ctx: ctx)
    }
}

private let foldOptions: [LocalizedText] = [L("Newest", "最新"), L("Oldest", "最早"), L("Popular", "最热"), L("A–Z", "按名称")]
private let foldSymbols: [String] = ["clock", "clock.arrow.circlepath", "flame", "textformat"]

private struct FoldMenuDemo: View {
    let ctx: DemoContext
    @Namespace private var ns
    @State private var open = false
    @State private var choice = 0
    @State private var token = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            button
            menu
            Spacer(minLength: 0)
        }
        .frame(width: 230)
        .padding(.top, 36)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottom) {
            DemoHint(text: L("Tap the sort button", "点击排序按钮"), ctx: ctx)
                .padding(.bottom, 14)
        }
        .autoplay(ctx.isPreview, every: 1.3) {
            if open {
                pick((choice + 1) % foldOptions.count)
            } else {
                toggle()
            }
        }
    }

    private var button: some View {
        Button { toggle() } label: {
            HStack(spacing: 6) {
                Text(L("Sort:", "排序："), ctx.language)
                    .foregroundStyle(.secondary)
                Text(foldOptions[choice], ctx.language)
                    .id(choice)
                    .transition(.push(from: .bottom))
                Spacer(minLength: 0)
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .bold))
                    .rotationEffect(.degrees(open ? 180 : 0))
                    .animation(.spring(response: 0.35, dampingFraction: 0.75), value: open)
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color.primary)
            .padding(.horizontal, 16)
            .frame(height: 44)
            .background(Palette.surface, in: Capsule())
            .overlay(Capsule().strokeBorder(Palette.stroke))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var menu: some View {
        VStack(spacing: 0) {
            ForEach(0..<foldOptions.count, id: \.self) { index in
                row(index)
            }
        }
        .background(Palette.elevated.opacity(open ? 1 : 0), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(open ? 0.12 : 0), radius: 16, y: 8)
        .animation(.easeInOut(duration: 0.25).delay(open ? 0 : 0.2), value: open)
    }

    private func row(_ index: Int) -> some View {
        let count = foldOptions.count
        let order: Int = open ? index : count - 1 - index
        let delay: Double = Double(order) * ctx["stagger"]
        let angle: Double = open ? 0 : -90
        return HStack(spacing: 12) {
            Image(systemName: foldSymbols[index])
                .font(.system(size: 14, weight: .semibold))
                .frame(width: 20)
                .foregroundStyle(Palette.indigo)
            Text(foldOptions[index], ctx.language)
                .font(.subheadline.weight(.medium))
            Spacer()
            if index == choice {
                Image(systemName: "checkmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Palette.indigo)
                    .matchedGeometryEffect(id: "foldCheck", in: ns)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 44)
        .background(Palette.elevated)
        .overlay(alignment: .bottom) {
            if index < count - 1 {
                Rectangle().fill(Palette.stroke).frame(height: 1).padding(.leading, 48)
            }
        }
        .overlay(Color.black.opacity(open ? 0 : 0.35).allowsHitTesting(false))
        .rotation3DEffect(.degrees(angle), axis: (x: 1, y: 0, z: 0), anchor: .top, perspective: ctx["perspective"])
        .opacity(open ? 1 : 0)
        .contentShape(Rectangle())
        .onTapGesture { pick(index) }
        .allowsHitTesting(open)
        .animation(.spring(response: ctx["response"], dampingFraction: 0.72).delay(delay), value: open)
    }

    private func toggle() {
        if !ctx.isPreview { Haptics.tap(.light) }
        open.toggle()
    }

    private func pick(_ index: Int) {
        if !ctx.isPreview { Haptics.selection() }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { choice = index }
        token += 1
        let current = token
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.25))
            guard token == current else { return }
            open = false
        }
    }
}
