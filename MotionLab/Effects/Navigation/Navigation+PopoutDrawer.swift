import SwiftUI

extension Effect {
    static let navigationPopoutDrawer = Effect(
        id: "navigation.popout-drawer",
        category: .navigation,
        interaction: .tap,
        name: L("Pop-out Glass Drawer", "弹出式玻璃抽屉"),
        summary: L(
            "The menu button morphs into an ✕ as a floating glass panel springs out of it and its rows cascade in.",
            "菜单按钮变形为 ✕，一块悬浮玻璃面板从按钮处弹出，菜单行依次落入。"
        ),
        prompt: L(
            "Inside a phone frame, a round hamburger button sits top-left over a content page. Tapping it grows a floating, inset glass panel (190 × 250 pt, 26 pt corners, thin material with a hairline stroke) out of the button itself — scaling from 20% anchored at the top-left corner on a bouncy spring (response ≈0.42 s, damping 0.72) — while the page behind blurs 6 pt, dims and recedes to 96%. The three bars of the button morph into an ✕ (top and bottom rotate ±45° and meet, middle shrinks away). Menu rows cascade in from 8 pt above with a 4 pt blur, ≈35 ms apart. Closing plays in reverse with rows leaving together. Spatial, source-anchored, very iPadOS.",
            "手机画框内，内容页左上角有一枚圆形汉堡菜单按钮。点击后，一块内缩悬浮的玻璃面板（190 × 250pt、26pt 圆角、薄材质加发丝描边）从按钮本身长出——以左上角为锚点从 20% 放大，采用弹跳弹簧（响应约 0.42 秒、阻尼 0.72）；背后页面模糊 6pt、变暗并后退到 96%。按钮的三条横线变形为 ✕（上下两条旋转 ±45° 相交，中间一条缩小消失）。菜单行从上方 8pt 处带 4pt 模糊依次落入，间隔约 35 毫秒。关闭时反向播放，菜单行一同离场。有空间感、从源头长出，非常 iPadOS。"
        ),
        implementation: L(
            "The panel is scaled with scaleEffect(anchor: .topLeading) and faded on a spring; the ✕ is three capsules with rotation and offset; each row reads the open state through animation(_:value:) with an index-based delay only when opening.",
            "面板通过 scaleEffect(anchor: .topLeading) 缩放并随弹簧淡入；✕ 由三枚胶囊的旋转与位移组成；每个菜单行通过 animation(_:value:) 读取打开状态，仅在打开时按序号设置延迟。"
        ),
        apis: ["scaleEffect(_:anchor:)", "animation(_:value:)", "blur(radius:)", "Material", "rotationEffect"],
        tags: ["drawer", "popover", "hamburger", "glass", "抽屉", "弹出菜单", "汉堡菜单", "玻璃"],
        params: [
            .slider("response", L("Spring response", "弹簧响应"), 0.25...0.8, default: 0.42, unit: "s"),
            .slider("damping", L("Damping", "阻尼"), 0.5...1.0, default: 0.72),
            .slider("stagger", L("Row stagger", "行错峰"), 0.0...0.08, default: 0.035, decimals: 3, unit: "s"),
        ]
    ) { ctx in
        PopoutDrawerDemo(ctx: ctx)
    }
}

private let popoutItems: [(String, LocalizedText)] = [
    ("square.grid.2x2.fill", L("Dashboard", "仪表盘")),
    ("person.2.fill", L("Team", "团队")),
    ("calendar", L("Schedule", "日程")),
    ("chart.pie.fill", L("Reports", "报表")),
    ("gearshape.fill", L("Settings", "设置")),
]

private struct PopoutDrawerDemo: View {
    let ctx: DemoContext
    @State private var open = false

    private var spring: Animation {
        .spring(response: ctx["response"], dampingFraction: ctx["damping"])
    }

    var body: some View {
        VStack(spacing: 14) {
            ZStack(alignment: .topLeading) {
                page
                panel
                menuButton
                    .padding(14)
            }
            .frame(width: 250, height: 320)
            .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
            .shadow(color: .black.opacity(0.18), radius: 18, y: 10)
            DemoHint(text: L("Tap the menu button", "点击菜单按钮"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.6) { toggle() }
    }

    private var page: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L("Overview", "概览"), ctx.language)
                .font(.title3.weight(.bold))
                .padding(.leading, 52)
                .padding(.top, 6)
            HStack(spacing: 10) {
                statTile(Palette.indigo)
                statTile(Palette.mint)
            }
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Palette.surface)
                .frame(height: 110)
                .overlay { PlaceholderLines(count: 3).padding(16) }
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(width: 250, height: 320, alignment: .topLeading)
        .background(Palette.elevated)
        .blur(radius: open ? 6 : 0)
        .overlay(Color.black.opacity(open ? 0.18 : 0))
        .scaleEffect(open ? 0.96 : 1)
        .animation(.easeInOut(duration: 0.3), value: open)
        .onTapGesture { if open { toggle() } }
    }

    private func statTile(_ color: Color) -> some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(color.opacity(0.18))
            .frame(height: 76)
            .overlay(alignment: .bottomLeading) {
                Capsule().fill(color).frame(width: 40, height: 6).padding(14)
            }
    }

    private var panel: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(0..<popoutItems.count, id: \.self) { index in
                row(index)
            }
        }
        .padding(.top, 52)
        .padding(.horizontal, 10)
        .frame(width: 190, height: 250, alignment: .topLeading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous).strokeBorder(Color.white.opacity(0.25)))
        .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
        .scaleEffect(open ? 1 : 0.2, anchor: .topLeading)
        .opacity(open ? 1 : 0)
        .padding(10)
        .animation(spring, value: open)
        .allowsHitTesting(open)
    }

    private func row(_ index: Int) -> some View {
        let delay: Double = open ? 0.08 + Double(index) * ctx["stagger"] : 0
        return HStack(spacing: 12) {
            Image(systemName: popoutItems[index].0)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Palette.indigo)
                .frame(width: 22)
            Text(popoutItems[index].1, ctx.language)
                .font(.subheadline.weight(.semibold))
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .frame(height: 36)
        .contentShape(Rectangle())
        .onTapGesture { toggle() }
        .opacity(open ? 1 : 0)
        .blur(radius: open ? 0 : 4)
        .offset(y: open ? 0 : -8)
        .animation(.spring(response: 0.35, dampingFraction: 0.8).delay(delay), value: open)
    }

    private var menuButton: some View {
        Button { toggle() } label: {
            ZStack {
                Capsule()
                    .frame(width: 16, height: 2.2)
                    .rotationEffect(.degrees(open ? 45 : 0))
                    .offset(y: open ? 0 : -5)
                Capsule()
                    .frame(width: 16, height: 2.2)
                    .scaleEffect(x: open ? 0.1 : 1)
                    .opacity(open ? 0 : 1)
                Capsule()
                    .frame(width: 16, height: 2.2)
                    .rotationEffect(.degrees(open ? -45 : 0))
                    .offset(y: open ? 0 : 5)
            }
            .foregroundStyle(Color.primary)
            .frame(width: 38, height: 38)
            .background(Palette.surface, in: Circle())
            .overlay(Circle().strokeBorder(Palette.stroke))
        }
        .buttonStyle(.plain)
        .animation(spring, value: open)
    }

    private func toggle() {
        if !ctx.isPreview { Haptics.tap(open ? .light : .medium) }
        open.toggle()
    }
}
