import SwiftUI

extension Effect {
    static let iconsHamburger = Effect(
        id: "icons.hamburger-morph",
        category: .icons,
        interaction: .tap,
        name: L("Hamburger ↔ Close", "菜单 ↔ 关闭形变"),
        summary: L("Three bars collapse and rotate into an X as a menu cascades open.", "三条横线收拢并旋转成 X，同时菜单级联展开。"),
        prompt: L(
            "A frosted circular menu button holds three rounded 34×4 pt bars spaced 9 pt apart. On open the morph runs in two beats: the top and bottom bars slide to the centre line while the middle bar shrinks horizontally to zero and fades; 120 ms later the outer bars rotate ±45° into a crisp X, optionally spinning the whole icon a half turn. Meanwhile the button lifts ~90 pt and a four-row menu cascades out beneath it, each row un-blurring and dropping into place 45 ms after the last. Closing plays the exact reverse. Snappy springs (≈0.4 s, damping 0.7) and a light haptic make it feel mechanical and deliberate.",
            "磨砂圆形菜单按钮内有三条 34×4 pt 的圆角横线，间距 9 pt。打开时形变分两拍：上下两条先滑向中线，中间一条沿水平方向缩为零并淡出；120 毫秒后外侧两条分别旋转 ±45°，组成利落的 X，可选整体同步旋转半圈。与此同时按钮上移约 90 pt，下方四行菜单依次以 45 毫秒间隔由模糊变清晰、下落就位。关闭时严格倒放。干脆的弹簧（约 0.4 秒、阻尼 0.7）配合轻触感，让形变机械、明确而不拖泥带水。"
        ),
        implementation: L(
            "Three Capsules with separate .animation(_:value:) modifiers wrapping rotation and offset, so each property gets its own delay depending on direction; menu rows use per-index delayed springs for the cascade.",
            "三个 Capsule，分别用独立的 .animation(_:value:) 包裹旋转与位移，使每个属性可根据开合方向拥有各自的延迟；菜单行按索引使用带延迟的弹簧形成级联。"
        ),
        apis: ["Capsule", "rotationEffect", "animation(_:value:)", "Animation.delay"],
        tags: ["hamburger", "menu", "close", "morph", "dropdown", "汉堡菜单", "菜单", "关闭", "图标形变", "下拉"],
        params: [
            .slider("response", L("Spring response", "弹簧响应"), 0.2...0.8, default: 0.4, unit: "s"),
            .slider("damping", L("Damping", "阻尼"), 0.4...1, default: 0.7),
            .toggle("sequenced", L("Two-step sequence", "两段式"), default: true),
            .toggle("spin", L("Spin icon", "整体旋转"), default: false),
        ]
    ) { ctx in
        HamburgerDemo(ctx: ctx)
    }
}

private struct HamburgerDemo: View {
    let ctx: DemoContext
    @State private var open = false

    private var items: [(title: LocalizedText, symbol: String, tint: Color)] {
        [
            (L("Home", "首页"), "house.fill", Palette.indigo),
            (L("Library", "资料库"), "books.vertical.fill", Palette.violet),
            (L("Favorites", "收藏"), "heart.fill", Palette.pink),
            (L("Settings", "设置"), "gearshape.fill", Palette.sky),
        ]
    }

    var body: some View {
        VStack(spacing: 18) {
            Button { toggle() } label: {
                HamburgerIcon(
                    open: open,
                    response: ctx["response"],
                    damping: ctx["damping"],
                    sequenced: ctx.bool("sequenced"),
                    spin: ctx.bool("spin")
                )
                .frame(width: 84, height: 84)
                .background(.regularMaterial, in: Circle())
                .overlay(Circle().strokeBorder(Palette.stroke))
                .shadow(color: .black.opacity(open ? 0.18 : 0.12), radius: open ? 20 : 16, y: open ? 10 : 8)
            }
            .buttonStyle(.plain)
            menu
        }
        // Without the menu the button sits at the optical centre; opening lifts it to make room.
        .offset(y: open ? 0 : 92)
        .animation(.spring(response: ctx["response"] + 0.1, dampingFraction: 0.82), value: open)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottom) {
            DemoHint(text: L("Tap the button", "点击按钮"), ctx: ctx)
                .opacity(open ? 0 : 1)
                .padding(.bottom, 14)
        }
        .autoplay(ctx.isPreview, every: 1.6) { toggle() }
    }

    private var menu: some View {
        VStack(spacing: 6) {
            ForEach(items.indices, id: \.self) { i in
                HamburgerMenuRow(title: items[i].title, symbol: items[i].symbol, tint: items[i].tint, language: ctx.language)
                    .opacity(open ? 1 : 0)
                    .blur(radius: open ? 0 : 4)
                    .scaleEffect(open ? 1 : 0.9, anchor: .top)
                    .offset(y: open ? 0 : -14 - CGFloat(i) * 8)
                    .animation(rowAnimation(i), value: open)
            }
        }
        .frame(width: 210)
        .allowsHitTesting(open)
    }

    /// Rows cascade in top-to-bottom after the bars have met, and leave bottom-to-top before the X unwinds.
    private func rowAnimation(_ i: Int) -> Animation {
        let order = open ? i : items.count - 1 - i
        let lead = open ? 0.1 : 0
        return .spring(response: ctx["response"], dampingFraction: 0.8).delay(lead + Double(order) * 0.045)
    }

    private func toggle() {
        open.toggle()
        if !ctx.isPreview { Haptics.tap(.light) }
    }
}

private struct HamburgerMenuRow: View {
    let title: LocalizedText
    let symbol: String
    let tint: Color
    let language: AppLanguage

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(tint.gradient, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            Text(title, language)
                .font(.subheadline.weight(.semibold))
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 10)
        .frame(height: 42)
        .background(Palette.elevated, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 13, style: .continuous).strokeBorder(Palette.stroke))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
    }
}

private struct HamburgerIcon: View {
    let open: Bool
    let response: Double
    let damping: Double
    let sequenced: Bool
    let spin: Bool

    private let spacing: CGFloat = 9
    private var gap: Double { sequenced ? 0.12 : 0 }

    private var spring: Animation {
        .spring(response: response, dampingFraction: damping)
    }

    var body: some View {
        ZStack {
            bar(rotation: 45, offset: -spacing)
            Capsule()
                .frame(width: 34, height: 4)
                .scaleEffect(x: open ? 0.01 : 1, y: 1)
                .opacity(open ? 0 : 1)
                .animation(spring, value: open)
            bar(rotation: -45, offset: spacing)
        }
        .foregroundStyle(.primary)
        .rotationEffect(.degrees(spin && open ? 180 : 0))
        .animation(spring.delay(open ? gap : 0), value: open)
    }

    private func bar(rotation: Double, offset: CGFloat) -> some View {
        Capsule()
            .frame(width: 34, height: 4)
            .rotationEffect(.degrees(open ? rotation : 0))
            .animation(spring.delay(open ? gap : 0), value: open)
            .offset(y: open ? 0 : offset)
            .animation(spring.delay(open ? 0 : gap), value: open)
    }
}
