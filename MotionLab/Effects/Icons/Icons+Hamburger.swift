import SwiftUI

extension Effect {
    static let iconsHamburger = Effect(
        id: "icons.hamburger-morph",
        category: .icons,
        interaction: .tap,
        name: L("Hamburger ↔ Close", "菜单 ↔ 关闭形变"),
        summary: L("Three bars collapse to the centre, then rotate into an X.", "三条横线先向中心收拢，再旋转成 X。"),
        prompt: L(
            "A circular menu button holds three rounded 34×4 pt bars spaced 9 pt apart. On open the motion runs in two beats: first the top and bottom bars slide to the centre line while the middle bar shrinks horizontally to zero and fades; then, 120 ms later, the outer bars rotate +45° and −45° into a crisp X, optionally with the whole icon spinning a half turn. Closing plays the exact reverse (rotate back first, then separate). Both beats use a snappy spring (≈0.4 s response, 0.7 damping) with a light haptic, so the morph feels mechanical and deliberate rather than mushy.",
            "圆形菜单按钮内有三条 34×4pt 的圆角横线，间距 9pt。打开时动作分两拍：先让上下两条滑向中线，中间一条沿水平方向缩为零并淡出；120 毫秒后，外侧两条分别旋转 +45° 与 −45°，组成利落的 X，可选整体同步旋转半圈。关闭时严格倒放（先转回，再分开）。两拍都使用干脆的弹簧（响应约 0.4 秒、阻尼 0.7），配合轻触感，让形变显得机械、明确而不拖泥带水。"
        ),
        implementation: L(
            "Three Capsules with separate .animation(_:value:) modifiers wrapping rotation and offset, so each property gets its own delay depending on direction.",
            "三个 Capsule，分别用独立的 .animation(_:value:) 包裹旋转与位移，使每个属性可根据开合方向拥有各自的延迟。"
        ),
        apis: ["Capsule", "rotationEffect", "animation(_:value:)", "Animation.delay"],
        tags: ["hamburger", "menu", "close", "morph", "汉堡菜单", "菜单", "关闭", "图标形变"],
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

    var body: some View {
        VStack(spacing: 22) {
            Button { toggle() } label: {
                HamburgerIcon(
                    open: open,
                    response: ctx["response"],
                    damping: ctx["damping"],
                    sequenced: ctx.bool("sequenced"),
                    spin: ctx.bool("spin")
                )
                .frame(width: 92, height: 92)
                .background(.regularMaterial, in: Circle())
                .overlay(Circle().strokeBorder(Palette.stroke))
                .shadow(color: .black.opacity(0.12), radius: 16, y: 8)
            }
            .buttonStyle(.plain)
            Text(open ? L("Close", "关闭") : L("Menu", "菜单"), ctx.language)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .contentTransition(.opacity)
                .animation(.snappy, value: open)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.4) { toggle() }
    }

    private func toggle() {
        open.toggle()
        if !ctx.isPreview { Haptics.tap(.light) }
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
